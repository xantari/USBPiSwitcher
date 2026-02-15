#!/usr/bin/env python3
"""
Raspberry Pi GPIO Switch Controller (multi-pin) via FastAPI
Controls multiple GPIO pins to drive relays (HIGH when on, LOW when off).

Note: Uses rpi-lgpio (Pi 5 / Pi Zero 2 W compatible).
"""

import asyncio
import os
import time

from fastapi import Depends, FastAPI, Header, HTTPException, Path, Query, status

try:
    import lgpio
except ModuleNotFoundError as exc:
    import sys

    pyver = f"{sys.version_info.major}.{sys.version_info.minor}"
    hint = (
        "lgpio is missing. On Raspberry Pi install it with: "
        "sudo apt-get install -y python3-lgpio. "
        "If you installed it already, ensure you are using the matching Python version "
        "(Raspberry Pi OS packages target Python 3.11). Current Python is " + pyver
    )
    raise SystemExit(hint) from exc

# Safe GPIO pins (BCM numbering) - no common peripheral conflicts
ALLOWED_PINS = {4, 5, 6, 12, 13, 16, 17, 19, 20, 21, 22, 23, 24, 25, 26, 27}
_chip = None
_pin_states = {}  # Track which pins are active: {pin_number: is_active}


def setup_gpio():
    """Initialize GPIO chip using lgpio."""
    global _chip

    if _chip is None:
        _chip = lgpio.gpiochip_open(0)
        print(f"GPIO initialized via lgpio. Allowed pins: {sorted(ALLOWED_PINS)}")
        print("Pins will be initialized on first use")


def _validate_pin(pin: int) -> None:
    """Validate that pin is in allowed range."""
    if pin not in ALLOWED_PINS:
        raise ValueError(f"Pin {pin} not allowed. Must be one of: {sorted(ALLOWED_PINS)}")


def _initialize_pin(pin: int) -> None:
    """Initialize a pin if not already initialized."""
    if pin not in _pin_states:
        # Start in output mode LOW (relay off)
        lgpio.gpio_claim_output(_chip, pin, lgpio.LOW)
        _pin_states[pin] = False
        print(f"GPIO {pin} initialized (output LOW - relay off)")


def activate_switch(pin: int) -> None:
    """Set pin to HIGH to turn on relay."""
    if _chip is None:
        raise RuntimeError("GPIO not initialized")
    
    _validate_pin(pin)
    _initialize_pin(pin)

    # Free the pin first, then claim as output HIGH (relay on)
    lgpio.gpio_free(_chip, pin)
    lgpio.gpio_claim_output(_chip, pin, lgpio.HIGH)
    _pin_states[pin] = True
    print(f"GPIO {pin} activated (output HIGH - relay on)")


def deactivate_switch(pin: int) -> None:
    """Set pin to LOW to turn off relay."""
    if _chip is None:
        raise RuntimeError("GPIO not initialized")
    
    _validate_pin(pin)
    _initialize_pin(pin)

    # Free the pin and reclaim as output LOW (relay off)
    lgpio.gpio_free(_chip, pin)
    lgpio.gpio_claim_output(_chip, pin, lgpio.LOW)
    _pin_states[pin] = False
    print(f"GPIO {pin} deactivated (output LOW - relay off)")


def toggle_switch(pin: int) -> str:
    """Toggle the pin between HIGH (relay on) and LOW (relay off)."""
    if _chip is None:
        raise RuntimeError("GPIO not initialized")
    
    _validate_pin(pin)
    _initialize_pin(pin)

    if _pin_states.get(pin, False):
        deactivate_switch(pin)
        return "LOW (relay off)"
    else:
        activate_switch(pin)
        return "HIGH (relay on)"


def get_switch_state(pin: int) -> str:
    """Return a human-readable description of the pin state."""
    if _chip is None:
        return "not initialized"
    
    _validate_pin(pin)
    
    if pin not in _pin_states:
        return "not initialized"

    return "HIGH (relay on)" if _pin_states[pin] else "LOW (relay off)"


def cleanup():
    """Deactivate everything and release GPIO resources."""
    global _chip, _pin_states

    if _chip is None:
        print("GPIO not initialized; nothing to clean up")
        return

    try:
        # Free all initialized pins
        for pin in list(_pin_states.keys()):
            lgpio.gpio_free(_chip, pin)
        _pin_states.clear()
    finally:
        lgpio.gpiochip_close(_chip)
        _chip = None
    print("GPIO cleanup complete")


API_KEY = os.environ.get("GPIO_API_KEY")  # set this env var to enforce key auth


def require_api_key(x_api_key: str | None = Header(default=None, alias="X-API-Key")) -> None:
    """Simple API key check using the X-API-Key header.

    If GPIO_API_KEY is unset, auth is skipped (not recommended for exposed hosts).
    """

    if not API_KEY:  # no key configured; auth disabled
        return

    if x_api_key != API_KEY:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or missing API key")


app = FastAPI(title="GPIO Switch Controller", version="1.0.0")


@app.on_event("startup")
def _on_startup() -> None:
    setup_gpio()


@app.on_event("shutdown")
def _on_shutdown() -> None:
    cleanup()


@app.get("/pin/{pin}/status")
def status(
    pin: int = Path(..., description="GPIO pin number"),
    _: None = Depends(require_api_key)
):
    """Return current pin state."""
    try:
        state = get_switch_state(pin)
        return {"pin": pin, "state": state}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/pin/{pin}/on")
def turn_on(
    pin: int = Path(..., description="GPIO pin number"),
    _: None = Depends(require_api_key)
):
    """Activate switch - set GPIO pin to HIGH to turn on relay."""
    try:
        activate_switch(pin)
        return {"pin": pin, "state": "HIGH (relay on)"}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/pin/{pin}/off")
def turn_off(
    pin: int = Path(..., description="GPIO pin number"),
    _: None = Depends(require_api_key)
):
    """Deactivate switch - set GPIO pin to LOW to turn off relay."""
    try:
        deactivate_switch(pin)
        return {"pin": pin, "state": "LOW (relay off)"}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/pin/{pin}/toggle")
def toggle(
    pin: int = Path(..., description="GPIO pin number"),
    _: None = Depends(require_api_key)
):
    """Toggle GPIO pin between active and inactive states."""
    try:
        state = toggle_switch(pin)
        return {"pin": pin, "state": state}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/pin/{pin}/pulse")
async def pulse(
    pin: int = Path(..., description="GPIO pin number"),
    delay_ms: int = Query(default=500, ge=1, le=10000, description="Pulse duration in milliseconds"),
    _: None = Depends(require_api_key)
):
    """Pulse the GPIO pin - turn on relay (HIGH), wait for delay, then turn off (LOW)."""
    try:
        activate_switch(pin)
        await asyncio.sleep(delay_ms / 1000.0)  # Convert ms to seconds
        deactivate_switch(pin)
        return {
            "pin": pin,
            "action": "pulse",
            "delay_ms": delay_ms,
            "state": "LOW (relay off)"
        }
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/")
def root():
    """Show available GPIO pins and endpoint patterns."""
    return {
        "allowed_pins": sorted(ALLOWED_PINS),
        "initialized_pins": {pin: ("active" if state else "inactive") for pin, state in _pin_states.items()},
        "endpoint_pattern": "/pin/{pin_number}/{action}",
        "actions": ["status", "on", "off", "toggle", "pulse"],
        "example": "/pin/17/on"
    }

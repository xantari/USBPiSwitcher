<p align="center">
  <img src="https://github.com/xantari/USBPiSwitcher/blob/main/PiGPIOLogoUgreen.png" alt="Pi GPIO Switch UGreen Logo">
</p>

# Raspberry Pi GPIO UGREEN USB Switch Controller (FastAPI)

FastAPI service that drives multiple GPIO pins on Raspberry Pi to control relays for HTTP enabled / remote UGREEN USB-C switch control.

**Compatible with:** Raspberry Pi 3/4/5, Raspberry Pi Zero 2 W (and other models with 40-pin GPIO header)

## Purpose

This project automates the manual switching button on **UGREEN USB-C Switch** devices, allowing programmatic control via HTTP API. By using a relay connected to the GPIO pins, you can trigger the switch button remotely without physical button presses.

**Supported GPIO Pins (BCM numbering):** 4, 5, 6, 12, 13, 16, 17, 19, 20, 21, 22, 23, 24, 25, 26, 27  
These pins have no conflicts with common peripherals (I2C, SPI, UART) and are safe for general-purpose use.

**Required Hardware:**
- Raspberry Pi (5, Zero 2 W, or other models with 40-pin GPIO header)
- Relay module - [3.3V Relay Module (recommended)](https://www.amazon.com/dp/B0F7R9XCZK)
- UGREEN USB-C Switch

**Supported UGREEN Devices:**
- [UGREEN USB-C Switch 2 Port (2 PC) USB 3.2](https://us.ugreen.com/products/ugreen-usbc-switch-2-port)
- [UGREEN USB-C Switch 2 Port (2 PC) USB 3.0](https://us.ugreen.com/products/ugreen-usb-c-switch-2-port-4-usb3)
- Other UGREEN USB-C switches with similar button circuitry

**How it works:** The GPIO pin controls a relay that simulates a manual button press on the UGREEN switch, causing it to toggle between connected PCs/devices.

## Use Case: Software-Based KVM Solution

This project is designed to enable a complete software-based KVM (Keyboard, Video, Mouse) solution by combining monitor switching with USB peripheral switching:

**Monitor Switching** ([SwitchMonitors](https://github.com/xantari/SwitchMonitors))  
- Uses DDC/CI commands to switch monitor input sources
- Programmatically controls which computer your monitors display
- No physical monitor button pressing required

**USB Peripheral Switching**  (This Repository)
- Integrates with a Raspberry Pi Zero HTTP API to control a USB switch
- Switches keyboard, mouse, and other USB peripherals between computers
- Controlled via simple HTTP requests to the Pi Zero

**Combined Workflow:**
When you want to switch between computers, a single command can:
1. Switch all monitor inputs to the target computer (using this SwitchMonitors script in Repo listed above)
2. Switch USB peripherals to the target computer (via Pi Zero API call using this project repository)

This creates a seamless, software-controlled KVM experience without expensive KVM hardware, perfect for multi-PC setups where you want to share monitors and peripherals between work and personal computers, or between desktop and laptop systems.

## Parts List

| Item | Product | Price (as of Feb 2026) | Link |
|------|---------|------------------------|------|
| 1 | Raspberry Pi Zero 2 WH Kit | ~$35 | [Amazon](https://www.amazon.com/Raspberry-Pi-Zero-WH-Kit/dp/B0DRRDJKDV) |
| 2 | SanDisk 32GB Ultra® microSDHC | ~$22 | [Amazon](https://www.amazon.com/SanDisk-Ultra%C2%AE-microSDHC-120MB-Class/dp/B08L5HMJVW) |
| 3 | 1 Channel 3V/3.3V Relay Module (pack of 4) | ~$8 | [Amazon](https://www.amazon.com/dp/B0F7R9XCZK) |
| 4 | Amazon Basics USB-A to Mini USB 2.0 Cable | ~$7 | [Amazon](https://www.amazon.com/Amazon-Basics-Charging-Transfer-Gold-Plated/dp/B00NH13S44) |

**Estimated Total Cost:** ~$72

## 💖 Do You Like This Project?

If you find this project useful and it's helped you automate your USB-C switching, please consider supporting it! Your support helps maintain and improve this project.

**Support this project:**

<p align="left">
  <!-- <a href="https://github.com/sponsors/xantari">
    <img src="https://img.shields.io/badge/Sponsor-GitHub%20Sponsors-ea4aaa?style=for-the-badge&logo=github" alt="GitHub Sponsors">
  </a>&nbsp;&nbsp; -->
  <a href="https://www.paypal.com/donate/?hosted_button_id=EPLVCAMK76NUG">
    <img src="https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="PayPal">
  </a>
</p>

**Other ways to help:**
- ⭐ **Star this repository** - It helps others discover the project
- 🐛 **Report issues** - Help improve the project by reporting bugs
- 🔧 **Contribute** - Submit pull requests with improvements or new features
- 📢 **Share** - Tell others who might find this useful

Every bit of support is appreciated and motivates continued development!

## Wiring Instructions

✅ **Relay Control Behavior:**

This controller uses a relay module to isolate and switch the USB-C switch button circuit:
- **When ON (activated)**: GPIO pin outputs **HIGH (3.3V)** → Relay closes → Simulates button press
- **When OFF (deactivated)**: GPIO pin outputs **LOW (0V)** → Relay opens → No button press

### Relay Wiring

**Raspberry Pi to Relay Module:**
1. **GPIO Pin** (e.g., GPIO 17 BCM, physical pin 11) → Relay module **IN** or **S** (signal pin)
2. **3.3V** (physical pin 1) → Relay module **VCC**
3. **GND** (physical pin 9) → Relay module **GND**

**Relay to UGREEN USB-C Switch:**
1. Connect the relay's **COM** (common) terminal to the USB switch button's D- line
2. Connect the relay's **NO** (normally open) terminal to USB switch GND
3. When the relay activates, it closes the circuit between D- and GND, simulating a button press

### Circuit Diagram
```
Raspberry Pi                 Relay Module              USB-C Switch
┌─────────────┐            ┌──────────┐              ┌──────────┐
│ Pin 1 (3.3V)├───────────→│ VCC      │              │          │
│ Pin 9 (GND) ├───────────→│ GND      │              │          │
│ Pin 11(GP17)├───────────→│ IN/S     │              │          │
│             │            │          │              │          │
│             │            │ COM ─────┼─────────────→│ D-       │
│             │            │ NO  ─────┼─────────────→│ GND      │
└─────────────┘            └──────────┘              └──────────┘

When GPIO 17 = HIGH (3.3V): Relay closes, connects D- to GND (button press)
When GPIO 17 = LOW (0V):    Relay opens, D- disconnected (no button press)
```

Full Color Image (Example using Pin 17 for 3.3V instead of Pin 1):

<p align="center">
  <img src="https://github.com/xantari/USBPiSwitcher/blob/main/PinoutDiagram.png" alt="Pinout Diagram">
</p>


### Raspberry Pi GPIO Pins

**Raspberry Pi Connections:**
- **Physical Pin 1 (3.3V) or Pin 17 (3.3V)** → Relay VCC
- **Physical Pin 9 (GND)** → Relay GND
- **Physical Pin 11 (GPIO 17 BCM)** → Relay IN/S (signal)

**Note:** You can use any of the allowed GPIO pins (4, 5, 6, 12, 13, 16, 17, 19, 20, 21, 22, 23, 24, 25, 26, 27) for the relay signal connection. Pin numbers listed are in BCM format for API endpoints.

## Installation (Pi 5 / Pi Zero 2 W / lgpio)

### Quick Setup (Automated)

Run the setup script to install everything automatically:
```bash
chmod +x setup.sh
./setup.sh
```

### Manual Setup

1. Install system GPIO library (required on Raspberry Pi 5):
```bash
sudo apt-get update
sudo apt-get install -y python3-lgpio
```

2. Create a venv that can see system packages (so it finds `lgpio`):
```bash
python3 -m venv --system-site-packages .venv
source .venv/bin/activate
```

3. Install Python dependencies (FastAPI + Uvicorn):
```bash
pip install -r requirements.txt
```

## Usage (FastAPI service)

### Manual Start

Start the API (listens on all interfaces for remote access):
```bash
uvicorn gpio_switch_fastapi:app --host 0.0.0.0 --port 8000
```

Enable SSL (cert + key files) and API key auth (set env `GPIO_API_KEY`):
```bash
GPIO_API_KEY="your-secret-key" uvicorn gpio_switch_fastapi:app \
    --host 0.0.0.0 --port 8000 \
    --ssl-certfile /path/to/cert.pem --ssl-keyfile /path/to/key.pem
```

### SSL via ACME (DNS-01)

**Requirements:** A registered domain that you own and API access to your DNS provider.

This project is set up to obtain free certificates using acme.sh with the **DNS-01** challenge. DNS-01 is chosen because it:
- Does **not** require exposing ports 80/443 or port-forwarding (works behind NAT/CGNAT)
- Supports wildcards and works even if your Pi is not publicly reachable
- Requires a real domain and DNS API credentials to prove ownership

By contrast, **HTTP-01** requires your domain to resolve to the Pi and inbound port 80 to be reachable during issuance, which is often impractical on home/CGNAT networks.

The setup script (`setup.sh`) can install acme.sh and optionally guide issuance. If you issue a cert via acme.sh, point uvicorn to the generated files:
- `--ssl-certfile /home/piwifi/Documents/certs/<domain>.crt`
- `--ssl-keyfile /home/piwifi/Documents/certs/<domain>.key`

### Self-Signed SSL Certificates

**Requirements:** None - works with IP addresses, local hostnames (e.g., `gpio.local`), or any identifier.

For testing or internal use, the setup script can generate self-signed certificates. These certificates:
- Work immediately without DNS or external validation
- No domain ownership required - can use IP addresses or local names
- Cause browser security warnings (untrusted certificate)
- Are valid for 50 years (no renewal needed)

### Auto-Start on Boot (systemd)

Install as a system service to start automatically on reboot (edit `gpio-switch.service` to set your username and project path first, or use the setup.sh script):

1. Copy the service file to systemd:
```bash
sudo cp gpio-switch.service /etc/systemd/system/
```

2. Reload systemd and enable the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable gpio-switch.service
sudo systemctl start gpio-switch.service
```

To supply an API key to systemd, create `<project_dir>/.env.gpio` (e.g., `/home/your-user/Documents/.env.gpio`) with:
```
GPIO_API_KEY=your-secret-key
```

3. Check service status:
```bash
sudo systemctl status gpio-switch.service
```

**Useful commands:**
- Stop service: `sudo systemctl stop gpio-switch.service`
- Restart service: `sudo systemctl restart gpio-switch.service`
- View logs: `sudo journalctl -u gpio-switch.service -f`
- Disable auto-start: `sudo systemctl disable gpio-switch.service`

### Test Endpoints

Replace `PI_IP` with your Pi's address and `{pin}` with the GPIO pin number (e.g., 17, 22, 24).

**HTTP (no SSL):**
```bash
# Get root info (shows allowed pins)
curl http://PI_IP:8000/

# Control specific pins
curl http://PI_IP:8000/pin/17/status
curl -X POST http://PI_IP:8000/pin/17/on
curl -X POST http://PI_IP:8000/pin/17/off
curl -X POST http://PI_IP:8000/pin/17/toggle

# Pulse pin (simulates button press) - default 500ms delay
curl -X POST http://PI_IP:8000/pin/17/pulse

# Pulse with custom delay (e.g., 1000ms = 1 second)
curl -X POST "http://PI_IP:8000/pin/17/pulse?delay_ms=1000"

# Control a different pin (e.g., pin 22)
curl http://PI_IP:8000/pin/22/status
curl -X POST http://PI_IP:8000/pin/22/on
```

**HTTPS with self-signed certificate (use `-k` to bypass SSL warnings):**
```bash
curl -k https://PI_IP:8000/pin/17/status
curl -k -X POST https://PI_IP:8000/pin/17/on
curl -k -X POST https://PI_IP:8000/pin/17/off
curl -k -X POST https://PI_IP:8000/pin/17/toggle
curl -k -X POST https://PI_IP:8000/pin/17/pulse
curl -k -X POST "https://PI_IP:8000/pin/17/pulse?delay_ms=1000"
```

**With API key authentication (add `-H "X-API-Key: your-secret-key"`):**
```bash
curl -k -H "X-API-Key: your-secret-key" https://PI_IP:8000/pin/17/status
curl -k -H "X-API-Key: your-secret-key" -X POST https://PI_IP:8000/pin/17/on
curl -k -H "X-API-Key: your-secret-key" -X POST https://PI_IP:8000/pin/17/off
curl -k -H "X-API-Key: your-secret-key" -X POST https://PI_IP:8000/pin/17/toggle
curl -k -H "X-API-Key: your-secret-key" -X POST https://PI_IP:8000/pin/17/pulse
curl -k -H "X-API-Key: your-secret-key" -X POST "https://PI_IP:8000/pin/17/pulse?delay_ms=1000"
```

**Notes:**
- Port 8000 must be open/allowed by any firewall.
- No sudo needed for the server unless your user lacks GPIO permissions.

## Pin Numbering

This service uses **BCM** numbering and supports the following GPIO pins:  
**4, 5, 6, 12, 13, 16, 17, 19, 20, 21, 22, 23, 24, 25, 26, 27**

These pins are safe general-purpose I/O pins that avoid conflicts with I2C, SPI, and UART interfaces.

Common Ground (GND) pins on Raspberry Pi 40-pin header:
- Physical pins 6, 9, 14, 20, 25, 30, 34, 39

Use any GND pin when completing the circuit for your GPIO loads/relays.

## Features

- ✅ Relay-based GPIO control (27 available pins)
- ✅ Active-high relay logic (HIGH = relay on, LOW = relay off)
- ✅ Pin validation (only safe GPIO pins allowed)
- ✅ REST endpoints: `/pin/{pin_number}/{action}`
- ✅ Actions: status, on, off, toggle, pulse
- ✅ Pulse mode: simulates button press with configurable delay (default 500ms)
- ✅ Independent control of multiple relays simultaneously
- ✅ Lazy pin initialization (pins set up on first use)
- ✅ Automatic startup/shutdown GPIO init and cleanup
- ✅ API key authentication support
- ✅ SSL/HTTPS support

## Troubleshooting

**Permission denied**: Run the API with a user that has GPIO access (or use `sudo`).

**GPIO already in use**: Another program may be using the GPIO pin. Reboot or stop the conflicting process.

**Invalid pin error**: Ensure you're using one of the allowed pins: 4, 5, 6, 12, 13, 16, 17, 19, 20, 21, 22, 23, 24, 25, 26, 27.

**Relay not activating**:
- Check wiring: GPIO pin → Relay IN/S, 3.3V → Relay VCC, GND → Relay GND
- Verify correct GPIO pin number (BCM numbering, not physical pin)
- Ensure `python3-lgpio` is installed and the venv uses `--system-site-packages`
- Test relay with a multimeter to confirm it's switching
- Check relay LED indicator (should light when activated)

**USB-C switch not responding**:
- Verify relay COM and NO terminals are connected to USB switch D- and GND
- Test the USB switch button manually to confirm it works
- Check that relay is actually closing when GPIO goes HIGH

## API Endpoints Summary

- `GET /` - List allowed pins and endpoint patterns
- `GET /pin/{pin}/status` - Get current state of a pin
- `POST /pin/{pin}/on` - Activate relay (set GPIO HIGH - relay closes)
- `POST /pin/{pin}/off` - Deactivate relay (set GPIO LOW - relay opens)
- `POST /pin/{pin}/toggle` - Toggle relay state
- `POST /pin/{pin}/pulse?delay_ms=500` - Pulse relay (on→delay→off) to simulate button press

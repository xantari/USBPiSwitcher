#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo "GPIO Switch Controller - Setup Script"
echo "=========================================="
echo ""

# Install system GPIO library
echo "Step 1: Installing python3-lgpio system package..."
sudo apt-get update
sudo apt-get install -y python3-lgpio
echo "✓ python3-lgpio installed"
echo ""

# Create venv with system site packages
echo "Step 2: Creating Python virtual environment..."
if [ -d ".venv" ]; then
    echo "  Removing existing .venv directory..."
    rm -rf .venv
fi
python3 -m venv --system-site-packages .venv
echo "✓ Virtual environment created"
echo ""

# Activate venv and install dependencies
echo "Step 3: Installing Python dependencies (FastAPI + Uvicorn)..."
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
echo "✓ Python dependencies installed"
echo ""

# Optional: configure API key authentication
echo "Step 4: (Optional) Configure API key authentication"
read -r -p "  Enable API key auth? [y/N]: " ENABLE_API_KEY
if [[ "${ENABLE_API_KEY,,}" == "y" || "${ENABLE_API_KEY,,}" == "yes" ]]; then
    read -r -p "  Enter API key value: " INPUT_API_KEY
    if [ -n "${INPUT_API_KEY}" ]; then
        # Persist to environment file for systemd overrides
        echo "GPIO_API_KEY=${INPUT_API_KEY}" > .env.gpio
        echo "  Saved API key to .env.gpio (not world-readable)."
        chmod 600 .env.gpio || true
    else
        echo "  No key entered; skipping API key setup."
    fi
else
    echo "  API key auth not enabled."
fi
echo ""

# Optional: install and enable systemd service for auto-start
echo "Step 5: (Optional) Install systemd service for auto-start on boot..."
SERVICE_FILE="/etc/systemd/system/gpio-switch.service"
if [ -f "gpio-switch.service" ]; then
    # Detect current user and project directory
    CURRENT_USER="${USER}"
    PROJECT_DIR="$(pwd)"
    
    echo "  Detected user: ${CURRENT_USER}"
    echo "  Detected project directory: ${PROJECT_DIR}"
    
    # Create temporary service file with substituted values
    TEMP_SERVICE="/tmp/gpio-switch.service.tmp"
    sed -e "s|<your-username>|${CURRENT_USER}|g" \
        -e "s|/home/<your-username>/Documents|${PROJECT_DIR}|g" \
        gpio-switch.service > "${TEMP_SERVICE}"
    
    echo "  Copying configured service file to ${SERVICE_FILE}"
    sudo cp "${TEMP_SERVICE}" ${SERVICE_FILE}
    rm -f "${TEMP_SERVICE}"
    
    sudo systemctl daemon-reload
    sudo systemctl enable gpio-switch.service
    sudo systemctl restart gpio-switch.service || true
    echo "✓ Service installed and enabled (gpio-switch.service)"
else
    echo "  Skipping: gpio-switch.service not found in current directory"
fi
echo ""

# Optional: SSL certificate setup
echo "Step 6: (Optional) Configure SSL certificates"
read -r -p "  Set up SSL certificates? [y/N]: " SETUP_SSL
if [[ "${SETUP_SSL,,}" == "y" || "${SETUP_SSL,,}" == "yes" ]]; then
    echo ""
    echo "  Choose SSL certificate type:"
    echo "    1) ACME (Let's Encrypt/ZeroSSL via DNS-01) - trusted, works behind firewall"
    echo "    2) Self-signed - quick setup, browser warnings (for testing/internal use)"
    read -r -p "  Enter choice [1/2]: " SSL_CHOICE
    
    if [[ "${SSL_CHOICE}" == "1" ]]; then
        echo ""
        echo "  Installing acme.sh for ACME certificates..."
        curl https://get.acme.sh | sh
        echo "  acme.sh installed under ~/.acme.sh (adds cron for renewals)."

    echo ""
    read -r -p "  Issue a certificate now with DNS-01 (works behind firewall/NAT)? [y/N]: " ISSUE_CERT
    if [[ "${ISSUE_CERT,,}" == "y" || "${ISSUE_CERT,,}" == "yes" ]]; then
        read -r -p "    Enter domain (e.g., gpio.example.com): " ACME_DOMAIN
        read -r -p "    Enter contact email for ACME registration: " ACME_EMAIL
        read -r -p "    Enter DNS provider (e.g., cloudflare, route53, namecheap, etc.): " DNS_PROVIDER
        
        if [ -n "${ACME_DOMAIN}" ] && [ -n "${DNS_PROVIDER}" ]; then
            echo ""
            echo "    DNS API credentials are required for ${DNS_PROVIDER}."
            echo "    See: https://github.com/acmesh-official/acme.sh/wiki/dnsapi"
            echo "    You will need to export environment variables for your DNS provider."
            echo "    Example for Cloudflare: export CF_Token=\"your-token\" CF_Account_ID=\"your-account-id\""
            echo ""
            read -r -p "    Have you exported the required DNS API credentials? [y/N]: " DNS_READY
            
            if [[ "${DNS_READY,,}" == "y" || "${DNS_READY,,}" == "yes" ]]; then
                ~/.acme.sh/acme.sh --register-account -m "${ACME_EMAIL:-admin@${ACME_DOMAIN}}"
                echo "    Issuing certificate via DNS-01 challenge (no ports needed)..."
                ~/.acme.sh/acme.sh --issue --dns dns_${DNS_PROVIDER} -d "${ACME_DOMAIN}"
                
                CERT_DIR="$(pwd)/certs"
                mkdir -p "${CERT_DIR}"
                ~/.acme.sh/acme.sh --install-cert -d "${ACME_DOMAIN}" \
                  --key-file       "${CERT_DIR}/${ACME_DOMAIN}.key" \
                  --fullchain-file "${CERT_DIR}/${ACME_DOMAIN}.crt"
                echo "    Certificates installed to ${CERT_DIR}/${ACME_DOMAIN}.crt and .key"
                
                # Update systemd service with SSL
                SSL_CERT_PATH="${CERT_DIR}/${ACME_DOMAIN}.crt"
                SSL_KEY_PATH="${CERT_DIR}/${ACME_DOMAIN}.key"
                UPDATE_SERVICE_SSL=1
            else
                echo "    Skipping issuance. Export DNS credentials and run acme.sh manually:"
                echo "      ~/.acme.sh/acme.sh --issue --dns dns_${DNS_PROVIDER} -d ${ACME_DOMAIN}"
            fi
        else
            echo "    Domain or DNS provider missing; skipping certificate issuance."
        fi
    else
        echo "  Skipping certificate issuance. You can run acme.sh manually later."
    fi
    
    elif [[ "${SSL_CHOICE}" == "2" ]]; then
        echo ""
        echo "  Generating self-signed certificate..."
        read -r -p "    Enter domain/hostname (e.g., gpio.local or IP): " SELF_DOMAIN
        
        if [ -n "${SELF_DOMAIN}" ]; then
            CERT_DIR="$(pwd)/certs"
            mkdir -p "${CERT_DIR}"
            
            # Generate self-signed cert valid for 50 years
            openssl req -x509 -newkey rsa:4096 -nodes \
              -keyout "${CERT_DIR}/${SELF_DOMAIN}.key" \
              -out "${CERT_DIR}/${SELF_DOMAIN}.crt" \
              -days 18250 \
              -subj "/CN=${SELF_DOMAIN}" 2>/dev/null
            
            echo "    Self-signed certificate created (valid for 50 years):"
            echo "      ${CERT_DIR}/${SELF_DOMAIN}.crt"
            echo "      ${CERT_DIR}/${SELF_DOMAIN}.key"
            echo "    ⚠️  Browsers will show security warnings (untrusted certificate)."
            
            # Update systemd service with SSL
            SSL_CERT_PATH="${CERT_DIR}/${SELF_DOMAIN}.crt"
            SSL_KEY_PATH="${CERT_DIR}/${SELF_DOMAIN}.key"
            UPDATE_SERVICE_SSL=1
        else
            echo "    No domain entered; skipping self-signed certificate generation."
        fi
    
    else
        echo "  Invalid choice; skipping SSL setup."
    fi
else
    echo "  SSL setup skipped."
fi

# Update systemd service file with SSL if configured
if [ "${UPDATE_SERVICE_SSL:-0}" -eq 1 ] && [ -n "${SSL_CERT_PATH:-}" ] && [ -n "${SSL_KEY_PATH:-}" ]; then
    echo "Step 7: Updating systemd service with SSL configuration..."
    if [ -f "${SERVICE_FILE}" ]; then
        # Create backup
        sudo cp "${SERVICE_FILE}" "${SERVICE_FILE}.bak"
        
        # Update ExecStart line to include SSL parameters
        TEMP_SERVICE="/tmp/gpio-switch.service.ssl"
        sudo sed "s|--port 8000|--port 8000 --ssl-certfile ${SSL_CERT_PATH} --ssl-keyfile ${SSL_KEY_PATH}|g" \
            "${SERVICE_FILE}" > "${TEMP_SERVICE}"
        
        sudo cp "${TEMP_SERVICE}" "${SERVICE_FILE}"
        rm -f "${TEMP_SERVICE}"
        
        sudo systemctl daemon-reload
        sudo systemctl restart gpio-switch.service || true
        echo "✓ Service updated with SSL configuration and restarted"
        echo "  Access your API at https://your-domain:8000"
    else
        echo "  Service file not found at ${SERVICE_FILE}. SSL config not applied to service."
        echo "  Manual update: --ssl-certfile ${SSL_CERT_PATH} --ssl-keyfile ${SSL_KEY_PATH}"
    fi
else
    echo "Step 7: SSL not configured for systemd service (no certificates set up)"
fi
echo ""

echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "To start the GPIO controller API:"
echo "  1. Activate the virtual environment:"
echo "       source .venv/bin/activate"
echo "  2. Start the server:"
echo "       uvicorn gpio_switch_fastapi:app --host 0.0.0.0 --port 8000"
echo ""
echo "Or run directly:"
echo "  .venv/bin/uvicorn gpio_switch_fastapi:app --host 0.0.0.0 --port 8000"
echo ""

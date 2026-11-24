#!/usr/bin/env bash
# Open Integration Engine - Linux Universal Installer

set -e

INSTALL_DIR="/opt/openintegrationengine"
SERVICE_NAME="openintegrationengine"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This installer requires superuser privileges." >&2
    echo "Execute: sudo $0" >&2
    exit 1
fi

echo "---- OIE INSTALLATION ----"

# 1. Check if Java exists in the machine (JRE)
JAVA_BIN="$(command -v java || true)"
if [ -z "$JAVA_BIN" ]; then
    echo "ERROR: 'java' was not found in system PATH." >&2
    echo "Install OpenJDK 17+ to continue." >&2
    exit 1
fi

#If there is previous installation -> if it's a new installation it won't run this portion
BACKUP_DIR=""
if [ -d "$INSTALL_DIR/conf" ]; then
    BACKUP_DIR=$(mktemp -d)
    cp -a "$INSTALL_DIR/conf" "$BACKUP_DIR/"
fi

# 2. Decompress integrated payload
echo "Decompressing files in $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

ARCHIVE_LINE=$(awk '/^__ARCHIVE_PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' "$0")
tail -n +"$ARCHIVE_LINE" "$0" | tar -xz -C "$INSTALL_DIR"

# Restores configuration after extraction
if [ -n "$BACKUP_DIR" ]; then
    echo "Restoring previous configuration..."
    cp -a "$BACKUP_DIR/conf/." "$INSTALL_DIR/conf/"
    rm -rf "$BACKUP_DIR"
fi

mkdir -p "$INSTALL_DIR/appdata" "$INSTALL_DIR/logs"

# 3. Link official CLI launchers (preserves oieserver.vmoptions & custom.vmoptions)
chmod +x "$INSTALL_DIR/oieserver" 

cat << EOF > /usr/local/bin/oieserver
#!/bin/sh
cd "$INSTALL_DIR" || exit 1
exec "$INSTALL_DIR/oieserver" "\$@"
EOF
chmod 755 /usr/local/bin/oieserver

cat << EOF > /usr/local/bin/oiecommand
#!/bin/sh
cd "$INSTALL_DIR" || exit 1
exec $JAVA_BIN -jar "$INSTALL_DIR/mirth-cli-launcher.jar" "\$@"
EOF
chmod 755 /usr/local/bin/oiecommand

# Create uninstall script inside the installation folder
cat << 'EOF' > "$INSTALL_DIR/uninstall.sh"
#!/usr/bin/env bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Uninstalling requires superuser privileges." >&2
    exit 1
fi

echo "Stopping and deleting systemd service..."
if [ -d /run/systemd/system ]; then
    systemctl stop openintegrationengine.service 2>/dev/null || true
    systemctl disable openintegrationengine.service 2>/dev/null || true
fi
rm -f /etc/systemd/system/openintegrationengine.service
if [ -d /run/systemd/system ]; then
    systemctl daemon-reload || true
fi

echo "Deleting system commands..."
rm -f /usr/local/bin/oieserver /usr/local/bin/oiecommand

echo "Deleting installation files..."
rm -rf /opt/openintegrationengine

echo "Uninstalling successfully completed."
EOF
chmod 755 "$INSTALL_DIR/uninstall.sh"

# 4. Register systemd service only if systemd is active as PID 1
if [ -d /run/systemd/system ]; then
    echo "Registering systemd service ($SERVICE_NAME)..."
    cat << EOF > /etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=Open Integration Engine Server
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$JAVA_BIN -Ddir.base=$INSTALL_DIR --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED -jar $INSTALL_DIR/mirth-server-launcher.jar
Restart=always
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload || true
    systemctl enable ${SERVICE_NAME}.service || true
    echo "Systemd service correctly configured."
else
    echo "WARNING: No active systemd detected (Container environment). Omitting systemd service configuration."
fi

echo ""
echo "---- INSTALLATION SUCCESSFUL ----"
echo "Directory: $INSTALL_DIR"
echo "Commands available:"
echo "  - oieserver  (Starts the backend engine)"
echo "  - oiecommand (Connects to the CLI console)"
exit 0

__ARCHIVE_PAYLOAD_BELOW__
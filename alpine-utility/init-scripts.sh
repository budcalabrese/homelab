#!/bin/bash
# Alpine Utility Initialization Script
# This script runs on container startup to restore persistent configurations

set -e

CONFIG_DIR="/config"
SCRIPTS_DIR="/config/scripts"
SSH_DIR="/config/ssh"

echo "=== Alpine Utility Initialization ==="

# Create config directories if they don't exist
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$SSH_DIR"

# Restore podcast copy script from persistent storage
if [ -f "$SCRIPTS_DIR/copy-podcast.sh" ]; then
    echo "✓ Restoring podcast copy script..."
    cp "$SCRIPTS_DIR/copy-podcast.sh" /tmp/copy-podcast.sh
    chmod +x /tmp/copy-podcast.sh
else
    echo "⚠ Warning: copy-podcast.sh not found in $SCRIPTS_DIR"
    echo "  Run setup script to create it"
fi

# Restore SSH authorized_keys from persistent storage
if [ -f "$SSH_DIR/authorized_keys" ]; then
    echo "✓ Restoring SSH authorized_keys..."
    mkdir -p /root/.ssh
    cp "$SSH_DIR/authorized_keys" /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
else
    echo "⚠ Warning: authorized_keys not found in $SSH_DIR"
    echo "  SSH key authentication will not work until keys are added"
fi

echo "=== Initialization Complete ==="
echo ""
echo "Status:"
echo "  - Podcast script: $([ -f /tmp/copy-podcast.sh ] && echo 'Ready' || echo 'Missing')"
echo "  - SSH keys: $([ -f /root/.ssh/authorized_keys ] && echo "$(wc -l < /root/.ssh/authorized_keys) key(s) configured" || echo 'None configured')"
echo ""

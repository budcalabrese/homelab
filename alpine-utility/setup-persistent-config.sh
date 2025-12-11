#!/bin/bash
# One-time setup script to store configurations in persistent volume
# Run this script from the host after initial alpine-utility setup

set -e

echo "=== Alpine Utility Persistent Config Setup ==="
echo ""

# Create the podcast copy script in persistent storage
echo "Creating podcast copy script..."
docker exec alpine-utility sh -c 'cat > /config/scripts/copy-podcast.sh << '\''EOF'\''
#!/bin/sh
# Copy podcast files from Open Notebook to AudioBookshelf

EPISODE_NAME="$1"
AUDIO_FILE="$2"
SHOW_NOTES="$3"

TARGET_DIR="/mnt/audiobookshelf/Daily-Digests"

echo "=== Podcast File Copy Script ==="
echo "Episode name: $EPISODE_NAME"
echo "Audio file: $AUDIO_FILE"
echo "Target dir: $TARGET_DIR"

# Copy MP3 from Open Notebook container
echo "Copying MP3 from container..."
docker cp "open-notebook:$AUDIO_FILE" "$TARGET_DIR/$EPISODE_NAME.mp3" 2>&1
if [ $? -eq 0 ]; then
  echo "✓ Audio file copied successfully"
else
  echo "✗ Failed to copy audio file"
  exit 1
fi

# Create show notes file
echo "Creating show notes..."
printf "%s" "$SHOW_NOTES" > "$TARGET_DIR/$EPISODE_NAME.txt"
if [ $? -eq 0 ]; then
  echo "✓ Show notes created"
else
  echo "✗ Failed to create show notes"
  exit 1
fi

echo "=== SUCCESS: All files copied ==="
EOF
chmod +x /config/scripts/copy-podcast.sh
'

echo "✓ Podcast copy script created at /config/scripts/copy-podcast.sh"

# Get n8n's SSH public key
echo ""
echo "Retrieving n8n SSH public key..."
N8N_PUB_KEY=$(docker exec n8n cat /home/node/.ssh/id_ed25519.pub 2>/dev/null || echo "")

if [ -z "$N8N_PUB_KEY" ]; then
    echo "⚠ n8n SSH key not found. Generating new key pair..."
    docker exec n8n sh -c 'mkdir -p ~/.ssh && ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "n8n-to-alpine-utility"'
    N8N_PUB_KEY=$(docker exec n8n cat /home/node/.ssh/id_ed25519.pub)
    echo "✓ New SSH key generated for n8n"
fi

echo "✓ n8n public key: $N8N_PUB_KEY"

# Store authorized_keys in persistent storage
echo ""
echo "Storing SSH authorized_keys in persistent storage..."
docker exec alpine-utility sh -c "mkdir -p /config/ssh && echo '$N8N_PUB_KEY' > /config/ssh/authorized_keys"
echo "✓ SSH authorized_keys saved to /config/ssh/authorized_keys"

# Apply the configurations immediately
echo ""
echo "Applying configurations to running container..."
docker exec alpine-utility /config/init-scripts.sh

# Test SSH connection
echo ""
echo "Testing SSH connection from n8n to alpine-utility..."
if docker exec n8n ssh -p 22 -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@alpine-utility echo "SSH key auth works!" 2>/dev/null; then
    echo "✓ SSH connection successful!"
else
    echo "✗ SSH connection failed. Please check logs."
    exit 1
fi

# Test podcast copy script
echo ""
echo "Testing podcast copy script..."
if docker exec alpine-utility /tmp/copy-podcast.sh "Test Episode" "/dev/null" "Test notes" 2>&1 | grep -q "SUCCESS"; then
    echo "✓ Podcast copy script is executable"
else
    echo "⚠ Podcast copy script test had warnings (this is expected if /dev/null doesn't exist in open-notebook)"
fi

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Configuration stored in:"
echo "  - /Volumes/docker/container_configs/alpine-utility/scripts/copy-podcast.sh"
echo "  - /Volumes/docker/container_configs/alpine-utility/ssh/authorized_keys"
echo ""
echo "These will automatically restore after container rebuilds."
echo ""
echo "To rebuild and test:"
echo "  cd /Users/bud/home_space/homelab"
echo "  docker compose up -d --build alpine-utility"
echo ""

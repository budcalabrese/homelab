#!/bin/bash

# Set root password from environment variable
if [ -n "$ALPINE_UTILITY_PASSWORD" ]; then
    echo "root:$ALPINE_UTILITY_PASSWORD" | chpasswd
    echo "Password set from environment variable"
else
    echo "WARNING: No ALPINE_UTILITY_PASSWORD set, using default 'changeme'"
fi

# Run initialization script if it exists
if [ -f /usr/local/bin/init-scripts.sh ]; then
    echo "Running initialization script..."
    /usr/local/bin/init-scripts.sh
else
    echo "No initialization script found at /usr/local/bin/init-scripts.sh"
fi

# Execute the CMD
exec "$@"

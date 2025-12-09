#!/bin/bash

# Set root password from environment variable
if [ -n "$ALPINE_UTILITY_PASSWORD" ]; then
    echo "root:$ALPINE_UTILITY_PASSWORD" | chpasswd
    echo "Password set from environment variable"
else
    echo "WARNING: No ALPINE_UTILITY_PASSWORD set, using default 'changeme'"
fi

# Execute the CMD
exec "$@"

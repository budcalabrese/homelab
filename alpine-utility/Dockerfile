FROM alpine:latest

# Install necessary packages
RUN apk add --no-cache \
    openssh \
    docker-cli \
    bash \
    curl \
    jq \
    grep \
    coreutils \
    git \
    zip \
    unzip \
    sqlite \
    bc \
    && rm -rf /var/cache/apk/*

# Configure SSH
RUN ssh-keygen -A && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Create scripts directory (will be mounted from host at runtime)
RUN mkdir -p /scripts

# Copy initialization script to /usr/local/bin
COPY init-scripts.sh /usr/local/bin/init-scripts.sh
RUN chmod +x /usr/local/bin/init-scripts.sh

# Set root password (will be overridden by environment variable)
RUN echo "root:changeme" | chpasswd

# Configure SSH to allow root login
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22

# Entrypoint script to set password from env
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]

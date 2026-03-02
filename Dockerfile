# Alpine Linux-based Ansible image for reduced vulnerabilities
FROM nexus.cce3.gpc/python:3.11-alpine


# Install system dependencies
RUN apk update --no-cache && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        openssh-client \
        git \
        ca-certificates \
        bash \
        sshpass \
        curl \
        unzip \
        gcc \
        musl-dev \
        libffi-dev \
        openssl-dev \
        python3-dev \
        py3-pip \
        podman && \
    # Create Docker alias for Podman
    ln -sf /usr/bin/podman /usr/bin/docker && \
    ln -sf /usr/local/bin/python3 /usr/bin/python && \
    rm -rf /var/cache/apk/*

# 👇 Configure pip to use Nexus PyPI proxy
RUN mkdir -p /etc/pip && \
    echo "[global]" > /etc/pip/pip.conf && \
    echo "index-url = https://nexus.cce3.gpc/repository/pypi-proxy/simple" >> /etc/pip/pip.conf && \
    echo "trusted-host = nexus.cce3.gpc" >> /etc/pip/pip.conf

# Install Python packages using Nexus proxy
RUN pip install --no-cache-dir --upgrade "setuptools>=78.1.1" && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir "ansible==9.12.0" && \
    pip install --no-cache-dir requests urllib3 six pyvmomi==8.0.2.0.1 && \
    rm -rf /root/.cache /tmp/*

# Verify installations
RUN echo "=== Python Configuration ===" && \
    python --version && \
    echo "=== Installed Modules ===" && \
    python -c "import requests, urllib3, six, pyVmomi; print('✅ modules available')" && \
    echo "=== Ansible Configuration ===" && \
    ansible --version && \
    echo "=== Container Tools ===" && \
    podman --version

# Create workspace
RUN mkdir -p /workspace
WORKDIR /workspace

# Copy repository content
COPY . /workspace/

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ansible --version || exit 1

# Default command
CMD ["ansible", "--version"]
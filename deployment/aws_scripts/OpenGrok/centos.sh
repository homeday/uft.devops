#!/bin/bash
sudo su
yum update -y

# Install docker 
curl -fsSL https://get.docker.com/ | sh

# Start Docker
systemctl start docker

# Check Docker running Status
systemctl status docker

# Enable auto start on boot 
systemctl enable docker

# Add current user in the Docker group to avoid sudo
usermod -aG docker $(whoami)

# Install docker Compose
curl -L "https://github.com/docker/compose/releases/download/2.5.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose

# Launch a container using docker
/usr/bin/docker-compose up -d




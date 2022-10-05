#!/bin/bash
sudo yum update -y

# Install docker 
curl -fsSL https://get.docker.com/ | sudo sh

# Start Docker
sudo systemctl start docker

# Check Docker running Status
sudo systemctl status docker

# Enable auto start on boot 
sudo systemctl enable docker

# Add current user in the Docker group to avoid sudo
sudo usermod -aG docker $(whoami)

# no need to install docker-compose anymore as docker itself supports that (docker compose ...)
# # Install docker Compose
# curl -L "https://github.com/docker/compose/releases/download/2.5.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
# chmod +x /usr/bin/docker-compose




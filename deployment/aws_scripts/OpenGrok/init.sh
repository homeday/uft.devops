#!/bin/bash

# Reference: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-firewalld-on-centos-7

sudo yum update -y
sudo yum install firewalld -y

# Enable 8080 port
sudo firewall-cmd --zone=public --add-port=8080/tcp

# Start firewalld on boot
sudo systemctl enable firewalld
sudo reboot
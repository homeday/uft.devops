Nginx - Deploy On Host Machine
==================

This document describe how to deploy **Nginx** on host machine.

## Install Nginx
Follow the instructions on the Nginx official web site to install Nginx.

## Configurations
1. Check the `nginx.conf` file on the host machine, typically it should be found in `/etc/nginx/`.
2. You can copy the `nginx.conf` file in this folder to `/etc/nginx/` on the host machine or directly modify the default `nginx.conf` file on the host machine.
3. Copy all `*.conf` files under `default.d` folder to host machine, under `/etc/nginx/default.d/`.
4. Copy all `*.conf` files under `conf.d` folder to host machine, under `/etc/nginx/conf.d/`.

## Start and Enable Nginx
```shell
sudo systemctl start nginx
sudo systemctl status nginx
sudo systemctl enable nginx
```

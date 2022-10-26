File Browser
=============

File Browser is a **create-your-own-cloud-kind** of software where you can install it on a server, direct it to a path and then access your files through a nice web interface. The information of this tool can be found in the [official page](https://filebrowser.org) and the source code is available in [GitHub repository](https://github.com/filebrowser/filebrowser).

> Caution: All the shell scripts are only tested on **CentOS 7**.

## Deployment
File Browser is a single binary and can be used as a standalone executable. Although, some might prefer to use it with Docker or Caddy, which is a fantastic web server that enables HTTPS by default. Its installation is quite straightforward independently on which system you want to use.

> Installtion References
>
>Follow the instructions shown in the [official installation page](https://filebrowser.org/installation).

### Install
Run the following command on the Linux machine to install the File Browser binary.
```shell
sudo curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
```

Check where the binary is installed.
```shell
which filebrowser
```

If the above command failed, it means the path where the binary was put does not appear in the `$PATH`. To fix it, simply run the commands below to move the binary to a common bin path.
```shell
sudo mv /usr/local/bin/filebrowser /usr/bin/filebrowser
sudo chown root:root /usr/bin/filebrowser
sudo chmod ugo+rx /usr/bin/filebrowser
```

### Uninstall
To uninstall, simply remove the binary file.


### Initial Setup
The initial setup is required when first time you run the File Browser. To do so, run the following command to create first time configurations.
```shell
if [ ! -d "/etc/filebrowser" ]; then sudo mkdir -p "/etc/filebrowser"; fi
if [ ! -d "/var/log/filebrowser" ]; then sudo mkdir -p "/var/log/filebrowser"; fi
sudo cp "./rubicon_products/rubicon_products.yml" "/etc/filebrowser/rubicon_products.yml"
sudo cp "./tools/tools.yml" "/etc/filebrowser/tools.yml"
```

### Start File Browser
To start File Browser, use the following command to run the binary with the configuration file at the background and the logs are written to the log file set in the configuration file.
```shell
sudo cp "./rubicon_products/rubicon_products.service" "/etc/systemd/system/filebrowser-rubicon_products.service"
# may need wait a few seconds then run the following commands
sudo systemctl status filebrowser-rubicon_products.service
sudo systemctl enable filebrowser-rubicon_products.service
sudo systemctl start filebrowser-rubicon_products.service
sudo systemctl status filebrowser-rubicon_products.service

sudo cp "./tools/tools.service" "/etc/systemd/system/filebrowser-tools.service"
# may need wait a few seconds then run the following commands
sudo systemctl status filebrowser-tools.service
sudo systemctl enable filebrowser-tools.service
sudo systemctl start filebrowser-tools.service
sudo systemctl status filebrowser-tools.service
```

Use the following command to track the logs.
```shell
tail -f /var/log/filebrowser/rubicon_products.log
tail -f /var/log/filebrowser/tools.log
```

### Reset File Browser
To reset a running file browser:
1. Stop the systemd service
2. Remove the database file
3. Start the systemd service

That's it!


## Quick Facts
#### File Browser for Rubicon Products
| Item | Value |
| ---- | ----- |
| `config file` | `/etc/filebrowser/rubicon_products.yml` |
| `database file` | `/etc/filebrowser/rubicon_products.db` |
| `log file` | `/var/log/filebrowser/rubicon_products.log` |
| `listen on` | `127.0.0.1:8317` |
| `base url` | `/products` |
| `full url` | `http://127.0.0.1:8317/products` |
| `root path` | `/mnt/rubicon/products` |
| `filebrowser cli` | `/bin/filebrowser -c "/etc/filebrowser/rubicon_products.yml" --cache-dir "/tmp/filebrowser/cache"` |
| `systemd service name` | `filebrowser-rubicon_products.service` |
| `systemd service file` | `/etc/systemd/system/filebrowser-rubicon_products.service` |

#### File Browser for Tools
| Item | Value |
| ---- | ----- |
| `config file` | `/etc/filebrowser/tools.yml` |
| `database file` | `/etc/filebrowser/tools.db` |
| `log file` | `/var/log/filebrowser/tools.log` |
| `listen on` | `127.0.0.1:8321` |
| `base url` | `/tools` |
| `full url` | `http://127.0.0.1:8321/tools` |
| `root path` | `/www/tools` |
| `filebrowser cli` | `/bin/filebrowser -c "/etc/filebrowser/tools.yml" --cache-dir "/tmp/filebrowser/cache"` |
| `systemd service name` | `filebrowser-tools.service` |
| `systemd service file` | `/etc/systemd/system/filebrowser-tools.service` |


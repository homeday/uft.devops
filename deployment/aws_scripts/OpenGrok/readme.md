
# Configure and Run OpenGrok

## 1. Prepare the source
Run 'scripts/uft-projs.sh' script with **git username** and **token**. The script will clone all repositories mentioned in repos-uft.list and checkout branches mentioned in branch.list.

```
For Example:
mkdir -p /opengrok/src
sh ./scripts/uft-projs.sh <git_username> <git_token>
```

## 2. Install docker and launch container

1. Run 'init.sh': This will reboot the server
2. Run 'centos.sh': This will install docker, doker-compose and launch container

## Sync

Add a schedule job
```
$crontab -e
// Append below line
0 1 * * * sh /opengrok/scripts/uft-projs.sh uftgithub 0211f662b4b1f6b26aceaa5c1501c4bc67938c41 > /opengrok/sync.log 2>&1
```


## References
```
### Install docker
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-centos-7

### Isntall Docker compose
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-centos-7

### Open 8080 port
https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-firewalld-on-centos-7

```


# Install OpenGrok on Ubuntu 18.04

## A. Install OpenJDK
> Reference: https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-ubuntu-18-04

```sh
sudo apt install openjdk-11-jdk

sudo nano /etc/environment
# add following line(s) to above file
#   JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

java -version
```

## B. Install git-lfs and Configure git
> Reference: https://github.com/git-lfs/git-lfs/wiki/Installation#debian-and-ubuntu

```sh
# install git lfs
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sudo apt-get install git-lfs
git lfs install

# self-signed CA: MSS Root CA (base64).cer
cd /tmp/
sudo mv 'MSS Root CA (base64).cer' MF_MSS_Root_CA.crt
sudo cp MF_MSS_Root_CA.crt /usr/local/share/ca-certificates/MF_MSS_Root_CA.crt
sudo update-ca-certificates

# global setting
git config --global credential.helper store
git config --global user.name 'uftgithub'
git config --global user.password '..............'
```

After installing and configuring git, try to download a repository to enter username and password to be recorded by system.

## C. Install ctags
> Reference: https://github.com/universal-ctags/ctags/blob/master/docs/autotools.rst

```sh
sudo apt install \
    gcc make \
    pkg-config autoconf automake \
    python3-docutils \
    libseccomp-dev \
    libjansson-dev \
    libyaml-dev \
    libxml2-dev

cd /tmp/
git clone https://github.com/universal-ctags/ctags.git
cd ctags
./autogen.sh
./configure --prefix=/usr/local
make
make install

which ctags
```

## D. Install Pip3 (Python)
> Reference: https://linuxize.com/post/how-to-install-pip-on-ubuntu-18.04/#installing-pip-for-python-3

```sh
sudo apt update
sudo apt install python3-pip

pip3 --version
```

## E. Install Apache Tomcat
> Reference: http://tomcat.apache.org/tomcat-9.0-doc/RUNNING.txt

```sh
wget -O /tmp/apache-tomcat-9.0.29.tar.gz http://mirror.metrocast.net/apache/tomcat/tomcat-9/v9.0.29/bin/apache-tomcat-9.0.29.tar.gz

cd /tmp/
tar zxvf /tmp/apache-tomcat-9.0.29.tar.gz
mv /tmp/apache-tomcat-9.0.29 /

sudo nano /etc/environment
# add following line(s) to above file
#   CATALINA_HOME="/apache-tomcat-9.0.29"
#   CATALINA_BASE="/apache-tomcat-9.0.29"

sudo nano /apache-tomcat-9.0.29/bin/setenv.sh
# add following line(s) to above file
#   CATALINA_PID="$CATALINA_BASE/tomcat.pid"

# start
$CATALINA_HOME/bin/catalina.sh start
# stop
$CATALINA_HOME/bin/catalina.sh stop
```

## F. Install OpenGrok
> Reference: https://github.com/oracle/opengrok/wiki/How-to-setup-OpenGrok

```sh
# step 0: prepare source(s)
/opengrok/scripts/prep-src.sh uft uftbase master

# step 1: install management tool (optional)
python3 -m pip install /opengrok/dist/lib/opengrok-tools.tar.gz

# step 2: deploy web app (tomcat)
opengrok-deploy -c /opengrok/etc/configuration.xml \
    /opengrok/dist/lib/source.war /apache-tomcat-9.0.29/webapps

# step 3: first-time indexing to generate configuration.xml file
opengrok-indexer \
    -J=-Djava.util.logging.config.file=/opengrok/etc/logging.properties \
    -a /opengrok/dist/lib/opengrok.jar -- \
    -c /usr/local/bin/ctags \
    -s /opengrok/src -d /opengrok/data -H -P -S -G \
    -W /opengrok/etc/configuration.xml -U http://localhost:8080/source
```

Script files:

- [prep-src.sh](scripts/prep-src.sh)

## G. Add OpenGrok project
> Reference: https://github.com/oracle/opengrok/wiki/Per-project-management

```sh
# add project
opengrok-projadm -b /opengrok -a uftbase

# reindexing
opengrok-indexer \
    -J=-Djava.util.logging.config.file=/opengrok/etc/logging.properties \
    -a /opengrok/dist/lib/opengrok.jar -- \
    -c /usr/local/bin/ctags \
    -s /opengrok/src -d /opengrok/data -H -P -S -G \
    -W /opengrok/etc/configuration.xml -U http://localhost:8080/source

# save changes to configuration.xml
opengrok-projadm -b /opengrok -r
```

## H. Sync projects
> Reference: https://github.com/oracle/opengrok/wiki/Repository-synchronization

```sh
# copy logging.properties.template 
wget -O /opengrok/etc/logging.properties.template https://raw.githubusercontent.com/oracle/opengrok/master/opengrok-tools/logging.properties.template

# --> mirror config yaml file: /opengrok/etc/mirror-config.yml
# --> sync config yaml file: /opengrok/etc/sync-config.yml

# do sync
opengrok-sync -c /opengrok/etc/sync-config.yml -d /opengrok/src/
```

Files:

- [mirror-config.yml](config/mirror-config.yml)
- [sync-config.yml](config/sync-config.yml)

## I. Add periodical sync
### Prepare invariant environments
Create symlink for necessary paths for synchronizing.

```sh
cd /usr/local/etc/
ln -s "/usr/lib/jvm/java-11-openjdk-amd64" lnk_JAVA_HOME
ln -s "/apache-tomcat-9.0.29" lnk_CATALINA_HOME
ln -s "/apache-tomcat-9.0.29" lnk_CATALINA_BASE
ls -l /usr/local/etc/
```

### crontab
> Reference: https://help.ubuntu.com/community/CronHowto

```sh
crontab -e
# add following line to the above file
#   17,47 * * * * /opengrok/scripts/sync.sh > /opengrok/log/sync.log

# show list
crontab -l
```

Script files:

- [sync.sh](scripts/sync.sh)


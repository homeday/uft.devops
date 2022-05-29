#!bin/bash
# sudo su
yum update -y
yum install tree wget -y 

### Installing Java
yum install java-11-openjdk-devel -y
echo JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/bin/java" >> /etc/environment

### Rename to 'java-11-openjdk-amd64'
cp -R /usr/lib/jvm/java-11-openjdk-devel-11.0.14.1.1-1.el7_9.x86_64 /usr/lib/jvm/java-11-openjdk-amd64

### Installing Git (Reference: https://github.com/git-lfs/git-lfs/wiki/Installation#debian-and-ubuntu )
yum install epel-release -y
sudo yum install git -y

#  *** Git LFS
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | sudo bash
yum install git-lfs -y
git lfs install -y

### Add self signed certificate
cp ./MF_MSS_Root_CA.crt  /etc/pki/ca-trust/source/anchors/MF_MSS_Root_CA.crt
update-ca-trust

### Git global setting
git config --global credential.helper cache



### Install Ctag (Reference:  https://github.com/universal-ctags/ctags/blob/master/docs/autotools.rst)
git clone https://github.com/universal-ctags/ctags.git
yum install -y \
	gcc make \
	pkg-config autoconf automake \
	python3-docutils \
	libseccomp-dev \
	libjansson-dev \
	libyaml-dev \
	libxml2-dev
	 
./autogen.sh
./configure --prefix=/usr/local
make
make install


### Install python3 pip (Reference: https://linuxize.com/post/how-to-install-pip-on-ubuntu-18.04/#installing-pip-for-python-3)
yum update -y
yum install -y python3-pip
pip3 --version


### Install Tomcat (Reference: http://tomcat.apache.org/tomcat-9.0-doc/RUNNING.txt)
wget -O /tmp/apache-tomcat-9.0.62.tar.gz https://downloads.apache.org/tomcat/tomcat-9/v9.0.62/bin/apache-tomcat-9.0.62.tar.gz
cd /tmp/
tar zxvf /tmp/apache-tomcat-9.0.62.tar.gz
mv apache-tomcat-9.0.62 /

echo CATALINA_HOME="/apache-tomcat-9.0.62" >> /etc/environment
echo CATALINA_BASE="/apache-tomcat-9.0.62" >> /etc/environment
echo CATALINA_PID="$CATALINA_BASE/tomcat.pid" >> /apache-tomcat-9.0.62/bin/setenv.sh
#echo CATALINA_PID="/apache-tomcat-9.0.62/tomcat.pid" >> /apache-tomcat-9.0.62/bin/setenv.sh

# start
$CATALINA_HOME/bin/catalina.sh start
# stop
$CATALINA_HOME/bin/catalina.sh stop

### Install Opengrok (https://github.com/oracle/opengrok/wiki/How-to-setup-OpenGrok)

# Download opengrok
mkdir -p /opengrok/{src,data,dist,etc,log}

wget -O opengrok-1.7.31.tar.gz https://github.com/oracle/opengrok/releases/download/1.7.31/opengrok-1.7.31.tar.gz
tar -C /opengrok/dist --strip-components=1 -xzf opengrok-1.7.31.tar.gz


# step 0: Get the source at /opengrok/src/uftbase/master
git clone https://svc_ft-auto-01:618b516b843eb4e1d642a55eb5a7a15651021065@github.houston.softwaregrp.net/uft/uftbase.git uftbase/master


# step 1: install management tool (optional)
python3 -m pip install /opengrok/dist/tools/opengrok-tools.tar.gz

# step 2: deploy web app (tomcat)
/usr/local/bin/opengrok-deploy -c /opengrok/etc/configuration.xml /opengrok/dist/lib/source.war /apache-tomcat-9.0.62/webapps
# step 3: first-time indexing to generate configuration.xml file
/usr/local/bin/opengrok-indexer \
	    -J=-Djava.util.logging.config.file=/opengrok/etc/logging.properties \
	    -a /opengrok/dist/lib/opengrok.jar -- \
	    -c /usr/local/bin/ctags \
	    -s /opengrok/src -d /opengrok/data -H -P -S -G \
	    -W /opengrok/etc/configuration.xml -U http://localhost:8080/source
############################3
## Pending from here
############################3
# Add project (https://github.com/oracle/opengrok/wiki/Per-project-management)
# add project "uftbase"
/usr/local/bin/opengrok-projadm -b /opengrok -a uftbase

# Re-indexing
/usr/local/bin/opengrok-indexer \
	-J=-Djava.util.logging.config.file=/opengrok/etc/logging.properties \
	-a /opengrok/dist/lib/opengrok.jar -- \
	-c /usr/local/bin/ctags \
	-s /opengrok/src -d /opengrok/data -H -P -S -G \
	-W /opengrok/etc/configuration.xml -U http://localhost:8080/source

# Save changes
/usr/local/bin/opengrok-projadm -b /opengrok -r

## Repo sync (https://github.com/oracle/opengrok/wiki/Repository-synchronization)

# copy logging.properties.template 
wget -O /opengrok/etc/logging.properties.template https://raw.githubusercontent.com/oracle/opengrok/master/opengrok-tools/logging.properties.template

# Mirror config yaml file
vi /opengrok/etc/mirror-config.yml
>> (file mirror-config.yml)

# Sync config yaml file
vi /opengrok/etc/sync-config.yml
>> (file sync-config.yml)


# Do sync
/usr/local/bin/opengrok-sync -c /opengrok/etc/sync-config.yml -d /opengrok/src/


#!bin/sh
# sudo su
yum update -y

### Installing Java
yum install install openjdk-11-jdk -y
echo JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64" >> /etc/environment


### Installing Git (Reference: https://github.com/git-lfs/git-lfs/wiki/Installation#debian-and-ubuntu )
yum install epel-release -y
sudo yum install git -y

#  *** Git LFS
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | sudo bash
yum install git-lfs -y
git lfs install -y

### Add self signed certificate
cp ./MF_MSS_Root_CA.crt  /usr/local/share/ca-certificates/MF_MSS_Root_CA.crt
update-ca-certificates

### Git global setting
git config --global credential.helper cache


### Install Ctag (Reference:  https://github.com/universal-ctags/ctags/blob/master/docs/autotools.rst)
git clone https://github.com/universal-ctags/ctags.git
apt install -y \
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
apt update
apt install python3-pip
pip3 --version


### Install Tomcat (Reference: http://tomcat.apache.org/tomcat-9.0-doc/RUNNING.txt)
wget -O /tmp/apache-tomcat-9.0.62.tar.gz https://downloads.apache.org/tomcat/tomcat-9/v9.0.62/bin/apache-tomcat-9.0.62.tar.gz
cd /tmp/
tar zxvf /tmp/apache-tomcat-9.0.29.tar.gz
mv /tmp/apache-tomcat-9.0.29 /
nano /etc/environment
	>> CATALINA_HOME="/apache-tomcat-9.0.29"
	>> CATALINA_BASE="/apache-tomcat-9.0.29"

nano /apache-tomcat-9.0.29/bin/setenv.sh
	>> CATALINA_PID="$CATALINA_BASE/tomcat.pid"

# start
$CATALINA_HOME/bin/catalina.sh start
# stop
$CATALINA_HOME/bin/catalina.sh stop
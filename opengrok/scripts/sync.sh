#!/bin/bash

date

echo "Exporting env ..."
source /etc/environment
#export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
#export JAVA_HOME=$(readlink -fn /usr/local/etc/lnk_JAVA_HOME)
#export CATALINA_HOME=$(readlink -fn /usr/local/etc/lnk_CATALINA_HOME)
#export CATALINA_BASE=$(readlink -fn /usr/local/etc/lnk_CATALINA_BASE)

echo "Showing exports ..."
export
echo

echo "Testing necessary executables ..."
echo "  - Java (JDK) version: $(java -version 2>&1 | sed -n ';s/.* version "\(.*\)\.\(.*\)\..*"/\1\2/p;')"
echo "  - git: $(which git)"
echo "  - ctags: $(which ctags)"
echo "  - opengrok-sync: $(which opengrok-sync)"
echo

echo "Synchronizing ..."
/usr/local/bin/opengrok-sync -c /opengrok/etc/sync-config.yml -d /opengrok/src/
ret=$?
echo "Exit code: $ret"

echo "Done!"
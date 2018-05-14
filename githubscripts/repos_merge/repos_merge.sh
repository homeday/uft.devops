#!/bin/bash

label=$1
srcbranch=$2
dstbranch=$3

repolist=$(curl -L -s "https://raw.${GITHUB_SERVER}/uft/uft.devops/master/repolist/${label}.txt")

if [[ "$repolist" =~ "404" ]]; then
    echo $repolist
    exit 1
fi

if [ -f errorreposities.txt ]; then
    rm errorreposities.txt
fi

while IFS='' read -r line; do
	if [ "" != "$line" ]; then
        echo ----------------------------merge of repoistory $line start------------------------------
        git clone https://${GITHUB_USER_TOKEN}@${GITHUB_SERVER}/uft/${line}
        pushd $line
        git ls-remote | grep refs/heads/${srcbranch}
        if [ "$?" != "0" ]; then
            continue
        fi
        git ls-remote | grep refs/heads/${dstbranch}
        if [ "$?" != "0" ]; then
            continue
        fi
        
        if [ "${srcbranch}" != "master" ]; then
            git checkout -b ${srcbranch} origin/${srcbranch}
            git pull
        else
            git checkout master
            git pull            
        fi 

        if [ "${dstbranch}" != "master" ]; then
            git checkout -b ${dstbranch} origin/${dstbranch}
            git pull
        else
            git checkout master
            git pull
        fi 
        
        git merge ${srcbranch}
        if [ "$?" != "0" ]; then
            echo ${dstbranch} >> errorreposities.txt
            continue
        fi
        git push
        popd
        echo ----------------------------merge of repoistory $line end------------------------------
    fi
done <<< "${repolist}"


if [ -f errorreposities.txt ]; then
    echo ----------------------------problem repositories------------------------------
    cat errorreposities.txt
    exit 1
fi
echo ----------------------------merge repositories successfully------------------------------
exit 0





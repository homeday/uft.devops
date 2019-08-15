#!/bin/bash

label=$1
srcbranch=$2
dstbranch=$3
exclude=
all="false"
if [ "$#" -gt 3 ]; then
	param=$4
	if [[ $param == *"exclude="* ]]; then
		IFS='=' read -r -a array <<< "$param"
		exclude=${array[1]}
	fi
	if [ $param == "-a" ]; then
		all="true"
	fi
fi

if [ "$#" -gt 4 ]; then
	param=$5
	if [[ $param == *"exclude="* ]]; then
		IFS='=' read -r -a array <<< "$param"
		exclude=${array[1]}
	fi
	if [ $param == "-a" ]; then
		all="true"
	fi
fi

echo exclude=${exclude}
echo all=${all}


repolist=$(curl -u ${GitHub_Account}:${GITHUB_USER_TOKEN} -L -s "https://raw.${GITHUB_SERVER}/uft/uft.devops/master/repolist/${label}.txt")

if [[ "$repolist" =~ "404" ]]; then
    echo $repolist
    exit 1
fi
echo $repolist

if [ "$all" == "true" ]; then
    repolist="st"$'\n'"uftbase"$'\n'"${repolist}"
fi
echo $repolist



if [ -f errorreposities.txt ]; then
    rm errorreposities.txt
fi

while IFS='' read -r line; do
	if [ "" != "$line" ]; then
        echo ----------------------------merge of repoistory $line start------------------------------
		if [[ $exclude == *"${line}"* ]]; then
			echo "${line} is excluded"
			continue
		fi
        git clone https://${GITHUB_USER_TOKEN}@${GITHUB_SERVER}/uft/${line}
        pushd $line
        git ls-remote | grep refs/heads/${srcbranch}
        if [ "$?" != "0" ]; then
            popd
            continue
        fi
        git ls-remote | grep refs/heads/${dstbranch}
        if [ "$?" != "0" ]; then
            popd
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
        
        echo ----------------------------merge from ${srcbranch} to ${dstbranch} ------------------------------
        git merge ${srcbranch}
        if [ "$?" != "0" ]; then
            popd
            echo ${line} >> errorreposities.txt
            continue
        fi
        git push
        popd
        echo ----------------------------merge of repoistory $line end------------------------------
    fi
done <<< "${repolist}"



if [ -f errorreposities.txt ]; then
    echo ----------------------------problematic repositories------------------------------
    cat errorreposities.txt
    exit 1
fi
echo ----------------------------merge repositories successfully------------------------------
exit 0






source ./githubmgr.sh

export GITHUB_SERVER=github.houston.softwaregrp.net
export GITHUB_USER_TOKEN=ed7d1f40911d99d86dcdfa160a8ecf393d4dfbf7

label=$1
operate=$2
reftype=$3
refname=$4
srcreftype=$5
srcrefname=$6

repolist=$(curl -L -s "https://raw.${GITHUB_SERVER}/uft/uft.devops/master/repolist/${label}.txt")
if [[ "$repolist" =~ "404" ]]; then
    echo $repolist
    exit 1
fi

while IFS='' read -r line; do
	if [ "" != "$line" ]; then
        case $operate in
            "delete")
                delete_ref uft $line $reftype $refname
            ;;
            "update")
                update_and_create_ref_by_srctag uft $line $reftype $refname $srcreftype $srcrefname
            ;;
            *)
            ;;
        esac
    fi
done <<< "${repolist}"










source ./githubmgr.sh

label=$1
operate=$2
reftype=$3
refname=$4
srcreftype=$5
srcrefname=$6

repolist=$(curl -u ${GitHub_Account}:${GITHUB_USER_TOKEN} -L -s "https://raw.${GITHUB_SERVER}/uft/uft.devops/master/repolist/${label}.txt")
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










source ./githubmgr.sh

repo=$1
operate=$2
reftype=$3
refname=$4
srcreftype=$5
srcrefname=$6

re="qtp\..*"
if [ ! "$repo" == "uftbase" ] && [ ! "${repo}" == "st" ] && [ ! "${repo}" == "sprinter" ] && [ ! "${repo}" == "iba" ] && [ ! "${repo}" == "uft.demo.play" ] && [ ! "${repo}" == "UTT" ] && [[ ! $repo =~ $re ]]; then
    echo "not support the repoistory ${repo}!"
    exit 1
fi

case $operate in
    "delete")
        delete_ref uft $repo $reftype $refname
    ;;
    "update")
        update_and_create_ref_by_srctag uft $repo $reftype $refname $srcreftype $srcrefname
    ;;
    *)
    ;;
esac


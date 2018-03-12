label=$1
operate=$2
branchname=$3


repolist=$(curl -L -s "https://raw.${GITHUB_SERVER}/uft/uft.devops/master/repolist/${label}.txt")

if [[ "$repolist" =~ "404" ]]; then
    echo $repolist
    exit 1
fi


get_code_2_src_folder()
{
    reponame=$1
    branchname=$2
    cd "/src"
    git clone "https://${GITHUB_SERVER}/uft/${reponame}.git" "${reponame}/${branchname}"
    pushd "${reponame}/${branchname}"
    git checkout ${branchname}
    git pull
    popd
}

remove_code_in_src_folder() 
{
    reponame=$1
    branchname=$2
    cd "/src"
    if [ -d "${reponame}/${branchname}" ]; then
        rm -rf "${reponame}/${branchname}"
    fi
}

case $operate in
    "delete")
        remove_code_in_src_folder st $branchname
        remove_code_in_src_folder uftbase $branchname
    ;;
    "update")
        get_code_2_src_folder st $branchname
        get_code_2_src_folder uftbase $branchname
    ;;
    *)
    ;;
esac
        
while IFS='' read -r line; do
	if [ "" != "$line" ]; then
        case $operate in
            "delete")
                remove_code_in_src_folder $line $branchname
            ;;
            "update")
                get_code_2_src_folder $line $branchname
            ;;
            *)
            ;;
        esac
    fi
done <<< "${repolist}"



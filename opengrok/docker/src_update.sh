 
update_repo()
{
    repoName=$1
    pushd $repoName > /dev/nul
    for d in ./*;
        do
            if [ -d $d ]; then
                pushd $d > /dev/nul
					git remote prune origin
                    git pull > /dev/nul 2>&1
                popd > /dev/nul
            fi
        done
    popd > /dev/nul
}

update() 
{
    cd /src
    for d in ./*;
        do
            if [ -d $d ]; then
                update_repo $d
            fi
        done
}

while :
do
    date
    update
    sleep 10m
done










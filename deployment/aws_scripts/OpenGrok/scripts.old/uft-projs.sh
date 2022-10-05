#!/bin/bash

org=uft
username="$1"
token="$2"

if [ -z "$username" -o -z "$token" ]; then
    echo "Missing one or more arguments!"
    echo "Usage: uft-projs.sh <username> <Git_token>"
    exit 2
fi


function prepsrc {
    repo="$1"
    echo "Repo Name: $1"	
    while IFS= read -r line
    do
        branch="$line"
        src="/opengrok/src/$repo/$branch"
        # if branch folder exists, skip
        if [ -d "$src" ]; then
            echo "Branch exists: $org/$repo/$branch"
            continue
        fi

        echo "Preparing source: $org/$repo/$branch ..."
        "/opengrok/scripts/prep-src.sh" "$org" "$repo" "$branch" "$username" "$token"
    done < "/opengrok/scripts/branch.list"
}

echo "### Create OpenGrok project or new branches ###"

while IFS= read -r line
do
    repo="$line"
    src="/opengrok/src/$repo"
    # if repo folder exists, skip
    if [ -d "$src" ]; then
        echo "Project exists: $org/$repo"
        prepsrc "$repo"
	echo ""
        continue
    fi

    echo "Creating new project: $org/$repo ..."
    "/opengrok/scripts/new-proj.sh" "$org" "$repo" "$username" "$token"
    echo ""
done < "/opengrok/scripts/repos-uft.list"


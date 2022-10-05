#!/bin/bash

org="$1"
proj="$2"
username="$3"
token="$4"

if [ -z "$org" -o -z "$proj" -o -z "$username" -o -z "$token" ]; then
    echo "Missing one or more arguments!"
    echo "usage: new-proj.sh <org> <proj> <username> <token>"
    exit 2
fi

# prepare source (as per branch.list file)
repo="$proj"
while IFS= read -r line
do
    branch="$line"

    echo "Preparing source: $org/$repo/$branch ..."
    /opengrok/scripts/prep-src.sh "$org" "$repo" "$branch" "$username" "$token"
    echo ""
done < "/opengrok/scripts/branch.list"



#!/bin/bash

# usage:
#   prep-src.sh <org> <repo_name> <branch> <username> <token>

org="$1"
repo="$2"
branch="$3"
username="$4"
token="$5"

if [ -z "$org" -o -z "$repo" -o -z "$branch" -o -z "$username" -o -z "$token" ]; then
    echo "Missing one or more arguments!"
    echo "Usage: prep-src.sh <org> <repo_name> <branch> <username> <Git_token>"
    exit 2
fi

pushd /opengrok/src >/dev/null

# create repo directory
if [ ! -d "$repo" ]; then mkdir "$repo"; fi
pushd "$repo" >/dev/null

# test if branch exists
r=$(git ls-remote --heads --exit-code "https://${username}:${token}@github.houston.softwaregrp.net/${org}/${repo}.git" "refs/heads/$branch")
if [ $? -eq 2 ]; then
    echo "Branch '$branch' does not exist"
    popd >/dev/null
    popd >/dev/null
    exit 3
fi

# checkout branch
git clone -b "$branch" --single-branch "https://${username}:${token}@github.houston.softwaregrp.net/${org}/${repo}.git" "$branch"
pushd "$branch" >/dev/null
git pull
git branch

popd >/dev/null
popd >/dev/null
popd >/dev/null


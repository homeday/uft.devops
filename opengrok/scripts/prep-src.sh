#!/bin/bash

# usage:
#   prep-src.sh <org> <repo_name> <branch>

org="$1"
repo="$2"
branch="$3"

if [ -z "$org" -o -z "$repo" -o -z "$branch" ]; then
    echo "Missing one or more arguments!"
    echo "Usage: prep-src.sh <org> <repo_name> <branch>"
    exit 2
fi

pushd /opengrok/src

# create repo directory
if [ ! -d "$repo" ]; then mkdir "$repo"; fi
pushd "$repo"

# checkout branch
git clone -b "$branch" --single-branch "https://github.houston.softwaregrp.net/${org}/${repo}.git" "$branch"
pushd "$branch"
git pull

popd
popd
popd

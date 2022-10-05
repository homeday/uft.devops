#!/bin/bash

# sync the source code in the <src-dir> and trigger indexing upon all
# docker containers with given container name prefix
# usage: sync-index.sh <git-username> <git-token> <src-dir> <sync-file-git-path> <container-name-prefix> [debug]

# const
VERSION=1.0

# error codes
ERRCODE_GENERAL=1
ERRCODE_WRONGARG=2

# binary settings
docker_bin=docker
curl_bin=curl

# other settings
reindex_ep_port=5000

# arguments
this_file="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
this_dir="$(dirname "$(test -L "$0" && readlink "$0" || echo "$0")")"
username="$1"
token="$2"
src_dir="$3"
sync_file_git_path="$4"
name_prefix="$5"
debug="$6"

# dependent script files
sync_script="${this_dir}/sync-src.sh"
index_script="${this_dir}/index-src.sh"


# function: log text
#   log <text>
log () {
    echo "sync-index: [INFO] $1"
}

# function: log debug text
#   log_debug <text>
log_debug () {
    if [ ! -z "$debug" ]; then
        echo "sync-index: [DEBUG] $1"
    fi
}

# function: log error text with error code
#   log_err <code> <text>
log_err () {
    code=$1
    echo "sync-index: [ERROR ${code}] $2" 1>&2
}

# function: log warning text
#   log_warn <text>
log_warn () {
    echo "sync-index: [WARN] $1"
}


######################
#### main process ####
######################

echo "================================================="
echo "Sync and OpenGrok Indexing v${VERSION}"
echo "- Sync source code and trigger OpenGrok index -"
echo "================================================="
log "Start at: $(date)"
echo ""

if [ -z "$username" -o -z "$token" -o -z "$src_dir" -o -z "$sync_file_git_path" -o -z "$name_prefix" ]; then
    log_err ${ERRCODE_WRONGARG} "Incorrect argument(s)"
    echo "Usage: ${this_file} <git-username> <git-token> <src-dir> <sync-file-git-path> <container-name-prefix> [debug]"
    exit ${ERRCODE_WRONGARG}
fi

# sync source
log "Synchronizing code repositores ..."
echo ""
new_repo_file=$(realpath "${this_dir}/new_repos.txt")
"${sync_script}" "${username}" "${token}" "${src_dir}" "${sync_file_git_path}" "${new_repo_file}" "$debug"
echo ""

# fetch how many docker containers need to be manipulated with name prefix
container_names=$(sudo "${docker_bin}" ps -f "name=${name_prefix}" --format '{{ .Names }}')
log_debug "The following containers need to be manipulated:"
log_debug "${container_names}"

# add new repos as OpenGrok projects
log "Adding new OpenGrok project(s) ..."
while IFS= read -r proj; do
    log_debug "Found new OpenGrok project: $proj"
    echo "${container_names}" | while IFS= read -r ctname; do
        log "Adding new project: $proj upon container: $ctname"
        sudo "${docker_bin}" exec "$ctname" opengrok-projadm -b /opengrok -a "$proj" -U http://localhost:8080
    done
done < "${new_repo_file}"
log "Completed to add new OpenGrok project(s)"
echo ""

# trigger indexing
log "Triggering OpenGrok indexing ..."
echo "${container_names}" | while IFS= read -r ctname; do
    "${index_script}" "${ctname}" "${reindex_ep_port}" "$debug"
done


echo ""
log "Finished at: $(date)"

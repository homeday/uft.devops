#!/bin/bash

# sync source code with sync settings and store in <src-dir>
# usage: sync-src.sh <git-username> <git-token> <src-dir> <sync-file-git-path> [new-repo-out-file] [debug]

# const
VERSION=1.0

# error codes
ERRCODE_GENERAL=1
ERRCODE_WRONGARG=2
ERRCODE_CANTDOWNLOADSYNCFILE=3
ERRCODE_NOSYNCFILE=4

# binary settings
git_bin=git

# github settings
github_protocol=https
github_host=github.houston.softwaregrp.net
github_raw_host=raw.github.houston.softwaregrp.net

# global variables
sync_file_remote_uri=""
repos=()
branches=()
branches_skip=()
branches_spec=()

# arguments
this_file="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
this_dir="$(dirname "$(test -L "$0" && readlink "$0" || echo "$0")")"
username="$1"
token="$2"
src_dir="$3"
sync_file_git_path="$4"
new_repo_out_file="$5"
debug="$6"


# function: log text
#   log <text>
log () {
    echo "$(date +"%Y-%m-%d %H:%M:%S %Z") <sync-src> [INFO] $1"
}

# function: log debug text
#   log_debug <text>
log_debug () {
    if [ ! -z "$debug" ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S %Z") <sync-src> [DEBUG] $1"
    fi
}

# function: log error text with error code
#   log_err <code> <text>
log_err () {
    code=$1
    echo "$(date +"%Y-%m-%d %H:%M:%S %Z") <sync-src> [ERROR ${code}] $2" 1>&2
}

# function: log warning text
#   log_warn <text>
log_warn () {
    echo "$(date +"%Y-%m-%d %H:%M:%S %Z") <sync-src> [WARN] $1"
}

# function: donwload sync file
#   download_sync_file <target-file>
download_sync_file () {
    local target_file="$1"
    local uri=
    curl -sSL "${github_protocol}://${username}:${token}@${github_raw_host}/${sync_file_git_path}" -o "$target_file"
    local r=$?
    if [ $r -eq 0 ]; then
        log_debug "Sync file is downloaded to: $target_file"
    else
        log_err ${ERRCODE_CANTDOWNLOADSYNCFILE} "Failed to download sync file with URI: ${github_protocol}://${github_raw_host}/${sync_file_git_path}"
        if [ -f "$target_file" ]; then rm -f "$target_file"; fi
        exit ${ERRCODE_CANTDOWNLOADSYNCFILE}
    fi
}

# function: read sync file and parse repos and branches to be sync
#   parse_sync_file <sync-file>
parse_sync_file () {
    local file="$1"
    log_debug "Parsing sync file: $file"

    local section_type=""
    local org_name=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then                 # empty line
            continue
        elif [[ ${line::1} == "#" ]]; then      # line starts with '#'
            log_debug "Skipped line starts with '#'"
        elif [[ "$line" == *"[org:"* ]]; then   # [org:xxx] section
            section_type="org"
            org_name=$(echo "$line" | cut -d ':' -f2 | cut -d ']' -f1)
            log_debug "Section found: org = ${org_name}"
        elif [ "$line" == "[branch]" ]; then   # [branch] section
            section_type="branch"
            log_debug "Section found: branch"
        elif [ "$line" == "[branch-skip]" ]; then   # [branch-skip] section
            section_type="branch-skip"
            log_debug "Section found: branch-skip"
        elif [ "$line" == "[branch-spec]" ]; then   # [branch-spec] section
            section_type="branch-spec"
            log_debug "Section found: branch-spec"
        else
            # items belongs to the current section
            if [ -z "section_type" ]; then
                log_warn "Item found but not under any section, ignored: $line"
                continue
            fi

            # process item
            if [ "${section_type}" == "org" ]; then     # for item under org section
                repo="${org_name}/$line"
                repos+=( "$repo" )
                log_debug "Repo found: $repo"
            elif [ "${section_type}" == "branch" ]; then   # for item under branch section
                branch="$line"
                branches+=( "$branch" )
                log_debug "Branch found: $branch"
            elif [ "${section_type}" == "branch-skip" ]; then   # for item under branch-skip section
                branch="$line"
                branches_skip+=( "$branch" )
                log_debug "Branch (skip) found: $branch"
            elif [ "${section_type}" == "branch-spec" ]; then   # for item under branch-spec section
                branch="$line"
                branches_spec+=( "$branch" )
                log_debug "Branch (spec) found: $branch"
            fi
        fi
    done < "$file"
    log_debug "Completed to parse sync file: $file"
}

# function: fetch the remote branches for the repo with branch pattern
#   fetch_remote_branches <org> <repo> <branch-pattern>
#   return value: print a list of branches fetched (one branch name per line)
fetch_remote_branches () {
    local org="$1"
    local repo="$2"
    local branch="$3"
    "${git_bin}" ls-remote --heads "${github_protocol}://${username}:${token}@${github_host}/${org}/${repo}.git" "refs/heads/$branch" \
        | cut -f2 \
        | cut -d '/' -f3-   # refs/heads/<branch> -> <branch>
}

# function: determine if the given branch appears in the skip list
#   is_branch_need_skip <branch>
#   return value: 0 (no-need-skip); 1 (need-skip)
is_branch_need_skip () {
    local branch="$1"
    for skip_branch in "${branches_skip[@]}"; do
        # the given branch appears in the skip list
        if [ "$branch" == "${skip_branch}" ]; then return 1; fi
    done
    return 0
}

# function: sync the source code for the given repo and branch
#   sync <org> <repo> <branch>
sync () {
    local org="$1"
    local repo="$2"
    local branch="$3"

    # go to directory that stores the source code
    if [ ! -d "${src_dir}" ]; then
        mkdir -p "${src_dir}"
        log_debug "Source directory is created: ${src_dir}"
    fi
    pushd "${src_dir}" > /dev/null

    # go to repo directory
    repo_dir="$repo"
    if [ ! -d "${repo_dir}" ]; then
        mkdir "${repo_dir}"
        log_debug "Repo directory is created: ${repo_dir}"
        echo "${repo_dir}" >> "${new_repo_out_file}"
        log "New repo is found: ${repo_dir}"
    fi
    pushd "${repo_dir}" > /dev/null

    # go to branch directory (the branch directory is a git repo)
    branch_dir=$(echo "$branch" | sed -e 's:/:-:g' | sed -e 's/ /_/g')
    if [ ! -d "${branch_dir}" ]; then
        # clone single branch for the repo
        log "Cloning repo '${org}/${repo}' with single branch '$branch' ..."
        "${git_bin}" clone -b "$branch" --single-branch "${github_protocol}://${username}:${token}@${github_host}/${org}/${repo}.git" "${branch_dir}"
    fi
    pushd "${branch_dir}" > /dev/null

    # pull latest code
    log "Updating to latest code for '${org}/${repo}/${branch}' ..."
    "${git_bin}" pull

    popd > /dev/null # pushd $branch_dir
    popd > /dev/null # pushd $repo_dir
    popd > /dev/null # pushd $src_dir
}


######################
#### main process ####
######################

echo "======================================"
echo "GitHub Source Sync v${VERSION}"
echo "- Clone or update Git repositories -"
echo "======================================"
echo ""
log "Sync started"

if [ -z "$username" -o -z "$token" -o -z "$src_dir" -o -z "$sync_file_git_path" ]; then
    log_err ${ERRCODE_WRONGARG} "Incorrect argument(s)"
    echo "Usage: ${this_file} <git-username> <git-token> <src-dir> <sync-file-git-path> [new-repo-out-file] [debug]"
    exit ${ERRCODE_WRONGARG}
fi

if [ -z "${new_repo_out_file}" ]; then new_repo_out_file="${this_dir}/new_repos.txt"; fi
new_repo_out_file=$(realpath "${new_repo_out_file}")
log_debug "Truncate file: ${new_repo_out_file}"
cat /dev/null > "${new_repo_out_file}"


# download sync file from remote site
log "Retrieving sync file from GitHub ..."
sync_file=$(realpath "${this_dir}/sync.txt")
download_sync_file "${sync_file}"
if [ ! -f "${sync_file}" ]; then
    log_err ${ERRCODE_NOSYNCFILE} "Can't download the OpenGrok sync file"
    exit ${ERRCODE_NOSYNCFILE}
fi
log "Sync file is retrieved"

# read sync file and parse repos and branches to be sync
parse_sync_file "${sync_file}"

# for each repo that need to be sync, fetch remote branch names
# as per branch settings in sync file, skip the one in skip list
# and add all those in spec list, if applicable
#
# after that, clone the branch if the it is never cloned locally;
# or git pull to the latest commit for the already cloned branch
for repo in "${repos[@]}"; do
    # the item in repos array contains both org and repo (<org>/<repo>)
    # here split into two variables
    this_org=$(echo "$repo" | cut -d '/' -f1)
    this_repo=$(echo "$repo" | cut -d '/' -f2)
    for this_branch in "${branches[@]}"; do
        # fetch all remote branch names with the repo and branch parsed in the sync file
        fetch_remote_branches "${this_org}" "${this_repo}" "${this_branch}" | \
            while IFS= read -r remote_branch
            do
                # skip the remote branch if it appears in the skip list
                is_branch_need_skip "${remote_branch}"
                if [ $? -eq 1 ]; then
                    log_warn "Branch is skipped: ${this_org}/${this_repo}/${remote_branch}"
                else
                    log "Sync start: ${this_org}/${this_repo}/${remote_branch} ..."
                    sync "${this_org}" "${this_repo}" "${remote_branch}"
                    log "Sync completed: ${this_org}/${this_repo}/${remote_branch}"
                fi
            done
    done
done

for branch in "${branches_spec[@]}"; do
    # the item in branches_spec array contains org, repo and branch in format <org>/<repo>/<branch>
    # here split into thress variables
    this_org=$(echo "$branch" | cut -d '/' -f1)
    this_repo=$(echo "$branch" | cut -d '/' -f2)
    this_branch=$(echo "$branch" | cut -d '/' -f3-)
    log "Sync start: ${this_org}/${this_repo}/${this_branch} ..."
    sync "${this_org}" "${this_repo}" "${this_branch}"
    log "Sync completed: ${this_org}/${this_repo}/${this_branch}"
done

echo ""
log "Sync completed"

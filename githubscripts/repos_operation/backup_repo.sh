#!/bin/bash

script_dir=$(dirname $(readlink -f $0))
sh_name=$0

sh_desc="Backup GIT repository in local."
sh_usage=$(cat <<-END

Usage: "${sh_name}" [options] org/repo target-dir

positional parameter
  org/repo          organization and repository name, separated by "/"
  target-dir        a directory in which the git repository will be cloned
                    if omitted, current working directory is used

options
  -b BASE_URL=https://github.houston.softwaregrp.net
                    base URL of Github in which the repository is hosted
  -r REMOTE_NAME=origin
                    remote ref name in repository, defaults to "origin"
  -h                show this help text and exit

Samples:
  "${sh_name}" myorg/test1 mydir
END
)


##################### GET COMMAND OPTIONS - START ####################

OPTIND=1
while getopts ":b:r:h" opt; do
    case $opt in
        b)
            base_url="$OPTARG"
            ;;
        r)
            remote_name="$OPTARG"
            ;;

        # Help
        h)
            echo "${sh_desc}" && echo "${sh_usage}"
            exit 0
            ;;

        # error / exception
        [?])
            echo "Invalid option: -$OPTARG. Add option '-h' to get help." >&2
            exit 1
            ;;
        :)
            echo "Option '-$OPTARG' requires an argument." no-time >&2
            exit 2
            ;;
    esac
done
shift $((OPTIND-1))

##################### GET COMMAND OPTIONS - END ####################

repo_full_name="$1"
target_dir="$2"

if [ -z "${repo_full_name}" ]; then echo "The organization and repository name is not specified." && echo "${sh_usage}"; exit 1; fi

if [ -z "${target_dir}" ]; then target_dir="."; fi
if [ -z "${remote_name}" ]; then remote_name="origin"; fi
if [ -z "${base_url}" ]; then base_url="https://github.houston.softwaregrp.net"; fi

repo_clone_url="${base_url}/${repo_full_name}.git"

# clone
echo "Cloning git repository via: ${repo_clone_url} ..."
if [ ! -d "${target_dir}" ]; then mkdir -p "${target_dir}"; fi
git clone "${repo_clone_url}" "${target_dir}"


pushd "${target_dir}" >/dev/null

# fetch all, including tags
git fetch --all --tags
echo ""

# list all remote branches
# for each remote branch, checkout and ensure pull is run
while IFS='' read -r remote_branch || [[ -n "${remote_branch}" ]]; do
    # git branch -r returns line like "  origin/master"

    # trim leading whitespaces, which becomes "origin/master"
    br_no_space=$(echo "${remote_branch}" | xargs)

    # remove leading remote name, which becomes "master"
    rn="${remote_name}/"
    br=$(echo "${br_no_space#$rn}")

    # skip "origin/HEAD -> origin/master"
    if [[ "$br" =~ ^HEAD\ +\-\>\ .* ]]; then echo "The '${br_no_space}' remote ref is not a branch, skipped."; fi

    # for a remote branch, checkout and pull
    echo "Checking out remote branch '${br_no_space}' and pulling ..."
    echo "---------------------------------------"
    git checkout --force "$br"
    git pull
    echo "---------------------------------------" && echo ""
done <<< "$(git branch -r)"

popd >/dev/null


echo "The repository '${repo_full_name}' is backup successfully!"

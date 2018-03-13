#!/bin/bash

script_dir=$(dirname $(readlink -f $0))
sh_name=$0

sh_desc="Update GIT repository."
sh_usage=$(cat <<-END

Usage: "${sh_name}" [options] org repo

positional parameter
  org               organization name
  repo              repository name

options
  -n NAME           repository new name, if omitted, name is not changed
  -d DSEC           repository description
  -i                disable "issues"
  -j                disable "projects"
  -k                disable "wiki"
  -m                prevent merging pull requests with merge commits
  -q                prevent squash-merging pull requests
  -r                prevent rebase-merging pull requests

  -b BASE_API_URL=https://github.houston.softwaregrp.net/api/v3
                    base URL of Github API
  -t GITHUB_TOKEN   token to be used to send Github API request, if omitted,
                    try environment variable 'GITHUB_USER_TOKEN' first and
                    then use default one
  -h                show this help text and exit

Samples:
  "${sh_name}" -m -r myorg test1
END
)


##################### GET COMMAND OPTIONS - START ####################

OPTIND=1
while getopts ":n:d:ijkmqrb:t:h" opt; do
    case $opt in
        n)
            repo_new_name="$OPTARG"
            ;;
        d)
            repo_desc="$OPTARG"
            ;;
        i)
            disable_issues="true"
            ;;
        j)
            disable_projects="true"
            ;;
        k)
            disable_wiki="true"
            ;;
        m)
            disable_merge_commit="true"
            ;;
        q)
            disable_squash_merge="true"
            ;;
        r)
            disable_rebase_merge="true"
            ;;

        # Github API and token
        b)
            base_api_url="$OPTARG"
            ;;
        t)
            github_token="$OPTARG"
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

org_name="$1"
repo_name="$2"

if [ -z "${org_name}" ]; then echo "The organization name is not specified." && echo "${sh_usage}"; exit 1; fi
if [ -z "${repo_name}" ]; then echo "The repository name is not specified." && echo "${sh_usage}"; exit 2; fi

if [ -z "${repo_new_name}" ]; then repo_new_name="${repo_name}"; fi

if [ -z "${base_api_url}" ]; then base_api_url="https://github.houston.softwaregrp.net/api/v3"; fi
if [ -z "${github_token}" ]; then github_token="${GITHUB_USER_TOKEN}"; fi
if [ -z "${github_token}" ]; then github_token="0211f662b4b1f6b26aceaa5c1501c4bc67938c41"; fi

# https://developer.github.com/v3/repos/#edit
req_method="PATCH"
api_endpoint="/repos/${org_name}/${repo_name}"
full_api_url="${base_api_url}${api_endpoint}"

data="{\"name\":\"${repo_new_name}\""
if [ -n "${repo_desc}" ]; then data="$data,\"description\":\"${repo_desc}\""; fi
if [ "${disable_issues}" = "true" ]; then data="$data,\"has_issues\":false"; fi
if [ "${disable_projects}" = "true" ]; then data="$data,\"has_projects\":false"; fi
if [ "${disable_wiki}" = "true" ]; then data="$data,\"has_wiki\":false"; fi
if [ "${disable_merge_commit}" = "true" ]; then data="$data,\"allow_merge_commit\":false"; fi
if [ "${disable_squash_merge}" = "true" ]; then data="$data,\"allow_squash_merge\":false"; fi
if [ "${disable_rebase_merge}" = "true" ]; then data="$data,\"allow_rebase_merge\":false"; fi
data="$data}"

http_code=$(curl --silent --output /dev/null --write-out %{http_code} \
    --request "${req_method}" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer ${github_token}" \
    --data "$data" \
    "${full_api_url}"
)
if [ "${http_code}" != "200" ]; then
    echo "Failed to send Github API request to update repository '${org_name}/${repo_name}'. HTTP CODE: ${http_code}"
    exit 9
fi

echo "${org_name}/${repo_name} ... Updated"

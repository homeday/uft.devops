#!/bin/bash

script_dir=$(dirname $(readlink -f $0))
sh_name=$0

sh_desc="Manage required status checks for branch of GIT repository."
sh_usage=$(cat <<-END

Usage: "${sh_name}" [options] org/repo branch [context1 [context2 ...]]

positional parameter
  org/repo          organization and repository name, separated by "/"
  branch            branch name(s) on which to manage required status checks
  context1..N       required status checks contexts of protected branch to be
                    added, replaced or deleted

options
  -l                list required status checks contexts of protected branch,
                    in json format
  -a                add required status checks contexts of protected branch
  -r                replace required status checks contexts of protected branch
  -d                delete required status checks contexts of protected branch

  -b BASE_API_URL=https://github.houston.softwaregrp.net/api/v3
                    base URL of Github API
  -t GITHUB_TOKEN   token to be used to send Github API request, if omitted,
                    try environment variable 'GITHUB_USER_TOKEN' first and
                    then use default one
  -h                show this help text and exit

Samples:
  "${sh_name}" -a myorg/test1 master ci/jenkins release/doc
END
)


##################### GET COMMAND OPTIONS - START ####################

OPTIND=1
while getopts ":lardb:t:h" opt; do
    case $opt in
        l)
            mode="list"
            ;;
        a)
            mode="add"
            ;;
        r)
            mode="replace"
            ;;
        d)
            mode="delete"
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

repo_full_name="$1"
branch_name="$2"
shift 2

if [ -z "${repo_full_name}" ]; then echo "The organization and repository name is not specified." && echo "${sh_usage}"; exit 1; fi
if [ -z "${branch_name}" ]; then echo "The branch name is not specified." && echo "${sh_usage}"; exit 2; fi

if [ -z "${base_api_url}" ]; then base_api_url="https://github.houston.softwaregrp.net/api/v3"; fi
if [ -z "${github_token}" ]; then github_token="${GITHUB_USER_TOKEN}"; fi
if [ -z "${github_token}" ]; then github_token="0211f662b4b1f6b26aceaa5c1501c4bc67938c41"; fi

contexts="["
first_ctx="true"
while true; do
    ctx="$1"
    if [ -z "$ctx" ]; then break; fi
    shift

    if [ "${first_ctx}" = "true" ]; then
        first_ctx="false"
    else
        contexts="${contexts},"
    fi
    contexts="${contexts}\"${ctx}\""
done
contexts="${contexts}]"

if [ "${mode}" = "add" ]; then
    # add mode
    # https://developer.github.com/v3/repos/branches/#add-required-status-checks-contexts-of-protected-branch
    req_method="POST"
    api_endpoint="/repos/${repo_full_name}/branches/${branch_name}/protection/required_status_checks/contexts"
    full_api_url="${base_api_url}${api_endpoint}"

    http_code=$(curl --silent --output /dev/null --write-out %{http_code} \
        --request "${req_method}" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer ${github_token}" \
        --data "${contexts}" \
        "${full_api_url}"
    )
    if [ "${http_code}" = "200" ]; then
        echo "${repo_full_name} @${branch_name} ... Context(s) Added"
    else
        echo "Failed to send Github API request to add contexts to protect branch '${branch_name}' in repository '${repo_full_name}'. HTTP CODE: ${http_code}"
        exit 9
    fi
elif [ "${mode}" = "replace" ]; then
    # replace mode
    # https://developer.github.com/v3/repos/branches/#replace-required-status-checks-contexts-of-protected-branch
    req_method="PUT"
    api_endpoint="/repos/${repo_full_name}/branches/${branch_name}/protection/required_status_checks/contexts"
    full_api_url="${base_api_url}${api_endpoint}"

    http_code=$(curl --silent --output /dev/null --write-out %{http_code} \
        --request "${req_method}" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer ${github_token}" \
        --data "${contexts}" \
        "${full_api_url}"
    )
    if [ "${http_code}" = "200" ]; then
        echo "${repo_full_name} @${branch_name} ... Context(s) Replaced"
    else
        echo "Failed to send Github API request to replace contexts on protect branch '${branch_name}' in repository '${repo_full_name}'. HTTP CODE: ${http_code}"
        exit 9
    fi
elif [ "${mode}" = "delete" ]; then
    # delete mode
    # https://developer.github.com/v3/repos/branches/#remove-required-status-checks-contexts-of-protected-branch
    req_method="DELETE"
    api_endpoint="/repos/${repo_full_name}/branches/${branch_name}/protection/required_status_checks/contexts"
    full_api_url="${base_api_url}${api_endpoint}"

    http_code=$(curl --silent --output /dev/null --write-out %{http_code} \
        --request "${req_method}" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer ${github_token}" \
        --data "${contexts}" \
        "${full_api_url}"
    )
    if [ "${http_code}" = "200" ]; then
        echo "${repo_full_name} @${branch_name} ... Context(s) Deleted"
    else
        echo "Failed to send Github API request to delete contexts from protect branch '${branch_name}' in repository '${repo_full_name}'. HTTP CODE: ${http_code}"
        exit 9
    fi
fi


# always list contexts
# https://developer.github.com/v3/repos/branches/#list-required-status-checks-contexts-of-protected-branch
req_method="GET"
api_endpoint="/repos/${repo_full_name}/branches/${branch_name}/protection/required_status_checks/contexts"
full_api_url="${base_api_url}${api_endpoint}"

curl --silent --request "${req_method}" \
    --header "Authorization: Bearer ${github_token}" \
    "${full_api_url}"

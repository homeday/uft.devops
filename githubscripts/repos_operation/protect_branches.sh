#!/bin/bash

script_dir=$(dirname $(readlink -f $0))
sh_name=$0

sh_desc="Protect branch(es) for GIT repository."
sh_usage=$(cat <<-END

Usage: "${sh_name}" [options] org/repo branch1 [branch2 ...]

positional parameter
  org/repo          organization and repository name, separated by "/"
  branch1..N        branch name(s) to protect

options
 Require pull request approving review
  -p                require at least one approving review on a pull request,
                    before merging
  -d                dismiss approved reviews automatically when a new commit
                    is pushed, takes effect only when "-p" is given

 Require status checks
  -s                require status checks to pass before merging
  -r                require branches to be up to date before merging, takes
                    effect when "-s" is given

 Others
  -a                enforce all configured restrictions for administrators
  -z                remove branch protection

  -b BASE_API_URL=https://github.houston.softwaregrp.net/api/v3
                    base URL of Github API
  -t GITHUB_TOKEN   token to be used to send Github API request, if omitted,
                    try environment variable 'GITHUB_USER_TOKEN' first and
                    then use default one
  -h                show this help text and exit

Samples:
  "${sh_name}" -p -d myorg/test1 master br_1.0
END
)


##################### GET COMMAND OPTIONS - START ####################

OPTIND=1
while getopts ":pdsrazb:t:h" opt; do
    case $opt in
        p)
            approved_review="true"
            ;;
        d)
            dismiss_stale_reviews="true"
            ;;
        s)
            status_checks="true"
            ;;
        r)
            branch_uptodate="true"
            ;;
        a)
            enforce_admins="true"
            ;;
        z)
            remove_protection="true"
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
shift

if [ -z "${repo_full_name}" ]; then echo "The organization and repository name is not specified." && echo "${sh_usage}"; exit 1; fi

if [ -z "${base_api_url}" ]; then base_api_url="https://github.houston.softwaregrp.net/api/v3"; fi
if [ -z "${github_token}" ]; then github_token="${GITHUB_USER_TOKEN}"; fi
if [ -z "${github_token}" ]; then github_token="0211f662b4b1f6b26aceaa5c1501c4bc67938c41"; fi


if [ "${remove_protection}" = "true" ]; then
    # https://developer.github.com/v3/repos/branches/#remove-branch-protection
    req_method="DELETE"
    while true; do
        branch_name="$1"
        if [ -z "${branch_name}" ]; then break; fi
        shift

        api_endpoint="/repos/${repo_full_name}/branches/${branch_name}/protection"
        full_api_url="${base_api_url}${api_endpoint}"

        #echo "[${req_method}] ${full_api_url}"
        http_code=$(curl --silent --output /dev/null --write-out %{http_code} \
            --request "${req_method}" \
            --header "Authorization: Bearer ${github_token}" \
            "${full_api_url}"
        )

        echo -n "${repo_full_name} @${branch_name} ... "
        if [ "${http_code}" = "204" ]; then
            echo "Deleted"
        elif [ "${http_code}" = "404" ]; then
            echo "Skipped"
        else
            echo "Failed"
            echo "Failed to send Github API request to delete branch protection. Branch '${branch_name}' in repository '${repo_full_name}'. HTTP CODE: ${http_code}"
            exit 9
        fi
    done
else
    # https://developer.github.com/v3/repos/branches/#update-branch-protection
    req_method="PUT"

    data='{"restrictions":null'

    data="${data},\"required_pull_request_reviews\""
    if [ "${approved_review}" = "true" ]; then
        data="${data}:{\"dismiss_stale_reviews\""
        if [ "${dismiss_stale_reviews}" = "true" ]; then
            data="${data}:true"
        else
            data="${data}:false"
        fi
        data="$data}"
    else
        data="${data}:null"
    fi

    data="${data},\"required_status_checks\""
    if [ "${status_checks}" = "true" ]; then
        data="${data}:{\"strict\""
        if [ "${branch_uptodate}" = "true" ]; then
            data="${data}:true"
        else
            data="${data}:false"
        fi
        data="$data,\"contexts\":[]}"
    else
        data="$data:null"
    fi

    data="$data,\"enforce_admins\""
    if [ "${enforce_admins}" = "true" ]; then
        data="$data:true"
    else
        data="$data:null"
    fi

    data="$data}"

    # echo "$data"

    while true; do
        branch_name="$1"
        if [ -z "${branch_name}" ]; then break; fi
        shift

        api_endpoint="/repos/${repo_full_name}/branches/${branch_name}/protection"
        full_api_url="${base_api_url}${api_endpoint}"

        # echo "[${req_method}] ${full_api_url}"
        http_code=$(curl --silent --output /dev/null --write-out %{http_code} \
            --request "${req_method}" \
            --header 'Content-Type: application/json' \
            --header "Authorization: Bearer ${github_token}" \
            --data "$data" \
            "${full_api_url}"
        )
        if [ "${http_code}" = "200" ]; then
            echo "${repo_full_name} @${branch_name} ... Protected"
        else
            echo "Failed to send Github API request to protect branch '${branch_name}' in repository '${repo_full_name}'. HTTP CODE: ${http_code}"
            exit 9
        fi
    done

fi

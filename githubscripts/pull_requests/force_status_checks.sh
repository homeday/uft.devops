#!/bin/bash

script_dir=$(dirname $(readlink -f $0))
sh_name=$0

sh_desc="Apply a force Github pull request status checks."
sh_usage=$(cat <<-END

Usage: "${sh_name}" [options] org/repo pr-id status-check1 [status-check2 ...]

positional parameter
  org/repo          organization name and repository name, separated by "/"
  pr-id             pull request ID on which apply the force status check
  status-check1..N  one or more status checks to set "success" status

options
  -u USER           who request force PR status checks
  -m MESSAGE        message to request force PR status checks
  -r URL            status check target URL

  -b BASE_API_URL=https://github.houston.softwaregrp.net/api/v3
                    base URL of Github API to apply PR review
  -t GITHUB_TOKEN   token to be used to send Github API request, if omitted,
                    try environment variable 'GITHUB_USER_TOKEN' first and
                    then use default one
  -h                show this help text and exit

Samples:
  "${sh_name}" -u john -m "Fix a critical bug" myorg/test1 15 cd/release/cf
END
)


##################### GET COMMAND OPTIONS - START ####################

OPTIND=1
while getopts ":u:m:r:b:t:h" opt; do
    case $opt in
        # Request user and message
        u)
            req_user="$OPTARG"
            ;;
        m)
            req_msg="$OPTARG"
            ;;
        r)
            status_check_url="$OPTARG"
            ;;
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
pr_id="$2"
shift 2

if [ -z "${repo_full_name}" ]; then echo "The organization and repository name is not specified." && echo "${sh_usage}"; exit 1; fi
if [ -z "${pr_id}" ]; then echo "The pull request ID is not specified." && echo "${sh_usage}"; exit 2; fi
if [ -z "${req_user}" ]; then echo "The request user is not specified." && echo "${sh_usage}"; exit 3; fi
if [ -z "${req_msg}" ]; then echo "The request message is not specified." && echo "${sh_usage}"; exit 4; fi

if [ -z "${base_api_url}" ]; then base_api_url="https://github.houston.softwaregrp.net/api/v3"; fi
if [ -z "${github_token}" ]; then github_token="${GITHUB_USER_TOKEN}"; fi
if [ -z "${github_token}" ]; then github_token="0211f662b4b1f6b26aceaa5c1501c4bc67938c41"; fi

# test jq tool and download if not available
export PATH=$PATH:${script_dir}
set +e
which jq >/dev/null 2>&1
ret=$?
set -e
if [ $ret -ne 0 ]; then
    echo -n "Downloading jq tool ... "
    if [ "$OSTYPE" = "msys" -o "$OSTYPE" = "cygwin" ]; then
        curl -sSL "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-win64.exe" -o ./jq
    else
        curl -sSL "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" -o ./jq || \
            wget -q -O ./jq "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64"
        chmod +x ./jq
    fi
    echo "Done"
fi

# get pull request head commit sha
# https://developer.github.com/v3/pulls/#get-a-single-pull-request
req_method="GET"
api_endpoint="/repos/${repo_full_name}/pulls/${pr_id}"
full_api_url="${base_api_url}${api_endpoint}"

json=$(curl --silent \
    --request "${req_method}" \
    --header "Authorization: Bearer ${github_token}" \
    "${full_api_url}"
)
if [ -z "$json" ]; then echo "Failed to send Github API request to get pull request."; exit 9; fi
sha=$(echo "$json" | ./jq -r '.head.sha')
echo "Commit sha: $sha"


# apply status check
# https://developer.github.com/v3/repos/statuses/#create-a-status
req_method="POST"
api_endpoint="/repos/${repo_full_name}/statuses/${sha}"
full_api_url="${base_api_url}${api_endpoint}"

while true; do
    status_check="$1"
    if [ -z "${status_check}" ]; then break; fi
    shift

    data='{"state":"success"'
    data="${data},\"context\":\"${status_check}\""
    data="${data},\"description\":\"Required by '${req_user}': ${req_msg}\""
    if [ -n "${status_check_url}" ]; then
        data="${data},\"target_url\":\"${status_check_url}\""
    fi
    data="$data}"

    echo -n "${repo_full_name}, PR #${pr_id}, ${status_check} ... "
    http_code=$(curl --silent --output /dev/null --write-out %{http_code} \
        --request "${req_method}" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer ${github_token}" \
        --data "${data}" \
        "${full_api_url}"
    )
    if [ "${http_code}" = "201" ]; then
        echo "Done"
    else
        echo "Failed"
        echo "Failed to send Github API request to set status check '${status_check}' for pull request '${pr_id}' in repository '${repo_full_name}'. HTTP CODE: ${http_code}"
        exit 9
    fi
done

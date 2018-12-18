#!/bin/bash

script_dir=$(dirname $(readlink -f $0))
sh_name=$0

sh_desc="Apply status on the head commit of pull request"
sh_usage=$(cat <<-END

Usage: "${sh_name}" [options] org/repo pr-id

positional parameter
  org/repo          organization name and repository name, separated by "/"
  pr-id             pull request ID on which the status will be applied

options
  -c CONTEXT        context of status to apply, defaults to 'default'

  -p                set state to 'pending', this is the default value
  -s                set state to 'success', higher priority than '-p'
  -f                set state to 'failure', higher priority than '-s'
  -e                set state to 'error', higher priority than '-f'

  -d DESCRIPTION    short (one-line) description of the status
  -u URL            target URL to associate with the status

  -b BASE_API_URL=https://github.houston.softwaregrp.net/api/v3
                    base URL of Github API to apply PR status
  -t GITHUB_TOKEN   token to be used to send Github API request, if omitted,
                    try environment variable 'GITHUB_USER_TOKEN' first and
                    then use default one
  -h                show this help text and exit

Samples:
  "${sh_name}" -sc ci/jenkins -d "CI #12" -u "http://url.com" myorg/test1 15
END
)


##################### GET COMMAND OPTIONS - START ####################

OPTIND=1
while getopts ":c:psfed:u:b:t:h" opt; do
    case $opt in
        # Status
        c)
            context="$OPTARG"
            ;;
        p)
            state="pending"
            ;;
        s)
            state="success"
            ;;
        f)
            state="failure"
            ;;
        e)
            state="error"
            ;;
        d)
            description="$OPTARG"
            ;;
        u)
            url="$OPTARG"
            ;;

        # API
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

if [ -z "${repo_full_name}" ]; then echo "The organization and repository name is not specified." && echo "${sh_usage}"; exit 1; fi
if [ -z "${pr_id}" ]; then echo "The pull request ID is not specified." && echo "${sh_usage}"; exit 2; fi

if [ -z "${context}" ]; then context="default"; fi
if [ -z "${state}" ]; then state="pending"; fi

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
	export PATH=$(pwd);$PATH
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
sha=$(echo "$json" | jq -r '.head.sha')


# apply status
# https://developer.github.com/v3/repos/statuses/#create-a-status
req_method="POST"
api_endpoint="/repos/${repo_full_name}/statuses/${sha}"
full_api_url="${base_api_url}${api_endpoint}"

data="{\"state\":\"${state}\""
data="${data},\"context\":\"${context}\""
if [ -n "${description}" ]; then
    data="${data},\"description\":\"${description}\""
fi
if [ -n "${url}" ]; then
    data="${data},\"target_url\":\"${url}\""
fi
data="$data}"

http_code=$(curl --silent --output /dev/null --write-out %{http_code} \
    --request "${req_method}" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer ${github_token}" \
    --data "${data}" \
    "${full_api_url}"
)
if [ "${http_code}" != "201" ]; then
    echo "Failed to send Github API request to apply status '${context}' on head commit '${sha}' of pull request '${pr_id}' in repository '${repo_full_name}'. HTTP CODE: ${http_code}"
    exit 9
fi

echo "Status '${context}' is applied on PR #${pr_id} (${repo_full_name}) successfully!"

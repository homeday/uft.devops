#!/bin/bash

script_dir=$(dirname $(readlink -f $0))
sh_name=$0

sh_desc="Apply a force Github pull request review."
sh_usage=$(cat <<-END

Usage: "${sh_name}" [options] org/repo pr-id

positional parameter
  org/repo          organization name and repository name, separated by "/"
  pr-id             pull request ID on which apply the force review

options
  -u USER           who request force PR review
  -m MESSAGE        message to request force PR review
  -b BASE_API_URL=https://github.houston.softwaregrp.net/api/v3
                    base URL of Github API to apply PR review
  -t GITHUB_TOKEN   token to be used to send Github API request, if omitted,
                    try environment variable 'GITHUB_USER_TOKEN' first and
                    then use default one
  -h                show this help text and exit

Samples:
  "${sh_name}" -u john -m "Fix a critical bug" myorg/test1 15
END
)


##################### GET COMMAND OPTIONS - START ####################

OPTIND=1
while getopts ":u:m:b:t:h" opt; do
    case $opt in
        # Request user and message
        u)
            req_user="$OPTARG"
            ;;
        m)
            req_msg="$OPTARG"
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

if [ -z "${repo_full_name}" ]; then echo "The organization and repository name is not specified." && echo "${sh_usage}"; exit 1; fi
if [ -z "${pr_id}" ]; then echo "The pull request ID is not specified." && echo "${sh_usage}"; exit 2; fi
if [ -z "${req_user}" ]; then echo "The request user is not specified." && echo "${sh_usage}"; exit 3; fi
if [ -z "${req_msg}" ]; then echo "The request message is not specified." && echo "${sh_usage}"; exit 4; fi

if [ -z "${base_api_url}" ]; then base_api_url="https://github.houston.softwaregrp.net/api/v3"; fi
if [ -z "${github_token}" ]; then github_token="${GITHUB_USER_TOKEN}"; fi
if [ -z "${github_token}" ]; then github_token="0211f662b4b1f6b26aceaa5c1501c4bc67938c41"; fi

# https://developer.github.com/v3/pulls/reviews/#create-a-pull-request-review
req_method="POST"
api_endpoint="/repos/${repo_full_name}/pulls/${pr_id}/reviews"
full_api_url="${base_api_url}${api_endpoint}"

http_code=$(curl --silent --output /dev/null --write-out %{http_code} \
    --request "${req_method}" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer ${github_token}" \
    --data "{\"event\":\"APPROVE\",\"body\":\"This forced review is requested by:\n${req_user}\n\nMessage from requester:\n${req_msg}\"}" \
    "${full_api_url}"
)
if [ "${http_code}" != "200" ]; then
    echo "Failed to send Github API request to apply pull request review. HTTP CODE: ${http_code}"
    exit 9
fi

echo "A forced pull request review is posted successfully for pull request #${pr_id} in repository '${repo_full_name}'."

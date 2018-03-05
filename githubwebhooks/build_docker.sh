#!/bin/bash

script_dir=$(dirname $(readlink -f $0))
sh_name=$0

sh_usage=$(cat <<-END
Build docker image

Usage: "${sh_name}" [options]

options
  -n IMAGE_NAME=github-pywebhooks       docker image name
  -t IMAGE_TAG=latest                   docker image tag, default is "latest"
  -p HTTP_PROXY=$HTTP_PROXY             http proxy passing to docker daemon
  -s HTTPS_PROXY=$HTTPS_PROXY           https proxy passing to docker daemon
  -f FTP_PROXY=$FTP_PROXY               ftp proxy passing to docker daemon
  -o NO_PROXY=$NO_PROXY                 by-pass proxy passing to docker daemon
  -h                                    show this help text and exit
END
)


##################### GET COMMAND OPTIONS - START ####################

OPTIND=1
while getopts ":n:t:p:s:f:o:h" opt; do
    case $opt in
        # Configurations options
        n)
            image_name="$OPTARG"
            ;;
        t)
            image_tag="$OPTARG"
            ;;
        p)
            var_http_proxy="$OPTARG"
            ;;
        s)
            var_https_proxy="$OPTARG"
            ;;
        f)
            var_ftp_proxy="$OPTARG"
            ;;
        o)
            var_no_proxy="$OPTARG"
            ;;

        # Help
        h)
            echo "${sh_usage}"
            exit 0
            ;;

        # error / exception
        [?])
            echo "Invalid option: -$OPTARG. Add option '-h' to get help." >&2
            exit 1
            ;;
        :)
            echo "Option '-$OPTARG' requires an argument." >&2
            exit 2
            ;;
    esac
done
shift $((OPTIND-1))

##################### GET COMMAND OPTIONS - END ####################


if [ -z "${image_name}" ]; then image_name="github-pywebhooks"; fi
if [ -z "${image_tag}" ]; then image_tag="latest"; fi

if [ -n "${var_http_proxy}" ]; then
    build_arg_http_proxy="$var_http_proxy"
    build_arg_HTTP_PROXY="$var_http_proxy"
else
    build_arg_http_proxy="$http_proxy"
    build_arg_HTTP_PROXY="$HTTP_PROXY"
fi

if [ -n "${var_https_proxy}" ]; then
    build_arg_https_proxy="$var_https_proxy"
    build_arg_HTTPS_PROXY="$var_https_proxy"
else
    build_arg_https_proxy="$https_proxy"
    build_arg_HTTPS_PROXY="$HTTPS_PROXY"
fi

if [ -n "${var_ftp_proxy}" ]; then
    build_arg_ftp_proxy="$var_ftp_proxy"
    build_arg_FTP_PROXY="$var_ftp_proxy"
else
    build_arg_ftp_proxy="$ftp_proxy"
    build_arg_FTP_PROXY="$FTP_PROXY"
fi

if [ -n "${var_no_proxy}" ]; then
    build_arg_no_proxy="$var_no_proxy"
    build_arg_NO_PROXY="$var_no_proxy"
else
    build_arg_no_proxy="$no_proxy"
    build_arg_NO_PROXY="$NO_PROXY"
fi

pushd "${script_dir}/docker" >/dev/null

docker build \
    --build-arg http_proxy="${build_arg_http_proxy}" \
    --build-arg https_proxy="${build_arg_https_proxy}" \
    --build-arg ftp_proxy="${build_arg_ftp_proxy}" \
    --build-arg no_proxy="${build_arg_no_proxy}" \
    --build-arg HTTP_PROXY="${build_arg_HTTP_PROXY}" \
    --build-arg HTTPS_PROXY="${build_arg_HTTPS_PROXY}" \
    --build-arg FTP_PROXY="${build_arg_FTP_PROXY}" \
    --build-arg NO_PROXY="${build_arg_NO_PROXY}" \
    -t "${image_name}:${image_tag}" .

popd >/dev/null

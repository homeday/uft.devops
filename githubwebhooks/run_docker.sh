#!/bin/bash

# command line:
# run_docker.sh [PORT] [DOCKER_IMAGE]
# supported environment variables
# - WEBHOOKS_REPO_RAW_FILE_URL (defaults to "https://raw.github.houston.softwaregrp.net/uft/uft.devops")
# - WEBHOOKS_REPO_BRANCH (defaults to "master")

script_dir=$(dirname $(readlink -f $0))
sh_name=$0

host_port="$1"
docker_image="$2"

if [ -z "${host_port}" ]; then host_port="${WEBHOOKS_HOST_PORT}"; fi
if [ -z "${host_port}" ]; then host_port="5000"; fi

if [ -z "${docker_image}" ]; then docker_image="${WEBHOOKS_DOCKER_IMAGE}"; fi
if [ -z "${docker_image}" ]; then docker_image="github-pywebhooks"; fi

# set executable for hook scripts
chmod -R +x "${script_dir}/hooks/"

docker run -d \
    --restart always \
    -e WEBHOOKS_REPO_RAW_FILE_URL \
    -e WEBHOOKS_REPO_BRANCH \
    -v ${script_dir}/hooks:/src/hooks:ro \
    -p ${host_port}:5000 "${docker_image}"
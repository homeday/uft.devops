#!/bin/bash

# #command line:
# run_docker.sh [NAME]
# - [NAME]: Optional. If specified, used as the container's name.
#
# #environment variables for launching docker container
# - WEBHOOKS_DOCKER_IMAGE: Used as the docker image name to launch container. Defaults to "github-pywebhooks".
# - WEBHOOKS_DOCKER_PUB_HOST_PORT: The host port to be published for the container. Defaults to 5000. 
#                                  Set 0 to disable publishing the host port.
# - WEBHOOKS_DOCKER_NETWORK: The docker network in which the container resides. Defaults to "bridge".
# - WEBHOOKS_LOG_FILE: defaults to "/logs/webhooks.log"
# - WEBHOOK_VERBOSE: defaults to "false"
#
# #environment variables used inside the docker container
# - WEBHOOKS_REPO_RAW_FILE_URL (defaults to "https://raw.github.houston.softwaregrp.net/uft/uft.devops")
# - WEBHOOKS_REPO_BRANCH (defaults to "master")

script_dir=$(dirname $(readlink -f $0))
sh_name=$0

# attempt to execute env file
env_file="${script_dir}/run_docker.env"
if [ -f "${env_file}" ]; then
    set -o allexport
    source "${env_file}"
    set +o allexport
fi

contianer_name="$1"
host_port="${WEBHOOKS_DOCKER_PUB_HOST_PORT}"
docker_image="${WEBHOOKS_DOCKER_IMAGE}"
network="${WEBHOOKS_DOCKER_NETWORK}"

if [ -z "${host_port}" ]; then host_port="5000"; fi
if [ -z "${docker_image}" ]; then docker_image="github-pywebhooks"; fi

# set executable for hook scripts
chmod -R +x "${script_dir}/hooks/"

# refine docker run flag: -p
docker_pub_port_flag=" -p ${host_port}:5000 "
if [ "${host_port}" = "0" ]; then docker_pub_port_flag=" "; fi

# refine docker run flag: --name
docker_name_flag=" "
if [ ! -z "${contianer_name}" ]; then docker_name_flag=" --name ${contianer_name} "; fi

# refine docker network flag: --network
docker_network_flag=" "
if [ ! -z "${network}" ]; then docker_network_flag=" --network ${network} "; fi

docker run -d \
    --restart always \
    -e WEBHOOKS_REPO_RAW_FILE_URL \
    -e WEBHOOKS_REPO_BRANCH \
    -e WEBHOOKS_LOG_FILE \
    -e WEBHOOK_VERBOSE \
    -v "${script_dir}/hooks:/src/hooks:ro" \
    -v "${script_dir}/logs:/logs" \
    ${docker_pub_port_flag} ${docker_name_flag} ${docker_network_flag} "${docker_image}"

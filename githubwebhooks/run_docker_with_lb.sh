#!/bin/bash

##############################################################
# Run multiple web hooks docker containers with load balance.
##############################################################
# #command line:
# run_docker_with_lb.sh <BASE_NAME> [BACKEND_NUM=3]
# - <BASE_NAME>: Required. The base name of the load balance container and web hooks backend container.
# - [BACKEND_NUM]: Optional. Defaults to 3. How many backend web hooks containers need to be created. Set to 0 to use default.
#
# #environment variables for launching docker container(s)
# - WEBHOOKS_DOCKER_IMAGE_LOADBALANCE: Used as the docker image name to launch load balance container. Defaults to "nginx".
# - WEBHOOKS_DOCKER_IMAGE_BACKEND: Used as the docker image name to launch web hooks container(s). Defaults to "github-pywebhooks".
# - WEBHOOKS_DOCKER_PUB_HOST_PORT: The host port to be published for the load balance container. Defaults to 80. 
#                                  Set 0 to disable publishing the host port.
# - WEBHOOKS_DOCKER_NETWORK: The docker network in which the load balance and web hooks containers reside.
#                            Defaults to "<BASE_NAME>_network". When specified, this script will check whether the given docker network
#                            exists; if not exist, a new docker network will be created with the given name.
# - WEBHOOK_VERBOSE: Enable the verbose for the web hooks backend container(s). Defaults to "false".
#
# #environment variables used inside the web hooks container(s)
# - WEBHOOKS_REPO_RAW_FILE_URL (defaults to "https://raw.github.houston.softwaregrp.net/uft/uft.devops")
# - WEBHOOKS_REPO_BRANCH (defaults to "master")

script_dir=$(dirname $(readlink -f $0))
sh_name=$0

# attempt to execute env file
env_file="${script_dir}/run_docker_with_lb.env"
if [ -f "${env_file}" ]; then
    set -o allexport
    source "${env_file}"
    set +o allexport
fi

base_name=$1
backend_number=$2
lb_docker_img="${WEBHOOKS_DOCKER_IMAGE_LOADBALANCE}"
be_docker_img="${WEBHOOKS_DOCKER_IMAGE_BACKEND}"
pub_host_port="${WEBHOOKS_DOCKER_PUB_HOST_PORT}"
docker_network="${WEBHOOKS_DOCKER_NETWORK}"

if [ -z "${base_name}" ]; then
    echo "Error: The base name must be not empty"
    echo "Usage: run_docker_with_lb.sh <BASE_NAME> [BACKEND_NUM=3]"
    exit 1
fi

# set default value if necessary
let be_num=3
if [ ! -z "${backend_number}" ]; then
    let n=${backend_number}
    if [ $n -gt 0 ]; then let be_num=$n; fi
fi

if [ -z "${lb_docker_img}" ]; then lb_docker_img="nginx"; fi
if [ -z "${be_docker_img}" ]; then be_docker_img="github-pywebhooks"; fi

let port=80
if [ ! -z "${pub_host_port}" ]; then
    # a special case, if the value is explicitly set to "0", means no need to publish port
    if [ "${pub_host_port}" = "0" ]; then
        let port=0
    else
        let p=${pub_host_port}
        if [ $p -gt 0 ]; then let port=$p; fi
    fi
fi

network="${base_name}_network"
if [ ! -z "${docker_network}" ]; then network="${docker_network}"; fi


# set executable for hook scripts used by web hooks backend container(s)
chmod -R +x "${script_dir}/hooks/"


####
#### create docker network if necessary
####
docker_ns=$(docker network ls -q --filter "name=${network}")
if [ -z "${docker_ns}" ]; then
    echo -n "Info: Creating docker network '${network}' ... "
    docker network create "${network}"
fi
# check network again
docker_ns=$(docker network ls -q --filter "name=${network}")
if [ -z "${docker_ns}" ]; then
    echo "Error: Failed to create docker network: ${network}"
    exit 2
fi
echo "Info: Using docker network: ${network}"


####
#### launch backend container(s) ####
####
for ((i=1;i<=be_num;i++)); do
    name="${base_name}_backend_$i"
    echo -n "Info: Launching backend container '${name}' ... "
    docker run -d \
        --restart always \
        --network "${network}" \
        -e WEBHOOKS_REPO_RAW_FILE_URL \
        -e WEBHOOKS_REPO_BRANCH \
        -e WEBHOOKS_LOG_FILE="/logs/${name}.log" \
        -e WEBHOOK_VERBOSE \
        -v "${script_dir}/hooks:/src/hooks:ro" \
        -v "${script_dir}/logs/webhooks:/logs" \
        --name "${name}" "${be_docker_img}"
done


####
#### launch load balance container ####
####
lb_name="${base_name}_lb"
nginx_svr_port=8001

# construct docker run flag for load balance container: -p
docker_pub_port_flag=" -p ${port}:${nginx_svr_port} "
if [ $port -eq 0 ]; then
    echo "Info: Skipped publishing host port"
    docker_pub_port_flag=""
fi

# generate nginx conf file
nginx_conf_file="${script_dir}/nginx/${lb_name}.conf"
nginx_conf_dir=$(dirname "${nginx_conf_file}")
if [ ! -d "${nginx_conf_dir}" ]; then mkdir -p "${nginx_conf_dir}"; fi

cat << EOF > "${nginx_conf_file}"
upstream ${lb_name}_backends {
$(
    for ((i=1;i<=be_num;i++)); do
        echo "    server ${base_name}_backend_$i:5000;"
    done
)
}

server {
    listen       ${nginx_svr_port};
    listen  [::]:${nginx_svr_port};

    access_log  /var/log/nginx/${lb_name}.log  main;

    location / {
        proxy_pass         http://${lb_name}_backends;
    }
}
EOF
echo "Info: The nginx conf file is generated: ${nginx_conf_file}"

echo -n "Info: Launching load balance container '${lb_name}' ... "
docker run -d \
    --restart always \
    --network "${network}" \
    -v "${script_dir}/nginx:/etc/nginx/conf.d:ro" \
    -v "${script_dir}/logs/loadbalance:/var/log/nginx" \
    ${docker_pub_port_flag} --name "${lb_name}" "${lb_docker_img}"

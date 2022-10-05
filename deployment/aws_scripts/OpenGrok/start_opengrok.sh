#!/bin/bash

##################################################################
# prior to running this script, docker engine must be installed
# run "centos.sh" to install docker engine
##################################################################

this_dir="$(dirname "$(test -L "$0" && readlink "$0" || echo "$0")")"
this_full_dir=$(realpath "${this_dir}")

# create necessary folders for OpenGrok deployment
echo "Copy files to OpenGrok deployment (all branches mode) ..."
ogk_dir=/opengrok
ogk_src_dir="${ogk_dir}/src"
ogk_etc_dir="${ogk_dir}/etc"
ogk_data_dir="${ogk_dir}/data"
scripts_dir="${ogk_dir}/scripts"
if [ ! -d "${ogk_src_dir}" ]; then sudo mkdir -p "${ogk_src_dir}"; fi
if [ ! -d "${ogk_etc_dir}" ]; then sudo mkdir -p "${ogk_etc_dir}"; fi
if [ ! -d "${ogk_data_dir}" ]; then sudo mkdir -p "${ogk_data_dir}"; fi
if [ ! -d "${scripts_dir}" ]; then sudo mkdir -p "${scripts_dir}"; fi

# copy the necessary files to OpenGrok deployment folder
sudo cp "${this_full_dir}/data/footer_include" "${ogk_data_dir}/"
sudo cp "${this_full_dir}/data/header_include" "${ogk_data_dir}/"
sudo cp "${this_full_dir}/data/http_header_include" "${ogk_data_dir}/"
sudo cp "${this_full_dir}/etc/readonly_configuration.xml" "${ogk_etc_dir}/"
sudo cp -r "${this_full_dir}/scripts/." "${scripts_dir}"
sudo find "${scripts_dir}" -name "*.sh" -exec sudo chmod +x {} \;
echo "Files are copied to OpenGrok deployment (all branches mode)"

# create necessary folders for OpenGrok deployment (master branch only)
echo "Copy files to OpenGrok deployment (master branch only mode) ..."
ogk_master_dir=/opengrok-master
ogk_master_src_dir="${ogk_master_dir}/src"
ogk_master_etc_dir="${ogk_master_dir}/etc"
ogk_master_data_dir="${ogk_master_dir}/data"
ogk_master_scripts_dir="${ogk_master_dir}/scripts"
if [ ! -d "${ogk_master_src_dir}" ]; then sudo mkdir -p "${ogk_master_src_dir}"; fi
if [ ! -d "${ogk_master_etc_dir}" ]; then sudo mkdir -p "${ogk_master_etc_dir}"; fi
if [ ! -d "${ogk_master_data_dir}" ]; then sudo mkdir -p "${ogk_master_data_dir}"; fi
if [ ! -d "${ogk_master_scripts_dir}" ]; then sudo mkdir -p "${ogk_master_scripts_dir}"; fi

# copy the necessary files to OpenGrok deployment (master branch only) folder
sudo cp "${this_full_dir}/data/footer_include" "${ogk_master_data_dir}/"
sudo cp "${this_full_dir}/data/header_include-masteronly" "${ogk_master_data_dir}/header_include"
sudo cp "${this_full_dir}/data/http_header_include" "${ogk_master_data_dir}/"
sudo cp "${this_full_dir}/etc/readonly_configuration-masteronly.xml" "${ogk_master_etc_dir}/readonly_configuration.xml"
sudo cp -r "${this_full_dir}/scripts/." "${ogk_master_scripts_dir}"
sudo find "${ogk_master_scripts_dir}" -name "*.sh" -exec sudo chmod +x {} \;
echo "Files are copied to OpenGrok deployment (master branch only mode)"


# Launch a container using docker
echo "Starting docker containers ..."
sudo docker compose up -d

echo "Docker containers are up"
echo "Please visit the OpenGrok page (no source are indexed yet)"
echo ""
echo "Congratulations! OpenGrok is running!"
echo ""
echo "Please following the instructions below to sync and index source code:"
echo ""
echo ""
echo "# FIRST-TIME SYNC AND INDEX #"
echo "If OpenGrok page is accessible, then please run the sync-index.sh in OpenGrok folder (in host system) for first-time sync and index"
echo 'Wait until you see the line: "sync-index: [INFO] Finished at: (date)" and index completed in container (see logs in container)'
echo ""
echo "You can run the following commands to do first-time sync and index in host system (replace <GIT-USER> and <GIT-TOKEN> with real values):"
echo 'nohup /opengrok/scripts/sync-index.sh "<GIT-USER>" "<GIT-TOKEN>" "/opengrok/src" "uft/uft.devops/master/repolist/opengrok_sync.txt" opengrok_all > /opengrok/sync.log 2>&1 &'
echo 'nohup /opengrok-master/scripts/sync-index.sh "<GIT-USER>" "<GIT-TOKEN>" "/opengrok-master/src" "uft/uft.devops/master/repolist/opengrok_sync_master.txt" opengrok_master > /opengrok-master/sync.log 2>&1 &'
echo ""
echo ""
echo "# CRON JOB #"
echo "After the first-time sync and index completed, then please add the cron jobs to the host system"
echo "Do NOT add cron job too early - it may run the sync-index.sh when the first-time sync and index is still running"
echo ""
echo "You can use the following command to add cron job (replace <GIT-USER> and <GIT-TOKEN> with real values):"
echo '(crontab -l ; /bin/bash /opengrok/scripts/sync-index.sh "<GIT-USER>" "<GIT-TOKEN>" "/opengrok/src" "uft/uft.devops/master/repolist/opengrok_sync.txt" opengrok_all > /opengrok/sync.log 2>&1) | crontab -'
echo '(crontab -l ; /bin/bash /opengrok-master/scripts/sync-index.sh "<GIT-USER>" "<GIT-TOKEN>" "/opengrok-master/src" "uft/uft.devops/master/repolist/opengrok_sync_master.txt" opengrok_master > /opengrok-master/sync.log 2>&1) | crontab -'

#!/bin/bash

# trigger indexing upon OpenGrok docker container
# usage: index-src.sh <docker-container-name-or-id> [port=5000] [debug]

# const
VERSION=1.0

# error codes
ERRCODE_GENERAL=1
ERRCODE_WRONGARG=2
ERRCODE_SKIPINDEX=3

# binary settings
docker_bin=docker
curl_bin=curl

# other settings
restart_threshold_hours=48

# arguments
this_file="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
this_dir="$(dirname "$(test -L "$0" && readlink "$0" || echo "$0")")"
container_name_or_id="$1"
port="$2"
debug="$3"

# state keys
state_key_index_trigger_time=index_trigger_time


# function: log text
#   log <text>
log () {
    echo "$(date +"%Y-%m-%d %H:%M:%S %Z") <index-src> [INFO] $1"
}

# function: log debug text
#   log_debug <text>
log_debug () {
    if [ ! -z "$debug" ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S %Z") <index-src> [DEBUG] $1"
    fi
}

# function: log error text with error code
#   log_err <code> <text>
log_err () {
    code=$1
    echo "$(date +"%Y-%m-%d %H:%M:%S %Z") <index-src> [ERROR ${code}] $2" 1>&2
}

# function: log warning text
#   log_warn <text>
log_warn () {
    echo "$(date +"%Y-%m-%d %H:%M:%S %Z") <index-src> [WARN] $1"
}

# function: return the full id of the given container name or id
fetch_container_full_id () {
    sudo "${docker_bin}" inspect --format="{{.Id}}" "${container_name_or_id}"
}

# function: converts the given EPOCH (seconds) to human readable time format
#   conv_disp_time <EPOCH-SECONDS>
#   return: human readable time format like 2022-10-03T15:32:17+0000
conv_disp_time () {
    time_sec="$1"
    date -d "1970-01-01 UTC ${time_sec} seconds" +"%Y-%m-%dT%H:%M:%S%:z"
}


######################
#### main process ####
######################

echo "==================================================="
echo "OpenGrok Indexing Trigger v${VERSION}"
echo "- Trigger indexing upon OpenGrok docker container -"
echo "==================================================="
echo ""
log "Index trigger started"

if [ -z "${container_name_or_id}" ]; then
    log_err ${ERRCODE_WRONGARG} "Incorrect argument(s)"
    echo "Usage: ${this_file} <docker-container-name-or-id> [port=5000] [debug]"
    exit ${ERRCODE_WRONGARG}
fi

if [ -z "$port" ]; then port=5000; fi

# generate trigger time
this_trigger_time=$(date +%s)
log "Starting to trigger a new OpenGrok index (t=${this_trigger_time}) in container: ${container_name_or_id} ..."

# get full id of container
full_id=$(fetch_container_full_id)
log_debug "Container '${container_name_or_id}' full id: ${full_id}"

# check if the state file (saved by this script) exists
# if so, fetch last index trigger time by this script
state_file=$(realpath "${this_dir}/${full_id}.ctstat")
last_index_trigger_time=
if [ -f "${state_file}" ]; then
    while IFS= read -r line; do
        # each line is key value pair with "=" as separator
        key=$(echo "$line" | cut -d'=' -f1)
        value=$(echo "$line" | cut -d'=' -f2-)
        if [ "$key" == "${state_key_index_trigger_time}" ]; then # index_trigger_time=1664905311
            last_index_trigger_time=value
            disp_time=$(conv_disp_time "$value")
            log_debug "Last index trigger time (by ${this_file}) for container '${container_name_or_id}': ${disp_time}"
        fi
    done < "${state_file}"
fi

# get last completed index time from OpenGrok container
log_debug "Fetching last completed OpenGrok index time upon container: ${container_name_or_id}"
time=$(sudo "${docker_bin}" exec "${container_name_or_id}" curl -sSL "http://localhost:8080/api/v1/system/indextime" | tr -d '"')
log_debug "Last completed OpenGrok index time (from container '${container_name_or_id}'): $time"
last_opengrok_index_time=
if [ "$time" == "null" ]; then
    log_debug "OpenGrok has never run index yet"
else
    last_opengrok_index_time=$(date -d"$time" +%s)
fi

# determine if last triggered index completed successfully
last_index_completed=false
if [ -z "${last_opengrok_index_time}" ]; then
    log_debug "OpenGrok has never run index"
    last_index_completed=true # treat as last index completed
elif [ -z "${last_index_trigger_time}" ]; then
    log_debug "OpenGrok index was never triggered by script, however, OpenGrok has ever run index before"
    last_index_completed=true
else
    let idx=last_opengrok_index_time
    let trig=last_index_trigger_time
    if [ "$idx" -ge "$trig" ]; then
        log_debug "Last completed OpenGrok index time is later than or equals to the time trigger the indexing"
        last_index_completed=true
    else
        log_debug "Last completed OpenGrok index time is earlier than the last trigger time, means the indexing might not be completed yet"
        last_index_completed=false
    fi
fi

if [ "${last_index_completed}" == "false" ]; then
    # if index was triggered but not completed, check the elapsed time since it was triggered
    # and if longer than restart-threshold, then need to restart the container
    let trig=last_index_trigger_time
    let now=$(date +%s)
    let diff=now-trig   # in seconds
    let diff_hours=diff/3600    # in hours
    log_debug "${diff_hours} hours elapsed since the last triggered indexing"
    if [ ${diff_hours} -gt ${restart_threshold_hours} ]; then
        # indexing run longer than restart-threshold, restart container
        log_warn "The last index was triggered ${diff_hours} hours ago and not finished yet"
        log_warn "The elapsed time is longer than the restart threshold (${restart_threshold_hours} hours)"
        log_warn "The OpenGrok indexing in container '${container_name_or_id}' might stuck somehow"
        log_warn "Restarting the container: ${container_name_or_id} ..."
        sudo "${docker_bin}" restart "${container_name_or_id}"
        log_warn "Container '${container_name_or_id}' was restarted"
        log_debug "Once container is started, a new index will be automatically triggered"
    else
        # indexing is running within restart-threshold, skip this trigger
        log_warn "The OpenGrok indexing in container '${container_name_or_id}' might still be running now"
        log_warn "Skip further indexing until the current indexing was completed, or the elapsed time is longer than threshold (${restart_threshold_hours} hours)"
        log_warn "The index trigger is skipped (t=${this_trigger_time})"
        exit ${ERRCODE_SKIPINDEX}
    fi
else
    # last triggered index was completed, now can trigger a new index
    log_debug "Triggering /reindex endpoint on port ${port} upon container: ${container_name_or_id}"
    sudo "${docker_bin}" exec "${container_name_or_id}" curl -sSL "http://localhost:${port}/reindex"
    echo ""
fi

log "OpenGrok index is triggered (t=${this_trigger_time}) in container: ${container_name_or_id}"

# clear state file
cat /dev/null > "${state_file}"
log_debug "Truncated state file: ${state_file}"

# update state file
echo "${state_key_index_trigger_time}=${this_trigger_time}" >> "${state_file}"
log_debug "Line is added to state file '${state_file}': ${state_key_index_trigger_time}=${this_trigger_time}"

echo ""
log "Index trigger completed"

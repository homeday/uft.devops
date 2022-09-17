# I. Build Docker Image

### 1. Install docker engine
Follow the instructions in the [official docker installation page](https://docs.docker.com/engine/install/).

### 2. Download build assets
Navigate to the GitHub [release page](https://github.houston.softwaregrp.net/uft/uft.devops/releases) and download the docker build assets. The docker build assets may be named like `github_webhooks_docker_build_1_0.zip`.

> **Notes:**
>
> Only the following directory(s) and file(s) are required if you just want to build docker image:
> - [Directory] `docker`
> - [File] `build_docker.sh`

### 3. Build docker image
Unzip the downloaded build assets to any directory and then run the following command lines:
```bash
# export http_proxy and https_proxy if necessary
chmod +x ./build_docker.sh
./build_docker.sh
```

# II. Run Docker Container

### 1. Download run assets
Navigate to the GitHub [release page](https://github.houston.softwaregrp.net/uft/uft.devops/releases) and download the docker run assets. The docker run assets may be named like `github_webhooks_docker_run_1_0.zip`.

> **Notes:**
>
> Only the following directory(s) and file(s) are required if you just want to run docker container with an existing web hook docker image:
> - [Directory] `hooks`
> - [File] `run_docker.env`
> - [File] `run_docker.sh`

### 2. Run web hook docker container
```bash
chmod +x ./run_docker.sh
./run_docker.sh
```

The [run_docker.sh](run_docker.sh) CLI:
```
run_docker.sh [NAME]
```
By default, the docker container will be named with a random string, however, you can define the container name by specifying the `NAME` argument when executing the `run_docker.sh` script.

You can also configure the environment variables to customize the launching docker container by either modifying the `run_docker.env` file or directly export the required environment variables. Check out the following sections regarding the details of the supported environment variables.

#### Environment Variables For Launching Container
The following environment variables are allowed to customize the settings of the launching docker container:
| Environment Variable | Default Value | Description |
| ---- | ---- | ----|
| `WEBHOOKS_DOCKER_IMAGE` | `github-pywebhooks` | The docker image name with or without tag to launch the container. |
| `WEBHOOKS_DOCKER_PUB_HOST_PORT` | `5000` | The host port to be published when launching the container. Specify `0` will disable publishing the host port and the web hook service can only be accessed within the docker network. |
| `WEBHOOKS_DOCKER_NETWORK` | `bridge` | The docker network in which the container will be launched. |

These environment variables must be set before executing the `run_docker.sh` script. They only affect the container to be launched and never be passed to the web hook service running inside the container.

#### Environment Variables For Web Hook Service Running Inside Container
The following environment variables can be configured to customize the web hook service running inside the docker container:
| Environment Variable | Default Value | Description |
| ---- | ---- | ----|
| `WEBHOOKS_REPO_RAW_FILE_URL` | `https://raw.github.houston.softwaregrp.net/uft/uft.devops` | The URL of the Git repository in which webhooks requests the web hooks configuration files. |
| `WEBHOOKS_REPO_BRANCH` | `master` | The branch name of the Git repository in which webhooks requests the web hooks configuration files. |
| `WEBHOOKS_LOG_FILE` | `/logs/webhooks.log` | The file in which the web hooks service stores the logs. Note that the file path is the one in the file system inside the docker container, not the host file system. The `/logs` directory inside the container is mounted to the host directory `./logs` under the directory where `run_docker.sh` resides. |
| `WEBHOOK_VERBOSE` | `false` | Whether enables verbose output for the web hook service. Note that this environment variable starts with `WEBHOOK_` rather than `WEBHOOKS_`. |

These environment variables must be set before executing the `run_docker.sh` script. They will be passed to the web hooks service.

### 3. Test web hooks with ping
You can test the web hook service running inside the launched container by simulating GitHub `ping` event. In the bash command window, run the following command (replace the `HOSTNAME_OR_IP` with your host's hostname or IP address as well as the `PORT` with the published host port or container port if not published):
```sh
curl -X POST http://HOSTNAME_OR_IP:PORT/ \
  -H 'Content-Type: application/json' \
  -H 'X-GitHub-Event: ping' \
  -d '{}'
```

If the web hook service was running normally, the status code of the response should be `200 OK` and the response body should be `{'msg': 'pong'}`.

### 4. Hook script files
The running container always attempts to look up the hook script files in the `hooks` directory when it receives an event sent from the GitHub and invoke the script files one by one with the received payload.

The `hooks` directory is mounted in read-only privilege while launching the docker container. You can add, modify and remove any script files in the `hooks` directory and the container will adopt the new changes from next received event.

The hook script file must be written in **Python** and accepts the following arguments that passed by the container.
```
<SCRIPT_FILE> PAYLOAD_FILE EVENT_NAME
```

The first argument that the hook script file can read is `PAYLOAD_FILE` which is the file path of the payload JSON data sent by the GitHub. You can use the following code snippet to load this payload file and read all JSON payload data into memory.
```python
import sys
import json

with open(sys.argv[1], 'r') as jsf:
  payload = json.loads(jsf.read())
```

The second argument that the hook script file can read is `EVENT_NAME` which is the event name sent by the GitHub. This argument is used to indicate whether the script file shall process the payload or not. For example, for a hook script file that processes any `push` event, you can use the following code snippet to check if the event payload shall be loaded:
```python
import sys

# test event which must be "push"
event = sys.argv[2]
if event != "push":
  print('The event "{}" is not "push". Exit.'.format(event))
  sys.exit()
```

# III. Configure Web Hook in GitHub

### 1. Navigate to either organization hooks setting page or repository hook setting page

### 2. Add web hook
Web hook settings:
- Payload URL:
    ```
    http://[CSA-machine-name]:5000

    for example:

    http://myd-vm07392.hpeswlab.net:5000
    ```

- Content type:
    ```
    application/json
    ```

# Misc

* The setting `Trigger builds remotely (e.g., from scripts)` in Jenkins job need to be enabled and configured with a `build token` in order to trigger Jenkins job remotely from webhooks.










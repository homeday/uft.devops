# Deployment:

#### 1. Install docker engine

#### 2. Download code assets
Use `git clone` or directly download zip file.
* git clone
    ```bash
    git clone https://github.houston.softwaregrp.net/uft/uft.devops.git
    ```

* download zip file
    ```bash
    curl -L https://github.houston.softwaregrp.net/uft/uft.devops/archive/master.zip --output uft.devops.zip
    ```

#### 3. Build docker image
Go to **githubwebhooks** directory and then run the following command lines:
```bash
# export http_proxy and https_proxy if necessary
chmod +x ./build_docker.sh
./build_docker.sh
```

# Run web hook

#### 1. Go to "githubwebhooks" directory

#### 2. Run web hook docker container
```bash
chmod +x ./run_docker.sh
./run_docker.sh
```

The [run_docker.sh](run_docker.sh) CLI:
```
run_docker.sh [PORT=5000] [DOCKER_IMAGE=github-pywebhooks]
```

Supported environment variables:
- `WEBHOOKS_HOST_PORT`: host port to be published for docker container, if the port is also specified in command line, this environment variable has no effect.
- `WEBHOOKS_DOCKER_IMAGE`: docker image name with/without tag to launch docker container, if the docker image is also specified in command line, this environment variable has no effect.
- `WEBHOOKS_REPO_RAW_FILE_URL`: the URL of the git repository in which webhooks requests configuration files. Defaults to `https://raw.github.houston.softwaregrp.net/uft/uft.devops`.
- `WEBHOOKS_REPO_BRANCH`: the branch name of the git repository in which webhooks requests configuration files. Defaults to `master`.

# Create web hook at organization page

#### 1. Navigate to either organization hooks setting page or repository hook setting page

#### 2. Add web hook

#### 3. Settings

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










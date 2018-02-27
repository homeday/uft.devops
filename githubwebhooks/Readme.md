# Deployment:

#### 1. Install docker engine

#### 2. Build docker image
    Copy "docker" sub folder to the CSA machine

    At CSA machine, go to the "docker" directory

    Run command 
        "docker build -t carlos-jenkins/python-github-webhooks . "


# Run web hook

#### 1. Create folder uftgithooks at directory $HOME

#### 2. Copy relevant resouce files to it
    Copy "config" and "hooks" folders to the $HOME/uftgithooks directory

#### 3. Run command
    docker run -d \
        --name webhooks \
        -v $HOME/uftgithooks/config:/src/config \
        -v $HOME/uftgithooks/out:/src/out \
        -v $HOME/uftgithooks/hooks:/src/hooks \
        -p 5000:5000 carlos-jenkins/python-github-webhooks 


# Create web hook at organization page

#### 1. Go to url https://github.houston.softwaregrp.net/organizations/uft/settings/hooks


#### 2. Add web hook

#### 3. Settings

    Payload URL:
        http://[CSA machine name]:5000/ "e.g. http://myd-vm07392.hpeswlab.net:5000/"

    Content type:
        application/json






# Opengrok Depolyment

#### 1. Install opengrok with docker
    
	docker run --restart always -d --name opengrok -v /src:/src -p 8080:8080 nagui/opengrok:latest
	

#### 2. Pull source code from Git to src folder

    change operate_opengrok_src.sh to unix format

    ```
    dos2unix operate_opengrok_src.sh
    ```

    bash operate_opengrok_src.sh [label] update [branch name]
    e.g.

    ```
	bash operate_opengrok_src.sh UFT_14_50 update master
    ```	

#### 3. Remove source code from Git to src folder
    change operate_opengrok_src.sh to unix format

    ```
    dos2unix operate_opengrok_src.sh
    ```

    bash operate_opengrok_src.sh [label] delete [branch name]
    e.g.
    
    ```
	bash operate_opengrok_src.sh UFT_14_50 delete UFT_14_03_SP_Patches


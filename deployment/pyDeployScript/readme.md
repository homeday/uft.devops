# Deploy FT product on remote machines

## Prerequisites 
1. Install Pythong 3.7.* or higher
2. Install latest pip or higher (pip was 22.0.2 at the time this doc written)
3. Powershell Version 5.1.*.* or higher (PS version was 5.1.19041.1320 at the time of this document written)
4. Winrm services should be enabled and configured in the remote machine.


## Usage
This small library helps to install UFT, UFT Patch, LFT, and Codeless on the remote machine

### Uninstall UFT

```
    SET VM_NAME = "<vmname>"
    SET LABEL = "<UFT Build Label>"

    python uninstall_uft_script.py

```

### Install UFT
```
    SET VM_NAME = "<vmname>"
    SET MODE = " uninstall | resnepshot"
    SET BUILD_VERSION = "<UFT_BUILD_NUMBER>"
    SET LABEL = "<UFT Build Label>"

    python install_uft_script.py
 
```
### Install Patch on top of UFT
```
    SET VM_NAME = "<vmname>"
    SET MODE = " uninstall | resnepshot"
    SET PATCH_BUILD_NUMBER = "<PATCH_BUILD_NUMBER>"
    SET LABEL = "<UFT Build Label>"
    SET PATCH_ID = "<Patch Id>"

    python install_uft_patch_script.py
 
```

### Install UFT with LFT as a feature

```
    Not Implemented! 
```

### Install LFT

```
    Not Implemented! 
```

### Install Codeless

```
    Not Implemented! 
```

### Install Codeless on top of UFT

```
    SET VM_NAME = "<vmname>"
    SET CDLS_BUILD_NUMBER = "<CDLS_BUILD_NUMBER>"
    SET LABEL = "<UFT Build Label>"

    python install_uft_ai_script.py
 
```


### Install codeless on top of LFT

```
    Not Implemented! 
```
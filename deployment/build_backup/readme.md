# Copy Build from On-premise to Cloud

## Prerequisites 
1. Set write permission to destination folder

```
    chmod -R -v 777 2022.0.0.700

```
2. Download and Install 7z | https://www.7-zip.org/a/7z2201-x64.exe


## Run the script
The backup_build_to_artifactory script do the following
1. Mount rubicon fileshare to P: 
2. Copy build locally
3. prapre archive
4. upload to artifactory
5. clean up local copy of the build
6. clean up archive copy

```
    py backup_build_to_artifactory.py <buildnumber>
    
    Example:
        py backup_build_to_artifactory.py 2023.0.0.700 

```
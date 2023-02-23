# # Copy Build from On-premise to Cloud

# ## Prerequisites 
# 1. Set write permission to destination folder

# ```
#     chmod -R -v 777 2022.0.0.700

# ```

# 2. Map source and destination URL

# 3. Download and Install 7z | https://www.7-zip.org/a/7z2201-x64.exe


# ## Run the script

# ```
#     py copy_files.py <buildnumber> <source> <destination>
    
#     Example:
#         py copy_files.py 2023.0.0.700 K:\FT\QTP\win32_release\ P:\FT\QTP\win32_release\

# ```


import os, sys
from src.utils import robocopy_only_missing_file

if __name__=="__main__":
       
    if len(sys.argv) < 4:
       print("\n[ Info ]: The following  parameters aren't pass in the command line \n\tBuildNumber | ',' seprator will be used for multiple build, \n\tSource | rubicon map path) and \n\tDestination | AWS Rubicon map path")
       print("\nExample:\n\t py %s 2021.0.0.1000,2021.1.0.600 F:\FT\QTP\win32_release\ K:\FT\QTP\win32_release\ " % (sys.argv[0]))
       sys.exit(-1)

  
    labels = sys.argv[1].split(',')
    
    for label in labels:
        source = os.path.join(sys.argv[2], label)
        destination = os.path.join(sys.argv[3], label)
        
        print("\n[ Source ]: %s \n[ Destination ]: %s" %(source, destination))
        robocopy_only_missing_file(source, destination)

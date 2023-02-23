import os, sys, uuid
import src.utils as utils


RUBICON_URL="\\\\rubicon.cross.admlabs.aws.swinfra.net\\NAS_NTPP"
RUBICON_PRODUCT_URL = RUBICON_URL + "\\products"
FT_PATH = "P:\\FT\\%s\\win32_release\\%s"

if __name__=="__main__":
    
    if len(sys.argv) < 3:
       print("\n[ Info ]: Required args missing. The following parameters aren't pass in the command line \n\tBuildNumber | ',' seprator will be used for multiple build, \n\tSource | rubicon map path) and \n\tDestination | AWS Rubicon map path")
       print("\nExample:\n\t py %s 2021.0.0.1000 [QTP | LeanFT | CDLS-AI]" % (sys.argv[0]))
       sys.exit(-1)



    BuildNumber = sys.argv[1]
    Repository = sys.argv[2]

    # Prepare source path
    rubicon_source = FT_PATH % (Repository, BuildNumber)
    local_source = "E:\\" + rubicon_source.split(":\\")[1]
    
    # Mount P drive (P is a default drive)
    utils.mount(RUBICON_PRODUCT_URL)

    
    
    # Copy to local
    print("\nCopy build to instance from \"%s\" to \"%s\"" %(rubicon_source, BuildNumber))
    utils.robocopy(rubicon_source, local_source)
    
    print("\nCompress from %s to %s" % (rubicon_source, BuildNumber))
    utils.compress(local_source, "%s\\%s.zip" % (BuildNumber, BuildNumber))

    # Read directory and send file to artifactory
    repo_path = "Backup/" + local_source.split(":\\")[1].replace("\\","/")
    
    for root, directories, files in os.walk(BuildNumber, topdown=False):
    
      for name in files:
    
         local_file = BuildNumber + "\\" + name
    
         print("***** Uploding '" + local_file + "'")
         utils.push_artifacts(repo_path, name, local_file)

    
    # Clean up local copy
    utils.rmdir(local_source)
    
    # Clean up Build archive
    utils.rmdir(os.path.abspath(BuildNumber))
    
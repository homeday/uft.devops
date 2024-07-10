from ArtifactoryClient import ArtifactoryClient
import os, sys


# Get source and destination from command line

args = sys.argv[1:]

if args == 0:
    print("Source and Destination arguments are missing, \n\t Example: " + sys.argv[0] + " path\\to\\your\\sourceFile path\\to\\your\\destinationFile " )
    sys.exit(-2)

if args == 1:
    print("Destination argument is missing, \n\t Example: " + sys.argv[0] + " path\\to\\your\\sourceFile path\\to\\your\\destinationFile " )
    sys.exit(-2)

source = args[0]
destinaton = args[1]

try: 
    ARTIFACTORY_URL = "https://fraartifactory.swinfra.net/artifactory"
    ARTIFACTORY_USERNAME = os.environ['ARTIFACTORY_USERNAME'].strip()
    ARTIFACTORY_PASSWORD = os.environ['ARTIFACTORY_PASSWORD'].strip()
    ARTIFACTORY_REPO = os.environ['ARTIFACTORY_REPO'].strip()

except:
    print("Environment variables are missing [ ARTIFACTORY_USERNAME, ARTIFACTORY_PASSWORD, and ARTIFACTORY_REPO]")
    sys.exit(-2)

client = ArtifactoryClient(
            ARTIFACTORY_URL, 
            ARTIFACTORY_REPO, 
            ARTIFACTORY_USERNAME, 
            ARTIFACTORY_PASSWORD
        )

client.upload_artifact(source, destinaton)





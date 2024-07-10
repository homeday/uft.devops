import requests, os, shutil, logging, subprocess
from requests.auth import HTTPBasicAuth
from retrying import retry
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ArtifactoryClient():

    _RETRY = 3
    _WAIT_BEFORE_RETRY = 2000

    def __init__(self, artifactory_url, repo_name, username, password, retry = 3, wait_before_retry=2000):
        
        self.artifactory_url = artifactory_url.rstrip('/')
        self.repo_name = repo_name
        _RETRY = retry
        _WAIT_BEFORE_RETRY = wait_before_retry

        self.auth = HTTPBasicAuth(username, password)

        # Validate authentication 
        try:
            self.__validate_auth()
            logger.info("Authentication validate successfully!")

        except requests.RequestException as e:
            logger.error("Authentication failed: %s", e)
            raise ValueError("Failed to authenticate with provide credentials.") from e

    # A private method to validate the authentication.
    def __validate_auth(self):
        
        ping_url = f"{self.artifactory_url}/api/system/ping"
        response = requests.get(ping_url, auth=self.auth)
        response.raise_for_status()  # Will raise an error for bad responses
    

    # Upload a single file to artificatory
    @retry(stop_max_attempt_number=_RETRY, wait_fixed=_WAIT_BEFORE_RETRY)
    def upload_artifact(self, source_path, destination_path):
        try:

            with open(source_path, 'rb') as file:
            
                upload_url = f"{self.artifactory_url}/{self.repo_name}/{destination_path}"

                logger.info(f"uploding '%s' to '%s' ", source_path, upload_url)
                response = requests.put(upload_url, data=file, auth=self.auth)
            
                if response.status_code == 201:
                    logger.info("Artifact %s uploaded successfully to %s", source_path, upload_url)
                else:
                    logger.warning("Unexpected status code: %d | Response: %s", response.status_code, response.text)    
            
        except requests.RequestException as e:
            logger.error("Error uploading artifact: %s", e)
            raise

    # Download a single file from artifatory
    @retry(stop_max_attempt_number=_RETRY, wait_fixed=_WAIT_BEFORE_RETRY)
    def download_artifact(self, artifact_path, download_path):
        
        try:
            download_url = f"{self.artifactory_url}/{self.repo_name}/{artifact_path}"
            logger.info(f"Downloding '%s' to '%s' ", artifact_path, download_path)
            response = requests.get(download_url, auth=self.auth, stream=True)
            
            if response.status_code == 200:
            
                with open(download_path, 'wb') as file:
                    for chunk in response.iter_content(chunk_size=8192):
                        file.write(chunk)
            
                logger.info("Artifact '%s' downloaded successfully to '%s' ", artifact_path, download_path)
            
            else:
                logger.warning("Unexpected status code: %d | Response: %s", response.status_code, response.text) 
        
        except requests.RequestException as e:
            logger.error("Error uploading artifact: %s", e)
            raise


    # Upload a folder to artifactory
    def upload_artifacts(self, source_path, destination_path):
        
        if not Path(source_path).exists():
            logger.error("'%s' path does not exist", source_path)
            return -2

        for root, _, files in os.walk(source_path):
            for file in files:
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, source_path)
                target_file_path = os.path.join(destination_path, relative_path).replace("\\", "/")

                self.upload_artifact(file_path, target_file_path)

    
    # Download a folder from artifactory
    def download_artifacts(self, folder_path, download_path):

        download_url = f"{self.artifactory_url}/api/storage/{self.repo_name}/{folder_path}/"
        logging.info("downloading artifacts from '%s' ", download_url)

        response = requests.get(download_url, auth=self.auth)
        response.raise_for_status()
        items = response.json().get('children', [])

        os.makedirs(download_path, exist_ok=True)
        
        for item in items:
        
            item_path = os.path.join(folder_path, item['uri'].lstrip('/')).replace("\\", "/")
            local_item_path = os.path.join(download_path, item['uri'].lstrip('/')).replace("\\", "/")
        
            if item['folder']:
                self.download_artifacts(item_path, local_item_path)
            else:
                self.download_artifact(item_path, local_item_path)

    def __execute_cmd(cmd):
        try:
            logging.info("Executing command using sub process")
            # return subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True)
            output = subprocess.run(cmd, capture_output=True, text=True)
            if output.stdout:
                logging.info("############ command output:#################\n %s", output.stdout)

            if output.stderr:
                logging.info("############ command output:#################\n %s", output.stderr)    
                
            return output.returncode
        
        except subprocess.CalledProcessError as ex:
            logger.info("Exception thorw when executing command: " + ex)
            return -1
            
    # Compress folder 
    #   compressionLevel: 0=copy, 1=fastest, 3=fast, 5=normal, 7=maximum, 9=ultra
    #   Example : 7z a -r "File\path\compressfilename.zip" "<source_dir>\(*)" -v<multivolume-size> -mx<compression-level>
    def compress_folder(self,
        exec_7z,
        folderToCompress,
        compressedFileName,
        compressionLevel = "0", 
        includeTopDirectory = False):

        folderToCompress = folderToCompress + "\\*"
        
        if includeTopDirectory:
            folderToCompress = ".\\" + folderToCompress + "\\*"
        
            

        cmd = "{0} a -r {1} {2} -mx{3}".format(exec_7z, compressedFileName, folderToCompress, compressionLevel)
        logger.info("Executing 7z compress command: %s", cmd)
        
        returncode = ArtifactoryClient.__execute_cmd(cmd)

        if returncode == 0:
            logger.info("compress command executed successfully!")     
        
        return returncode

    # Example: 7z x "file/path/compressfile.zip" -o"folderToUncompress"
    def uncompress_folder(self, exec_7z, compressedFileName, folderToUncompress):

        cmd = "{0} x {1} -o{2}".format(exec_7z, compressedFileName, folderToUncompress)
        
        logger.info("Executing 7z uncompress command: %s", cmd)
        returncode = ArtifactoryClient.__execute_cmd(cmd)

        if returncode == 0:
            logger.info("Uncompress command executed successfully!")     
        
        return returncode



# ***********************************************    
# **                                           **
# **                Main Process               **
# **                                           **    
# ***********************************************

if __name__ == "__main__":

    print(__name__)
    # artifactory_url = "https://fraartifactory.swinfra.net/artifactory"
    # repo_name = "adm-ufto-ft-generic-local"
    # username = os.getenv("artificatory_username", "_ft_auto")
    # password = os.getenv("artifactory_password", "W3lcome1")
    
    # client = ArtifactoryClient(artifactory_url, repo_name, username, password)
    # client.upload_artifact('./app.py', "sprinter/test/app.py")
    # client.download_artifact("sprinter/test/app.py", './test.py')
    # client.upload_artifacts("P:\\FT\\QTP\\win32_release\\2024.4.0.514", "QTP\\win32_release\\2024.4.0.514")
    # client.download_artifacts("sprinter/testA", "./testD")
    # client.compress_folder("7z", "C:\\Users\\chejaran\\Desktop\\UFT_00216", "test_with-script.zip")
    # client.uncompress_folder("7z", ".\\test_with-script.zip", ".\\output")

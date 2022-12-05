import os, sys, subprocess, json, time
from multiprocessing import Process

# Global Variable
USERNAME="_ft_auto"
PASSWORD="W3lcome1"

def RunProcess(args):
    """ Run process on the local machine and return stderr, stdout """
    subprocess.Popen(args)
       


def RunProcessSync(args):
    """ Run process on the local machine and return stderr, stdout """
    
    proc = subprocess.Popen(args, stdout = subprocess.PIPE, stderr = subprocess.PIPE, universal_newlines=True)
    (output, err) = proc.communicate()  

    # This makes the wait possible
    return_code = proc.wait()
   
    return {"return_code": return_code, "output": json.loads(output), "err": err}



def get_file_list(BuildVersion):
    # curl -u "_ft_auto:W3lcome1"  https://fraartifactory.swinfra.net/artifactory/api/storage/adm-ufto-generic-local/2023.0.0.247?list
    cmd = "curl -u {0}:{1} https://fraartifactory.swinfra.net/artifactory/api/storage/adm-ufto-generic-local/{2}?list".format(
        USERNAME, PASSWORD, BuildVersion
    )

    print("***** Running command - " + cmd)
    return RunProcessSync(["cmd", "/c", cmd])

def prepare_cmd(files, DownloadDir):
    
    download_commands = []
    
    for file in files:
        print(file["uri"])
        cmd = "C:\Windows\System32\curl.exe -u {0}:{1} https://fraartifactory.swinfra.net/artifactory/adm-ufto-generic-local/{2}{3} --create-dirs -O --output-dir {4}".format(
            USERNAME, PASSWORD, BuildVersion, file["uri"], DownloadDir
        )

        # print("***** command - " + cmd)
        download_commands.append(cmd)
    
    return download_commands

def download_files(cmd_args):
    os.system(cmd_args)
    
    # Download zip file (This feature is not supported)
    # cmd = "curl -u {0}:{1} https://fraartifactory.swinfra.net/artifactory/api/archive/download/adm-ufto-generic-local/{2}/?archiveType=zip -O {3}".format(
    #     USERNAME,
    #     PASSWORD",
    #     BuildVersion,
    #     BuildVersion + ".zip"
    # )
        
    # print("***** Running command - " + cmd)
    # # RunProcessSync(["cmd", "/c", cmd])


def isKeyExist(dic, key):
    if key in dic.keys():
        return True
    
    return False
         
    
   

# ********************** Main Program *******************************
if __name__ == "__main__":
    download_dir = ""
    l = len(sys.argv)
    if l == 1:
        print("BuildVersion argument missing, For Example: {0} 2023.0.0.347".format(sys.argv[0]))
        sys.exit(-1)

    if l == 2:
        download_dir = "C:\\Temp"

    if l == 3:
        download_dir = sys.argv[2]


    BuildVersion = sys.argv[1]
    download_dir = download_dir + "\\" + BuildVersion
    result = get_file_list(BuildVersion)

    
    if result["return_code"] != 0:
        print("Unable to get file list - " + result["err"])

    if(not isKeyExist(result["output"], "files")):
        print("No files found! Either build number not correct or not exist on Artifactory.")
        sys.exit(-1)

    if len(result["output"]["files"]) == 0:
        print("No files found! Make sure files were added in the build.")
        sys.exit(-1)

    commands = prepare_cmd(result["output"]["files"], download_dir)
    start_time = time.time()
    procs = []
    for cmd in commands:
        proc = Process(target=download_files, args=(cmd,))
        procs.append(proc)
        proc.start()

    # complete the processes
    for proc in procs:
        proc.join()
    
    end_time = time.time()
    print("********************** Download Info **********************************\n")
    print("\tStart Time : " + time.ctime(start_time))
    print("\tEnd Time   : " + time.ctime(end_time))
    print("\tDownload took {0} minutes".format(int((end_time - start_time) / 60)))
    print("\n**************************************************************")

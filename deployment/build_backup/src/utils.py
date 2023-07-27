import os, sys, subprocess, threading, shutil


    
# Get Label name from Rubicon. Currently only support one filter. filter can be a start string. for example: "UFT_2021_1"
def getLabelNames(root, filter): 
    
    results = []
    names = next(os.walk(root))[1]
    
    for name in names:
        if name.startswith(filter):
            results.append(name)
           
    return results

def xcopy(source, dest):
    
    cmd = ("echo F | xcopy /q /d \"%s\" \"%s\"" % (source, dest))
    os.system(cmd)

def robocopy_only_missing_file(source, dest):
    
    cmd = ("robocopy /XC /XN /XO /E /R:5 /COPY:DT \"%s\" \"%s\"" % (source, dest))
    os.system(cmd)

def robocopy(source, dest, file_to_copy="", exclude=""):
    cmd = ("robocopy \"%s\" \"%s\" \"%s\" /XD \"%s\" /NDL /NFL /E /NP /R:10 /MT:64" % (source, dest, file_to_copy, exclude))
    return os.system(cmd)

def run_subprocess1(command):
    # Start the subprocess
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)

    # Create a thread to read and print the subprocess output
    def print_output():
        for line in process.stdout:
            print(line.strip())

    t = threading.Thread(target=print_output)
    t.start()

    # Wait for the subprocess to complete
    process.wait()

    # Wait for the print thread to complete
    t.join()


def run_subprocess(cmd):

    err_code = 0
    cmd_output = None

    try:
    
        cmd_output = subprocess.check_output(
            cmd, 
            stderr=subprocess.STDOUT, 
            shell=True)
    
    except subprocess.CalledProcessError as ex:
        cmd_output = ex.output
        err_code = ex.returncode

    return {"err_code": err_code, "cmd_output": cmd_output.decode()}

def compress(
        folder_to_compress, 
        compressed_filename,
        exec_7z = "C:\\Program Files\\7-Zip\\7z.exe",
        volume_size = "1024m",
        compression_level = "0",
        compression_type = "zip",
        include_top_directory = False
        ):
    
    if not include_top_directory:
        folder_to_compress = folder_to_compress + "\\*"
    
    
    cmd = "\"{0}\" a -t{1} {2} {3} -v{4} -mx{5}".format(
        exec_7z, 
        compression_type,
        compressed_filename,
        folder_to_compress,
        volume_size,
        compression_level
    )

    print("***** 7zip command to execute")
    print(cmd)
    
    result = run_subprocess(cmd)
        
    if result["cmd_output"]:
        print("***** 7zip command output")
        print(result["cmd_output"])

    if result["err_code"] == 0:
        print("***** 7zip command completed successfully!")
    
    return result["err_code"]

def mount(url, drive="P"):
   
    cmd = "cmd /c IF NOT EXIST {1}: NET USE {1}: {0} /u:_ft_auto /PERSISTENT:Yes".format(url, drive)
    print("******* Running " + cmd)
    
    output = os.system(cmd)
    print(output)

    os.system("NET USE")

def unmount(drive="P"):
    
    cmd = "cmd /c NET USE /DELETE /Y %s:" %(drive) 
    print("******* Running " + cmd)

    output = os.system(cmd)
    print(output)


def push_artifacts(repo_path, filename, local_file):
    URL = "https://fraartifactory.swinfra.net/artifactory"
    REPO_NAME = "/adm-ufto-generic-local"
    USERNAME = "_ft_auto"
    PASSWORD = "W3lcome1"
    
    
    cmd = "curl --retry 3 --retry-delay 10 -u {0}:{1} -X PUT https://fraartifactory.swinfra.net/artifactory/adm-ufto-generic-local/{2}/{3} -T {4}".format(
        USERNAME, PASSWORD, repo_path, filename, local_file
    )
    
    print("***** Running " + cmd)
    os.system(cmd)


def rmdir(path_to_remove):

    try:

        shutil.rmtree(path_to_remove)
        print("'%s' is deleted successfully!")

    except Exception as e: 
        print("[Error: Exception occured when removing directoy!")
        print(e)
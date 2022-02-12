import winrm
import subprocess
import os
import logging
logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(message)s")


# Reference- https://www.tutorialspoint.com/How-to-copy-files-from-one-server-to-another-using-Python
class ConnectMachine():
    def __init__(self, 
        host, 
        username="_ft_auto", 
        password="W3lcome1", 
        domian="swinfra.net",
        transport="ntlm"
    ):
        self.host = host
        self.username = username
        self.password = password
        self.domian = domian
        self.transport = transport
    
    def connect(self):
        print("[Info]: Connecting to '" + self.host +"'")
        print("Hostname: " + self.host)
        print("username: " + self.username)
        print("password: " + self.password)
        return winrm.Session(
            self.host, 
            auth=('{}@{}'.format(self.username, self.domian), self.password),
            transport=self.transport,
            server_cert_validation='ignore'
        )
   

    def runCommand(self, cmd, args=[]):
        logging.info("Running command '" + cmd +"'")
        
        session = None

        try:

            session = self.connect()

        except Exception as ex: 
            return { "status_code": "-1", "std_err": ex, "std_out": None}

        if session != None:
            logging.info("The connection established successfully!")

        # Return std object. std.status_code, std._std_err, std.std_out 
        return session.run_cmd(cmd, args)
        
    
    def run_ps(self, script):
        print("Running PS command: " + script +"'")

        session = None

        try:

            session = self.connect()

        except Exception as ex: 
            return { "status_code": "-1", "std_err": ex, "std_out": None}

        if session != None:
            logging.info("The connection established successfully!")

        # Return std object. std.status_code, std._std_err, std.std_out 
        return session.run_ps(script)
    
    # Return 0 or 1 on the std out. 0 means exist and 1 means not exist 
    def IsFileExist(self, filename):
        """Checking the file exist or not exist. Return 0 if exist else return 1"""
        logging.info("Checking '{0}' file is exist.".format(filename))
        
        result = self.runCommand("IF EXIST {0} (echo 0) else (echo 1)".format(filename))
        return result.std_out.decode("utf-8")
    
    def kill_process(self, process_name):
        """Kill the process if the process is running"""
        
        output = self.runCommand('taskkill', ['/F', '/IM', process_name]) # taskkill /F /IM Process Name
        return_code = output.status_code
        
        if output.std_err:
            logging.error(output.std_err.decode("utf-8"))

        if output.std_err:
            logging.info(output.std_out.decode("utf-8"))
        
        # Return code 128 for not found the process
        if int(return_code) == 128:
            return str(0)

        return return_code

    def RunProcess_old(self, args):
        """ Run process on the local machine and return stderr, stdout """
    
        proc = subprocess.Popen(args, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
        stdout, stderr = proc.communicate()

        # Log errors if a hook failed
        if proc.returncode != 0:
            print('{} : {} \n{}'.format(args[0], proc.returncode, stderr))

        
        if stderr.decode('UTF-8') != "":
            return stderr.decode('UTF-8')

        return stdout.decode('UTF-8')

    def RunProcess(self, args):
        """ Run process on the local machine and return stderr, stdout """
    
        proc = subprocess.Popen(args, stdout = subprocess.PIPE, stderr = subprocess.PIPE, universal_newlines=True)
       
        # Handling err
        for line in iter(proc.stderr.readline, ""):
            print("\t" + line, end='')

        proc.stderr.close()
        
        # Constantly printing process output line by line to avoid waiting at the end
        for line in iter(proc.stdout.readline, ""):
            print("\t" + line, end='')
        
        proc.stdout.close()

        # Get the return code
        return_code = proc.wait()

        # Log errors if a hook failed
        if return_code != 0:
            print('{} : {} \n{}'.format(args[0], return_code, proc.stderr), end='')
        
        return return_code

    def RunProcessSync(self, args):
        """ Run process on the local machine and return stderr, stdout """
    
        proc = subprocess.Popen(args, stdout = subprocess.PIPE, stderr = subprocess.PIPE, universal_newlines=True)
        (output, err) = proc.communicate()  

        #This makes the wait possible
        return_code = proc.wait()

        if err:
            print("error")
            print(err)
        print(output)

        # Log errors if a hook failed
        if return_code != 0:
            logging.error('{} : {} \n{}'.format(args[0], return_code, proc.stderr), end='')
        
        return return_code
        
    def WaitForWinRMReady(self):
       """Wait for WinRM service to ready"""
       source = os.path.dirname(os.path.abspath(__file__))
       print(source)

       return self.RunProcessSync([
            os.environ['SYSTEMROOT'] + "\\System32\\WindowsPowerShell\\v1.0\\powershell.exe", 
            source +  "\\ps_script\\CheckWinrmStatus.ps1",
            "-hostname " + self.host,
            "-username {0}@{1}".format(self.username, self.domian),
            "-password " + self.password
        ])

    def CopyFile(self, CopyFrom, CopyTo):
        "Copy file from local to remote (Windows) machine. The function used Powershell to copy file!"
        source = os.path.dirname(os.path.abspath(__file__))
        logging.info(source)

        return self.RunProcessSync([
            os.environ['SYSTEMROOT'] + "\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
            source + "\\ps_script\\CopyToRemote.ps1",
            "-hostname " + self.host,
            "-username " + "{0}@{1}".format(self.username, self.domian),
            "-password " + self.password,
            "-source " +  CopyFrom, 
            "-destination " + CopyTo
        ])
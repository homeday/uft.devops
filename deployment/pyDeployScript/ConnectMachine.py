import winrm
import subprocess
import logging
logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(message)s")


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
        logging.info("Connecting to '" + self.host +"'")
        
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
            return "Failed to established connection. Reason: " + ex

        if session != None:
            logging.info("The connection established successfully!")

        result = session.run_cmd(cmd, args)
        
        if result.status_code == 0:
            logging.info("The command executed successfully!")

        if result.std_err:
            return result.std_err.decode("UTF-8")

        return result.std_out.decode("UTF-8")
    
    def run_ps(self, script):
        logging.info("Running PS command: " + script +"'")
        session = self.connect()
        result = session.run_ps(script) 
        
        print(result.status_code)
        if result.std_err:
            return result.std_err.decode("UTF-8")

        return result.std_out.decode("UTF-8")
    def kill_process(self, process_name):
        """Kill the process if the process is running"""
        
        session = None

        try:
            session = self.connect()
        except Exception as ex: 
            return "Failed to established connection. Reason: " + ex

        if session != None:
            logging.info("The connection established successfully!")

        output = session.run_cmd('taskkill', ['/F', '/IM', process_name]) # taskkill /F /IM Process Name
        std_out = output.std_out.decode("utf-8")
        
        if std_out == '':
            return "The '" + process_name + "' process is not running."

        return std_out

    def RunProcess_old(self, args):
        """ Run process on the local machine and return stderr, stdout """
    
        proc = subprocess.Popen(args, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
        stdout, stderr = proc.communicate()

        # Log errors if a hook failed
        if proc.returncode != 0:
            logging.info('{} : {} \n{}'.format(args[0], proc.returncode, stderr))

        
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
            logging.info('{} : {} \n{}'.format(args[0], return_code, proc.stderr), end='')
        
        return return_code

    def WaitForWinRMReady(self):
       """Wait for WinRM service to ready"""
       return self.RunProcess([
            "powershell.exe", 
            ".\\ps_script\\CheckWinrmStatus.ps1",
            "-hostname " + self.host,
            "-username {0}@{1}".format(self.username, self.domian),
            "-password " + self.password
        ])

    def CopyFile(self, CopyFrom, CopyTo):
        "Copy file from local to remote (Windows) machine. The function used Powershell to copy file!"

        return self.RunProcess([
            "powershell.exe", 
            ".\\ps_script\\CopyToRemote.ps1",
            -hostname + " " + self.host,
            -username + " " + "{0}@{1}".format(self.username, self.domian),
            -password + " " + self.password,
            -source  + " " + CopyFrom,
            -destination + " " + CopyTo
        ])
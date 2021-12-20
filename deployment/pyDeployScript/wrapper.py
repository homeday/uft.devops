#!/bin/usr/python

import os
import time
#import winrm

class DeployMachineWrapper():
    def __init__(self, vm_name, username, password, domian, subscription_id, catalog_id, portal_url, org,mnm_portal_url,
            automation_username,automation_password, jar_package):
            
        self.vm_name = vm_name
        self.username = username
        self.password = password
        self.domian = domian
        self.subscription_id = subscription_id
        self.catalog_id = catalog_id
        self.portal_url = portal_url
        self.jar_package = jar_package
        self.org = org
        self.mnm_portal_url = mnm_portal_url
        self.automation_username = automation_username
        self.automation_password = automation_password
        self.account_name = domian + "\\" + username
        self.vm_full_name = vm_name + "." + domian

    def revert_snapshot(self):
        """Revert snapshot of CSA and restart the machine"""

        cmd = "cmd /c java -jar {0} subscriptionId={1} actionName=RevertToSnapshot csaOrganization={2} csaUrl={3} csaUsername={4} csaPassword={5} managementPortalUrl={6} automationUsername={7} automationPassword={8} ".format(
            self.jar_package,
            self.subscription_id,
            self.org,
            self.portal_url,
            self.username,
            self.password,
            self.mnm_portal_url,
            self.automation_username,
            self.automation_password
        )
        print("Command to execute: " + str(cmd))

        os.system(cmd) # Revert to Snapshot
        time.sleep(20) # Sleep 20 secs
        DeployMachineWrapper.restart_machine(self) # Restart
    
    def kill_process(self, win_rm_session, process_name):
        """Kill the process if the process is running"""
        
        output = win_rm_session.run_cmd('taskkill', ['/F', '/IM', process_name]) # taskkill /F /IM Process Name
        std_out = output.std_out.decode("utf-8")
        
        if std_out == '':
            return "The '" + process_name + "' process is not running."

        return std_out

    def __uninstall_application(self):
        """Uninstallat UFT using UFTUninstaller.exe"""

        # Restart
        # Kill MSIexec Process
        print("Target Host: " + self.vm_full_name)
        # session = winrm.Session(self.vm_full_name, auth=('{}@{}'.format(self.username, self.domian), self.password), transport='ntlm')
        #session.run_cmd('ipconfig', ['/all']) # To run command in cmd
        
        print("Killing 'msiexec.exe' process if the process is running")
        # std_out = DeployMachineWrapper.kill_process(self, session, 'msiexec.exe')
        # print(std_out)

    
    # [Void]UninstallApplication(
    #     [string]$CSAName,
    #     [System.Management.Automation.PSCredential]$CSACredential
    # ) {
    #     Write-Host "CSAPreparationUninstallUFT::UninstallApplication Start" -ForegroundColor Green -BackgroundColor Black
    #     ([CSAPreparation]$this).RestartMachine($CSAName, $CSACredential)
    #     $this.StopMsiexecProcess($CSAName, $CSACredential)
    #     Write-Host "To delete old version UFT with the uninstaller tool" -ForegroundColor Green -BackgroundColor Black
    #     $ExpressionResult = Invoke-Command -Credential $CSACredential -ComputerName $CSAName -ScriptBlock { 
    #         Start-Process -FilePath "C:\UFTUninstaller_v2.0\UFTUninstaller.exe" -ArgumentList -silent -Wait 
    #     } 
    #     Write-Host $ExpressionResult -ForegroundColor DarkBlue -BackgroundColor Gray -Separator "`n"
    #     ([CSAPreparation]$this).RestartMachine($CSAName, $CSACredential)
    #     Write-Host "CSAPreparationUninstallUFT::UninstallApplication End" -ForegroundColor Green -BackgroundColor Black
    # }

    def __map_drive(self):
        """Map the server to grant the access"""
        
        os.system("cmd /c net use * /delete /y")
        cmd = "cmd /c net use \\\\{0}\\IPC$ {1} /USER:{2}".format(self.vm_full_name, self.password, self.account_name)
        print(cmd)
        
        return os.system(cmd)

    def restart_machine(self, type="rest"):
        """Restart the target (remote) server"""


        if type.lower() == "rest":
            cmd = "cmd /c java -jar {0} subscriptionId={1} actionName=Restart csaOrganization={2} csaUrl={3} csaUsername={4} csaPassword={5} managementPortalUrl={6} automationUsername={7} automationPassword={8} ".format(
                self.jar_package,
                self.subscription_id,
                self.org,
                self.portal_url,
                self.username,
                self.password,
                self.mnm_portal_url,
                self.automation_username,
                self.automation_password
            )
            print("Restart from HCM rest!")
            print(cmd)
            return os.system(cmd)

        DeployMachineWrapper.__map_drive(self)
        cmd = "cmd /c shutdown /r /m \\\\{0} /f".format(self.vm_full_name)
        print("Restart from command line!")
        print(cmd)
        return os.system(cmd)

    def unintall(self):
        """Uninstall Application"""

        DeployMachineWrapper.__uninstall_application(self)
        # i = 0
        # is_exist = true
        # while is_exist and i < 3:
        #     # uninstallation action
        #     is_exist = is_uft_exist()
        #     i += 1
        

    def is_uft_installed(self):
        """Check app exist or not. Return true if app found"""
        
        DeployMachineWrapper.__map_drive() # Grant permission to access the network path
        # cmd = "cmd /c net use \\" + self.vm_full_name + "\IPC /USER:" + self.account_name + " " + self.password
        # print(cmd)
        # os.system(cmd)

        is_app_exist = false
        is_app_exist = os.path.exists("\\\\" + self.vm_full_name + "\\C$\\Program Files (x86)\\Micro Focus\\Unified Functional Testing\\bin\\UFT.exe")
        
        if not is_app_exist:
            is_app_exist = os.path.exists("\\\\" + self.vm_full_name + "\\C$\\Program Files (x86)\\HPE\\Unified Functional Testing\\bin\\UFT.exe")
        
        if not is_app_exist:
            is_app_exist = os.path.exists("\\\\" + self.vm_full_name + "\\C$\\Program Files (x86)\\HP\\Unified Functional Testing\\bin\\UFT.exe")

        return is_app_exist



    
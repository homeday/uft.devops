#!/bin/usr/python
from DeployMachineCore import DeployMachine
from config import Config
from ConnectMachine import ConnectMachine
import os

import logging
logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(message)s")

class Deploy():

    def __init__(self, 
            vm_name, sid, 
            cid = None, 
            username="_ft_auto", 
            password="W3lcome1", 
            domian="swinfra.net", 
            hcm_url=Config.hcm_url,
            csa_organization=Config.csa_organization,
            mnm_portal_url=Config.mnm_portal_url, 
            automation_username=Config.automation_username, 
            automation_password=Config.automation_password,
            jar_package=Config.csa_5_jar_package
        ):
        self.vm_name = vm_name
        self.username = username
        self.password = password
        self.domian = domian
        self.subscription_id = sid
        self.catalog_id = cid
        self.machine = DeployMachine(
                vm_name,
                username,
                password,
                domian,
                sid, 
                cid,
                hcm_url, 
                csa_organization,
                mnm_portal_url,  
                automation_username, 
                automation_password,
                jar_package
        )
        self.conn = ConnectMachine(self.vm_name, self.username,self.password, self.domian)
    
    def revert_snapshot(self):
        """Revert to snapshot."""
        
        if self.machine == None:
            raise "The 'machine' object is not initialized!"
            
        return self.machine.revert_snapshot()
        
    def restart_machine(self, restart_type="rest"):
        """ Restart machine
            restart_type="rest": Restart HCM machine using HCM rest API
            restart_type="cmd": restart machine running command
        """
        return self.machine.restart_machine(restart_type)

    def WaitForWinrmServices(self):
        return self.conn.WaitForWinRMReady()
        
    def prepare_machine(self):
        logging.info("Copying require file to the machine ...")
        source = os.path.dirname(os.path.abspath(__file__)) + "\\Preparation_files\\*"
        logging.info(source)
        return self.conn.CopyFile(".\\Preparation_files\\*", "C:\\")

    def uninstall(self, prodcutName="uft"):
        """Uninstall product like uft| st"""
        
        logging.info("Copying relevent files to remote machine")
        self.conn.CopyFile(".\\Preparation_files\\UFTUninstaller_v2.0\\*", "C:\\UFTUninstaller_v2.0\\")
        self.conn.CopyFile(".\\Preparation_files\\del.bat", "C:\\UFTUninstaller_v2.0\\del.bat")
        logging.info("Uninstllation has started!")
        
        self.conn.runCommand("C:\\UFTUninstaller_v2.0\\UFTUninstaller.exe -product:"+ prodcutName + " -silent ")
        logging.info("Uninstllation done!")
        
        return self.conn.runCommand("C:\\del.bat")
        

    def install_lft(self):
        """Install LeanFT"""
        pass

    
    def install(self, command):
        return self.conn.runCommand(command)

    def install_uft(self, buildNumber, mode="resnapshot"):
        """This function support two installtion mode; resnapshot or uninstallation
           resnapshot: This mode will revert the machine to snapshot and install the UFT (more like installing UFT on a clean machine)
           uninstall: This mode will uninstall the UFT if exist and install it
        """
        logging.info("Installing UFT with '" + mode + "' mode ...")
        
        if mode == "uninstall":
            self.uninstall("uft")
            self.restart_machine()
        else:
            self.revert_snapshot()
        
        self.WaitForWinrmServices()
        self.prepare_machine()
        self.conn.kill_process("msiexec")
        return self.install("C:\installUFT.bat " + buildNumber + " " + Config.license_server + " " + Config.rubicon_username + " " + Config.rubicon_password)
    
    def install_uft_from_jenkins(self, buildNumber):
        self.WaitForWinrmServices()
        self.prepare_machine()
        self.conn.kill_process("msiexec")
        return self.install("C:\installUFT.bat " + buildNumber + " " + Config.license_server + " " + Config.rubicon_username + " " + Config.rubicon_password)

    def install_patch_on_uft(self, buildNumber):
        pass

    def install_codeless_on_uft(self, buildNumber):
        pass

    def install_codeless_on_lft(self, buildNumber):
        pass

    def install_Test(self):
        """Install UFT"""
        logging.info("Running dummy command to test ...")
        return self.conn.runCommand("C:\\test.bat 2021.1.0.860 " + Config.license_server + " " + Config.rubicon_username + " " + Config.rubicon_password)
        

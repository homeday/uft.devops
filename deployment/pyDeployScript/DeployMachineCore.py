#!/bin/usr/python

import os
import time

class DeployMachine():
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
        DeployMachine.restart_machine(self) # Restart
    
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
            # print(cmd)
            return os.system(cmd)

        # DeployMachine.__map_drive(self)
        cmd = "cmd /c shutdown /r /m \\\\{0} /f".format(self.vm_name)
        print("Restart from command line!")
        # print(cmd)
        return os.system(cmd)


    
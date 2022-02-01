import sys
from ConnectMachine import ConnectMachine
from Deploy import Deploy
import xmltodict
import os

GlobalProperties = {}
hosts = []


# Convert yaml to python dict        
def InitProperties(machineListFile):
    with open(machineListFile) as f:
        text = f.read()

    d = xmltodict.parse(text)
    for k,deploy in d.items():
        for k, gp in deploy.items():
            if(k == "GlobalProperties"):
                global GlobalProperties 
                GlobalProperties = dict(gp)
            if(k == "hosts"):
                for key, value in gp.items():
                    for host in value:
                        hosts.append(dict(host))


# Get environments from the OS
VM_NAME = os.environ['VM_NAME']
MODE = os.environ['MODE']
BUILD_VERSION = os.environ['BUILD_VERSION']
DEV_XML = os.getcwd() + "\\..\\csa\\" + os.environ['LABEL'] + "_RnD_Deploy.xml"
QA_XML = os.getcwd() + "\\..\\csa_qa\\" + os.environ['LABEL'] + "_QA_Deploy_HCM.xml"
MLU_XML = os.getcwd() + "\\..\\csa_mlu\\" + os.environ['LABEL'] + "_QA_Deploy_G11N.xml"

if(MODE.lower() != "resnapshot" and MODE.lower() != "uninstall"):
    raise ValueError("The MODE (second) aregument value can not be other than these: 'resnapshot', 'uninstall'")

# if(not os.path.exists(DEV_XML)):
#     raise ValueError("File is not exists at " + DEV_XML)

print("Reading the '{0}' host information in '{1}'".format(VM_NAME, DEV_XML))
InitProperties(DEV_XML)

is_vm_exist = False
for host in hosts:
    if host["VM_NAME"] == VM_NAME:
        is_vm_exist = True
        hostname = "{0}.{1}".format(VM_NAME, host.get('CSADomain', GlobalProperties["CSADomain"]))
        username = host.get('CSAAccount', GlobalProperties["CSAAccount"])
        password = host.get('CSAPassword', GlobalProperties["CSAPassword"])
        domian = host.get('CSADomain', GlobalProperties["CSADomain"])


if is_vm_exist == False:
    print("The '{}' host info does not exist in '{}'".format(VM_NAME, DEV_XML))
    print("Reading the '{0}' host information in '{1}'".format(VM_NAME, QA_XML))
    InitProperties(QA_XML)

    for host in hosts:
        if host["VM_NAME"] == VM_NAME:
            is_vm_exist = True
            hostname = "{0}.{1}".format(VM_NAME, host.get('CSADomain', GlobalProperties["CSADomain"]))
            username = host.get('CSAAccount', GlobalProperties["CSAAccount"])
            password = host.get('CSAPassword', GlobalProperties["CSAPassword"])
            domian = host.get('CSADomain', GlobalProperties["CSADomain"])


if is_vm_exist == False:
    print("The '{}' host info does not exist in '{}'".format(VM_NAME, QA_XML))
    print("Reading the '{0}' host information from '{1}'".format(VM_NAME, MLU_XML))
    InitProperties(MLU_XML)

    for host in hosts:
        if host["VM_NAME"] == VM_NAME:
            is_vm_exist = True
            hostname = "{0}.{1}".format(VM_NAME, host.get('CSADomain', GlobalProperties["CSADomain"]))
            username = host.get('CSAAccount', GlobalProperties["CSAAccount"])
            password = host.get('CSAPassword', GlobalProperties["CSAPassword"])
            domian = host.get('CSADomain', GlobalProperties["CSADomain"])

if is_vm_exist == False:
    print("The '{}' host info does not exist in '{}'".format(VM_NAME, MLU_XML))
    print("'{0}' host was not configured in the HCM XML file.".format(VM_NAME)) 
    sys.exit(-1)
 


deploy = Deploy(hostname, host["SUBSCRIPTION_ID"], host["CATALOG_ID"], username, password, domian)
sys.exit(deploy.install_uft(BUILD_VERSION, MODE.lower()))

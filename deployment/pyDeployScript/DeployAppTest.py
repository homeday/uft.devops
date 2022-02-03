import sys
from ConnectMachine import ConnectMachine
from Deploy import Deploy
import xmltodict
import os
import logging
logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(message)s")

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

def GetConfigFilePath(label, xml_type="dev"):

    file_to_read = "{0}\\..\\csa\\{1}_RnD_Deploy.xml".format(os.getcwd(), label)
    if xml_type.lower() == "qa":
        file_to_read = "{0}\\..\\csa_{1}\\{2}_QA_Deploy_HCM".format(os.getcwd(), xml_type, label)

    if xml_type.lower() == "mlu":
        file_to_read = "{0}\\..\\csa_{1}\\{2}_QA_Deploy_G11N.xml".format(os.getcwd(), xml_type, label)

    # logging.info("Machine configuration filename: " + file_to_read)
    return file_to_read

# Get environments from the OS
VM_NAME = os.environ['VM_NAME']
MODE = os.environ['MODE']
BUILD_VERSION = os.environ['BUILD_VERSION']

DEV_XML = GetConfigFilePath(os.environ['LABEL'])
QA_XML = GetConfigFilePath(os.environ['LABEL'], "qa")
MLU_XML = GetConfigFilePath(os.environ['LABEL'], "mlu")

if(MODE.lower() != "resnapshot" and MODE.lower() != "uninstall"):
    raise ValueError("The MODE (second) aregument value can not be other than these: 'resnapshot', 'uninstall'")

# if(not os.path.exists(DEV_XML)):
#     raise ValueError("File is not exists at " + DEV_XML)

logging.info("Reading the '{0}' host information in '{1}'".format(VM_NAME, DEV_XML))
InitProperties(DEV_XML)

is_vm_exist = False
for host in hosts:
    if host["VM_NAME"] == VM_NAME:
        is_vm_exist = True
        hostname = "{0}.{1}".format(VM_NAME, host.get('CSADomain', GlobalProperties["CSADomain"]))
        sub_id = host.get('SUBSCRIPTION_ID', '')
        cat_id = host.get('CATALOG_ID', '')
        username = host.get('CSAAccount', GlobalProperties["CSAAccount"])
        password = host.get('CSAPassword', GlobalProperties["CSAPassword"])
        domian = host.get('CSADomain', GlobalProperties["CSADomain"])


if is_vm_exist == False:
    logging.info("The '{}' host info does not exist in '{}'".format(VM_NAME, DEV_XML))
    logging.info("Reading the '{0}' host information in '{1}'".format(VM_NAME, QA_XML))
    InitProperties(QA_XML)

    for host in hosts:
        if host["VM_NAME"] == VM_NAME:
            is_vm_exist = True
            hostname = "{0}.{1}".format(VM_NAME, host.get('CSADomain', GlobalProperties["CSADomain"]))
            sub_id = host.get('SUBSCRIPTION_ID', '')
            cat_id = host.get('CATALOG_ID', '')
            username = host.get('CSAAccount', GlobalProperties["CSAAccount"])
            password = host.get('CSAPassword', GlobalProperties["CSAPassword"])
            domian = host.get('CSADomain', GlobalProperties["CSADomain"])


if is_vm_exist == False:
    logging.info("The '{}' host info does not exist in '{}'".format(VM_NAME, QA_XML))
    logging.info("Reading the '{0}' host information from '{1}'".format(VM_NAME, MLU_XML))
    InitProperties(MLU_XML)

    for host in hosts:
        if host["VM_NAME"] == VM_NAME:
            is_vm_exist = True
            hostname = "{0}.{1}".format(VM_NAME, host.get('CSADomain', GlobalProperties["CSADomain"]))
            sub_id = host.get('SUBSCRIPTION_ID', '')
            cat_id = host.get('CATALOG_ID', '')
            username = host.get('CSAAccount', GlobalProperties["CSAAccount"])
            password = host.get('CSAPassword', GlobalProperties["CSAPassword"])
            domian = host.get('CSADomain', GlobalProperties["CSADomain"])

if is_vm_exist == False:
    logging.info("The '{}' host info does not exist in '{}'".format(VM_NAME, MLU_XML))
    logging.info("'{0}' host was not configured in the HCM XML file.".format(VM_NAME)) 
    sys.exit(-1)
 
logging.info("Hostname: " + hostname)
logging.info("Subscription_Id: " + sub_id)

if hostname == "":
    logging.ERROR("Hostname cannot be empty")
    sys.exit(-1)

if sub_id == "":
    logging.ERROR("Subscription cannot be empty")
    sys.exit(-1)

deploy = Deploy(hostname, sub_id, cat_id, username, password, domian)
sys.exit(deploy.install_uft(BUILD_VERSION, MODE.lower()))

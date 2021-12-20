import sys
from wrapper import DeployMachineWrapper
from config import Config
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

def PreparingWrapperObject(
    machinName, 
    subscriptionId,
    catalogId,
    username="_ft_atuo",
    password="W3lcome1",
    domian="swinfra.net"
    ):
    return DeployMachineWrapper(machinName, username, password, 
    domian, subscriptionId, catalogId, Config.hcm_url, Config.csa_organization,
    Config.mnm_portal_url,  Config.automation_username, Config.automation_password,
    Config.csa_5_jar_package)


# wrapper = DeployMachineWrapper("myd-hvm00266", "_ft_auto", "W3lcome1", 
#     "swinfra.net", "2c90b185765081f00176ffbd31485073", "8a471d916170325b016174057e31037b", Config.hcm_url, Config.csa_organization,
#     Config.mnm_portal_url,  Config.automation_username, Config.automation_password,
#     Config.csa_5_jar_package)

# Get environments from the OS
VM_NAME = os.environ['VM_NAME']
ACTION = os.environ['ACTION']
XML_FILE = os.getcwd() + "\\..\\csa\\" + os.environ['LABEL'] + "_RnD_Deploy.xml"

if(ACTION.lower() != "restart" and ACTION.lower() != "revert"):
    raise ValueError("The action (second) aregument value can not be other than these: 'restart', 'revert'")

if(not os.path.exists(XML_FILE)):
    raise ValueError("File is not exists at " + XML_FILE)

InitProperties(XML_FILE)

# print(hosts)
for host in hosts:
    if(host["VM_NAME"] == VM_NAME):
        username = host.get('CSAAccount', GlobalProperties["CSAAccount"])
        password = host.get('CSAPassword', GlobalProperties["CSAPassword"])
        domian = host.get('CSADomain', GlobalProperties["CSADomain"])
        wrapper = PreparingWrapperObject(host["VM_NAME"], host["SUBSCRIPTION_ID"], host["CATALOG_ID"], username, password, domian)

if(ACTION.lower() == "restart"):
    wrapper.restart_machine()

if(ACTION.lower() == 'revert'):
    wrapper.revert_snapshot()


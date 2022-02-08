import xmltodict
import os

def xml_parse_to_dict(xml_file):
    parse_to_dict = { "hosts": [], "GlobalProperties": {}}
    with open(xml_file) as f:
        text = f.read()

    d = xmltodict.parse(text)
    for k,deploy in d.items():
        for k, gp in deploy.items():
            if(k == "GlobalProperties"):
                parse_to_dict["GlobalProperties"] = dict(gp)
            if(k == "hosts"):
                for key, value in gp.items():
                    for host in value:
                        parse_to_dict["hosts"].append(dict(host))

    return parse_to_dict

def GetConfigFilePath(label, xml_type="dev"):

    file_to_read = "{0}\\..\\csa\\{1}_RnD_Deploy.xml".format(os.getcwd(), label)
    if xml_type.lower() == "qa":
        file_to_read = "{0}\\..\\csa_{1}\\{2}_QA_Deploy_HCM.xml".format(os.getcwd(), xml_type, label)

    if xml_type.lower() == "mlu":
        file_to_read = "{0}\\..\\csa_{1}\\{2}_QA_Deploy_G11N.xml".format(os.getcwd(), xml_type, label)

    # logging.info("Machine configuration filename: " + file_to_read)
    return file_to_read
def get_info(vm_name, label, machine_type):

    machine_info = {
            "hostname": "", 
            "sub_id": "", 
            "cat_id": "",
            "username": "",
            "password": "",
            "domian": "",
            "is_vm_exists": False}

    xml_dict = xml_parse_to_dict(GetConfigFilePath(label, machine_type))
    is_vm_exist = False
    
    hosts = xml_dict["hosts"] # Get all hosts
    GlobalProperties = xml_dict["GlobalProperties"] # Get global properties

    for host in hosts:
        if host["VM_NAME"] == vm_name:
            machine_info["is_vm_exists"] = True
            machine_info["hostname"] = "{0}.{1}".format(vm_name, host.get('CSADomain', GlobalProperties["CSADomain"]))
            machine_info["sub_id"] = host.get('SUBSCRIPTION_ID', '')
            machine_info["cat_id"] = host.get('CATALOG_ID', '')
            machine_info["username"] = host.get('CSAAccount', GlobalProperties["CSAAccount"])
            machine_info["password"] = host.get('CSAPassword', GlobalProperties["CSAPassword"])
            machine_info["domian"] = host.get('CSADomain', GlobalProperties["CSADomain"])

    return machine_info

# Main function 
def get_machine_info(vm_name, label):
    m_info = get_info(vm_name, label, "dev")

    if m_info["is_vm_exists"]:
        return m_info

    m_info = get_info(vm_name, label, "qa")
    if m_info["is_vm_exists"]:
        return m_info

    m_info = get_info(vm_name, label, "mlu")
    if m_info["is_vm_exists"]:
        return m_info

    return m_info

    

    
    

    
import sys
from Deploy import Deploy
import os
import util
import logging
logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(message)s")

 
# Get environments from the OS
VM_NAME = os.environ['VM_NAME'].strip()
PATCH_BUILD_NUMBER = os.environ['PATCH_BUILD_NUMBER'].strip()
LABEL = os.environ['LABEL'].strip()
PATCH_ID = os.environ['PATCH_ID'].strip()


machine_info = util.get_machine_info(VM_NAME, LABEL)
if not machine_info["is_vm_exists"]:
    logging.info("The '{}' host info does not found in Dev, QA, and MLU xml configuration'".format(VM_NAME))
    sys.exit(-1)
 
if machine_info["hostname"] == "":
    logging.ERROR("Hostname cannot be empty")
    sys.exit(-1)

if machine_info["sub_id"] == "":
    logging.ERROR("Subscription cannot be empty")
    sys.exit(-1)

logging.info("Hostname: " + machine_info["hostname"])
logging.info("Subscription_Id: " + machine_info["sub_id"])

deploy = Deploy(
    machine_info["hostname"], machine_info["sub_id"], machine_info["cat_id"], 
    machine_info["username"], machine_info["password"], machine_info["domian"])

ret_code = deploy.install_uft_patch(PATCH_BUILD_NUMBER, PATCH_ID)
deploy = None # reset 
sys.exit(ret_code)

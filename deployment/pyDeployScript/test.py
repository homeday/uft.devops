from ConnectMachine import ConnectMachine
from Deploy import Deploy
import xmltodict
machine = { "name": "", "sid": "", "cid":"", "username":"", "password":"", "domain": ""}
machines = [
    { "name": "", "sid": "", "cid":"", "username":"", "password":"", "domain": ""},
    { "name": "", "sid": ""}
]

print(machines)

with open('machines.xml') as f:
    text = f.read()

d = xmltodict.parse(text)
GlobalProperties = {}
hosts = []
for k,deploy in d.items():
    for k, gp in deploy.items():
        if(k == "GlobalProperties"):
            GlobalProperties = dict(gp)
        if(k == "hosts"):
            for key, value in gp.items():
                for host in value:
                    hosts.append(dict(host))

 
# print(GlobalProperties)
# print(hosts)
# conn = ConnectMachine("myd-hvm00266.swinfra.net")
# print(conn.runCommand('ipconfig', ['/all']))
deploy = Deploy("myd-hvm00266.swinfra.net", "2c90b185765081f00176ffbd31485073", "8a471d916170325b016174057e31037b")
# deploy = Deploy("myd-hvm03853.swinfra.net", "2c9090b36e91b9e10170389b750579e5")
# print(deploy.revert_snapshot())
# print(deploy.WaitForWinrmServices())
# print(deploy.prepare_machine())
print(deploy.install_uft("2021.1.0.862", "uninstall"))
# print(deploy.uninstall())
# print(deploy.install_Test())
# print(conn.CopyFile("C:\\works\\naren\\DevOps\\devops\\auto_deploy\\deployment\\Preparation_files\\*", "C:\\Preparation_files\\"))
#print(conn.copy_file("C:\\works\\naren\\DevOps\\devops\\auto_deploy\\deployment\\wrapper.py", "C:\\test.py"))
#print(conn.runCommand('cd /'))
#print(conn.runCommand('dir'))
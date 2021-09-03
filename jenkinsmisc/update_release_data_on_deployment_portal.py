# !/usr/bin/python
### This scrit is used to configure the release data in the deployment poertal


import sys, getopt, os
import requests

def SendRequest(url, method, payload={}):
	if method.upper() == "POST":
		return requests.post(url, payload) 

	if method.upper() == "PUT":
		return requests.put(url, payload)
def ArgValidator(argv):
	"""Validate commmand line arguments"""
	
	if len(argv) <= 0:
		print(cmd_help)
		sys.exit(2)	
	try:
		opts, args = getopt.getopt(argv, "hn:c:",["nRelease=","cRelease="])

	except getopt.GetoptError:
		print(cmd_help)
		sys.exit(2)

	for opt, arg in opts:
		if opt == '-h':
			print(cmd_help)
			sys.exit()

		
		if opt in ("-n", "--nRelease"):
			
			if not arg:
				print(cmd_help)
				sys.exit()	
			global upcoming_release
			upcoming_release = arg

		if opt in ("-c", "--cRelease"):
			if not arg:
				print(cmd_help)
				sys.exit()	
			
			global current_release
			current_release = arg


upcoming_release = ""
current_release = ""
HOST_URL = "http://myd-vma00436.swinfra.net:8088"
cmd_help = "\n\tUsage:\n\t" + os.path.basename(__file__) + ' -n <NextRelease> -c <CurrentRelease>\n'

# Validate argv parameters and update the global variables
ArgValidator(sys.argv[1:])
data = [
    {
        "api_path": "/api/releases",
        "method": "POST",
        "payload": {
		    "name": upcoming_release.lower(),
		    "isdefault": True,
		    "hasdeployments": True,
		    "hasbuilds": True,
		    "isvalid": True,
		    "displayname": upcoming_release.upper()
		}
    },
	{
		"api_path": "/api/releases",
        "method": "PUT",
        "payload": {
		    "name": current_release.lower(),
		    "isvalid": False
		}
	},
	{
		"api_path": "/api/jobconfigures/" + upcoming_release.lower(),
        "method": "POST",
        "payload": {
		    "joburl": "http://mydtbld0211.swinfra.net:8080/job/UFT.Build",
		    "jobname": "UFT.Build",
		    "describename": "UFT Nightly",
		    "tablename": "qtpnightly",
		    "group": "FT",
		    "product": "QTP",
		    "serveraddress": "http://mydtbld0211.swinfra.net:8080",
		    "isvalid": True,
		    "condition": [
		    	{ "name": "Type", "value": "Nightly" },
		        { "name": "BuildLabel", "value": upcoming_release.upper() },
		        { "name": "Configuration", "value": "win32_release" }
		    ],
		    
			"description": "The Nightly builds of " + upcoming_release.upper()
		}
	},
	{
		"api_path": "/api/jobconfigures/" + upcoming_release.lower(),
        "method": "POST",
        "payload": {
		        "joburl": "http://mydtbld0211.swinfra.net:8080/job/UFT.Build",
		        "jobname": "UFT.Build",
		        "describename": "UFT CI",
		        "tablename": "qtpci",
		        "group": "FT",
		        "product": "QTP",
		        "serveraddress": "http://mydtbld0211.swinfra.net:8080",
		        "isvalid": True,
		        "condition": [
		            {
		                "name": "Type",
		                "value": "CI"
		            },
		            {
		                "name": "BuildLabel",
		                "value": upcoming_release.upper() + "_For_Dev"
		            },
		            {
		                "name": "Configuration",
		                "value": "win32_release"
		            }
		        ],
		        "description": "The CI builds of " + upcoming_release.upper()
		}

	},
	{
		"api_path": "/api/jobconfigures/" + upcoming_release.lower(),
        "method": "POST",
        "payload": {
		        "joburl": "http://mydtbld0211.swinfra.net:8080/job/UFTBase.Build",
		        "jobname": "UFTBase.Build",
		        "describename": "UFTBase Release",
		        "tablename": "uftbaserelease",
		        "group": "FT",
		        "product": "UFTBase",
		        "serveraddress": "http://mydtbld0211.swinfra.net:8080",
		        "isvalid": True,
		        "condition": [
		            {
		                "name": "BuildLabel",
		                "value": upcoming_release.upper()
		            },
		            {
		                "name": "Configuration",
		                "value": "win32_release"
		            }
		        ],
		        "description": "The UFTBase release builds of " + upcoming_release.upper()
		}
	},
	{
		"api_path": "/api/jobconfigures/" + upcoming_release.lower(),
       	"method": "POST",
       	"payload":  {
	        "joburl": "http://mydtbld0211.swinfra.net:8080/job/ST.Build",
	        "jobname": "ST.Build",
	        "describename": "ST Release",
	        "tablename": "strelease",
	        "group": "ST",
	        "product": "ST",
	        "serveraddress": "http://mydtbld0211.swinfra.net:8080",
	        "isvalid": True,
	        "condition": [
		        {
	                "name": "BuildLabel",
	                "value": upcoming_release.upper()
		        },
		        {
		            "name": "Configuration",
		            "value": "win32_release"
		        }
		    ],
		   "description": "The ST release builds of  " + upcoming_release.upper()
		        
		}

	}
]


print("Next Release: " + upcoming_release)
print("Current Release: " + current_release)

# for d in data:
# 	d["url"] = HOST_URL + d["api_path"]
# 	res = SendRequest(d["url"], d["method"], d["payload"])
# 	print(res.json())
# 	print("{0} | {1} | {2}".format(d["method"], d["url"], res.status_code))


for d in data:
	d["url"] = HOST_URL + d["api_path"]
	if os.environ["Dry_Run"] == "true":
		res = SendRequest(d["url"], d["method"], d["payload"])
		print("{0} | {1} | {2}".format(d["method"], d["url"], res.status_code))
	else:
		print(d)
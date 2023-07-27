import yaml
import random  
import string
import os
import sys


def readfile(filename, mode="r"):
    try:
        
        with open(filename, mode) as file:
            return file.read()
        
    except Exception as e:
        print("An exception raised while processing '{0}' file".format(filename))
        print(e)
        return ""  

def readyamlfile(filename, mode="r"):
    try:

        return yaml.load(readfile(filename, mode), Loader=yaml.FullLoader)

    except Exception as e:

        print("An exception raise while processing yaml '{0}' file".format(filename))
        print(e)
        return ""

def getRandomString(length=5):

    return ''.join((random.choice(string.ascii_lowercase) for x in range(length)))

def writefile(filename, content, mode='w'):
    try:

        with open(filename, mode) as file:
            file.write(content)

    except Exception as e:
        print("An exception raised while writing '{0}' file".format(filename))
        print(e) 

# **************************************************
#                Main Program
# **************************************************

args = sys.argv
if len(args) <= 1:

    print("'DATA_FILE' argument is missing! Make sure the argument pass in the command line argument")
    sys.exit(-1)

DATA_FILE = args[1].strip()
if DATA_FILE == "":

    print("First argument cannot be empty!")
    sys.exit(-1)

# Read yaml file and generate a single txt file from deploy config array
scan_configs = readyamlfile(DATA_FILE)
if scan_configs == "":

    print("'{0}' file is empty!.".format(DATA_FILE))
    sys.exit(-1) 

# Get config and write a txt file
for config in scan_configs:
    
    text = ""
    for k in config.keys():
        if k == "filename":
            text += "%s=%s\n" % (k, config[k]  + ".zip")
        else:
            text += "%s=%s\n" % (k, config[k])

    filename = "scan-ga-release_%s.txt" % (getRandomString())
    writefile(filename, text)


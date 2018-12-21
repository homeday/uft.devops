#######################################################################################
# The script is for capturing the data from Jenkins
# And store the data to postgreSQL
# prequisites
# sudo pip install
# usage
# python main.py  \
#   -a <the api address> \
#   -d <the mydastr01 address which store the submission infomation>
#######################################################################################

import argparse 
import logging
import os, getopt, sys, time
import re
import xml.etree.ElementTree as ET
from os import walk
import shutil

def handleXml(xmlDir, filesbasedir, dstbasedir):
    root = ET.parse(xmlDir)
    products = root.findall(".//*[@name='LT-TPS']")
    aryextension = []
    for product in products:
        comps = product.findall("./comp")
        comps = [comp for comp in comps if comp.attrib['name'].find('qc4tools') == -1 and comp.attrib['name'].find('iHP_') == -1]
        for comp in comps:
            files = comp.findall("./files/file")
            for file in files:
                trg = file.attrib['trg']
                if trg[0] == '\\':
                    trg = trg[1:]
                try:
                    filesrcpath = ""
                    filedstpath = ""
                    if 'gac' in file.attrib and file.attrib['gac'] == 'true':
                        filesrcpath = os.path.join(filesbasedir, 'GlobalAssemblyCache', trg)    
                        filedstpath = os.path.join(dstbasedir, 'GlobalAssemblyCache', trg)
                    elif 'windir\system64' in trg:
                        filesrcpath = os.path.join(filesbasedir, 'System64Folder', trg.replace('windir\\system64\\', ''))    
                        filedstpath = os.path.join(dstbasedir,  'System64Folder', trg.replace('windir\\system64\\', ''))    
                    elif 'windir\system32' in trg:
                        filesrcpath = os.path.join(filesbasedir, 'SystemFolder', trg.replace('windir\\system32\\', ''))
                        filedstpath = os.path.join(dstbasedir,  'SystemFolder', trg.replace('windir\\system32\\', ''))   
                    else:
                        filesrcpath = os.path.join(filesbasedir, 'TARGETDIR', trg)    
                        filedstpath = os.path.join(dstbasedir, 'TARGETDIR', trg)   
                    os.makedirs(os.path.dirname(filedstpath), exist_ok=True)
                    shutil.copy(filesrcpath, filedstpath)
                    #filename, file_extension = os.path.splitext(filesrcpath)

                    #if not file_extension in aryextension:
                        #aryextension.append(file_extension)
                except:
                    logging.error("handle file error {0}".format(sys.exc_info()[1]))
                #print(filesrcpath)

    #print(aryextension)
            
    
def main(argv):
    buildreportsfolder=''
    try:
        buildreportsfolder = os.path.join(argv.mydanas, 'FT', 'QTP', 'win32_release', argv.version, 'build', 'reports')
        filesbasedir = os.path.join(argv.mydanas, 'FT', 'QTP', 'win32_release', argv.version, 'SetupBuilder', 'Output', 'UFT', 'Content', 'Win32')
        cwd = os.getcwd()
        dstbasedir = os.path.join(cwd, "result")
        logging.info("the build reports folder is {0}".format(buildreportsfolder))
        regex = re.compile(r'prd_files_UFT_install_(.*).xml')
        if not os.path.isdir(buildreportsfolder):
            logging.info("the build reports folder doesn't exist {0}".format(buildreportsfolder))
            return
        (_, _, filenames) = next(walk(buildreportsfolder))
        for filename in filenames:
            if regex.match(filename):
                xmlDir = os.path.join(buildreportsfolder, filename)
                handleXml(xmlDir, filesbasedir, dstbasedir)
                shutil.make_archive("uft3rdparty", 'zip', dstbasedir)
                break
    except:
        logging.error("Error in handling the releases {0}".format(sys.exc_info()[1]))
   
    
   


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='The script is for collecting 3rd party files of UFT'
    )
    parser.add_argument("-m", "--mydanas", metavar="arg", help='the address of mydanas01', default='\\mydanas01.swinfra.net')
    parser.add_argument("-v", "--version", metavar="arg", help='the version of UFT', default='UFT_14_52_Setup_Last')
    
    argv = parser.parse_args()
    main(argv)
    









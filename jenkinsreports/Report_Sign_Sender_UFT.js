

var signReport = {

    objMessage : new ActiveXObject("CDO.Message"),

    objFSO : new ActiveXObject("Scripting.FileSystemObject"),
    
    rubiconPath : "\\\\mydastr01.hpeswlab.net\\products\\FT\\",

    //rubiconPath:"D:\\products\\FT\\",

    //rubiconPath:"E:\\FT\\",

    opHtmlRpt : "DevOps_Info.html",

    objHtmlRpt : null,

    buildNumber : 0,

    repositoryName :  "QTP",

    buildlogPath : "",

    buildReportPath : "",

    mailList : "",

    rootPath : "",

    signMethodName : "CodeSign",

    sendmail : function() {
        
        var path = this.buildReportPath + this.opHtmlRpt;
        var fileContent = "No report was genertated!!";
        if ( this.objFSO.FileExists(path) ) {
            fileContent = this.objFSO.OpenTextFile(path).ReadAll();
        }

        this.objMessage.From = "uft.dev.ops@microfocus.com"; 
        this.objMessage.To = this.mailList; 


        /*if ( fileContent.indexOf("Failed") >= 0) {
            this.objMessage.Subject = "UFT [" + this.buildNumber + "] Code Sign Failed"; 	
        }
        else {
            this.objMessage.Subject = "UFT [" + this.buildNumber + "] Code Sign Passed"; 	
        }*/
        if ( this.repositoryName == "QTP")
            this.objMessage.Subject = "UFT [" + this.buildNumber + "] Dev-Ops Report"; 	
        else 
            this.objMessage.Subject = this.repositoryName + " [" + this.buildNumber + "] Dev-Ops Report"; 	
        this.objMessage.HTMLBody = fileContent; 


        var namespace = "http://schemas.microsoft.com/cdo/configuration/";

        this.objMessage.Configuration.Fields.Item(namespace + "sendusing") = 2;

        this.objMessage.Configuration.Fields.Item(namespace + "smtpserver") = "smtp3.hpe.com";
        this.objMessage.Configuration.Fields.Item(namespace + "smtpserverport") = 25;


            
        this.objMessage.Configuration.Fields.Update();
        WScript.Echo("try to send mail!");
        this.objMessage.Send()
        WScript.Echo("Mail was sent successfully to:" + this.objMessage.To);
    },

    createHead : function () {
        var path = this.buildReportPath + this.opHtmlRpt;
        if ( this.objFSO.FileExists(path) ) {
            this.objFSO.DeleteFile(path)
        }

        this.objHtmlRpt = this.objFSO.CreateTextFile(path,true);
        this.objHtmlRpt.WriteLine("<html><head>");
        this.objHtmlRpt.WriteLine("<meta http-equiv='content-type' content='text/html; charset=ISO-8859-1'>");
        this.objHtmlRpt.WriteLine("<STYLE type='text/css'>");
        this.objHtmlRpt.WriteLine("fieldset");
        this.objHtmlRpt.WriteLine("{");
        this.objHtmlRpt.WriteLine("position: relative;");
        this.objHtmlRpt.WriteLine("border: 2px solid black;");
        this.objHtmlRpt.WriteLine("position: relative;");
        this.objHtmlRpt.WriteLine("}");
        this.objHtmlRpt.WriteLine("</STYLE>");
        this.objHtmlRpt.WriteLine("</head><body>");

    },

    createFooter : function() {

        this.objHtmlRpt.WriteLine("</body>");
        this.objHtmlRpt.WriteLine("</html>");
        this.objHtmlRpt.Close();

    },

    generateVersionRpt : function () {

        var logPath = this.buildlogPath  + "Generate_Version_Files.log";
        if (!this.objFSO.FileExists(logPath))
            return;

        var logFile = this.objFSO.OpenTextFile(logPath);
        var resGood = true;

        var ErrLength = "[ERROR]".length;
        while( !logFile.AtEndOfStream ) {
            var logLine = logFile.ReadLine();
            var index = -1;
            var incorrectPath = "";
            if ( 0 <= (index = logLine.indexOf("[ERROR]"))) {
                index += ErrLength;
                incorrectPath = logLine.substring(index, logLine.length);
                if (resGood) {
                    this.objHtmlRpt.WriteLine("<h4 style='font-family:Calibri'>Version Check Status <font color='red'><b>Failed</b></font></h4>");
                    this.objHtmlRpt.WriteLine("<table style='font-family:Calibri; font-size:14px' cellpadding='0' cellspacing='0' border='1'>");

                    this.objHtmlRpt.WriteLine("<tbody>");
                    this.objHtmlRpt.WriteLine("<tr style='font-size:14px; width:100%;' bgcolor='silver' >");
                    
                    this.objHtmlRpt.WriteLine("<th style='padding:2px'><b>File Name</b></th>");
                    this.objHtmlRpt.WriteLine("<th style='padding:2px'><b>Version</b></th>");
                    this.objHtmlRpt.WriteLine("</tr>");
                }
                resGood = false;
                incorrectPath = incorrectPath.split("|");
                if ( incorrectPath.length >= 2) {
                    this.objHtmlRpt.WriteLine("<tr style='font-size:14px; width:100%'>");
                    this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'>" + incorrectPath[1] + "</td>");
                    this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'>" + incorrectPath[0] + "</td>");
                    this.objHtmlRpt.WriteLine("</tr>");
                }
            }
        }
        if (resGood) {
            this.objHtmlRpt.WriteLine("<h4 style='font-family:Calibri'>Version Check Status <font color='green'><b>Passed</b></font></h4>");
        }
        else {
            this.objHtmlRpt.WriteLine("</tbody>");
            this.objHtmlRpt.WriteLine("</table>");
        }

        logFile.Close();

    },

    generateReport : function () {

        this.createHead();

        this.generateSignRpt();

        this.generateVersionRpt();

        this.createFooter();
    },
    generateSignRpt  : function() {

        
        this.objHtmlRpt.WriteLine("<h4 style='font-family:Calibri'>Sign Files Status (Summary of " + this.signMethodName + " Logs)</h4>");
        this.objHtmlRpt.WriteLine("<table style='font-family:Calibri; font-size:14px' cellpadding='0' cellspacing='0' border='1'>");
        this.objHtmlRpt.WriteLine("<tbody>");
        this.objHtmlRpt.WriteLine("<tr style='font-size:14px; width:100%;' bgcolor='silver' >");
        
        this.objHtmlRpt.WriteLine("<th style='padding:2px'><b>Project Name</b></th>");
        this.objHtmlRpt.WriteLine("<th style='padding:2px'><b>Sign Tool</b></th>");
        this.objHtmlRpt.WriteLine("<th style='padding:2px'><b>Status</b></th>");
        this.objHtmlRpt.WriteLine("<th style='padding:2px'><b>Unsigned File List</b></th>");
        this.objHtmlRpt.WriteLine("</tr>");
        var prefixCS = "File failed to verify".length + 1;
        var prefixVB = "ERROR: Not Signed".length + 1;
        var FoundSigningLogFile = false;


        //////////////////////////// FOR AUJAS ////////////////////////////////////
        // try to find AUJAS logs by enumerate all sub directories
        var aujasSignTool = "AUJAS";
        var aujasIndicatorLowerCase = "_aujas";
        var subdirs = new Enumerator(this.objFSO.GetFolder(this.buildlogPath).SubFolders);
        for (; !subdirs.atEnd(); subdirs.moveNext()) {
            var subdir = subdirs.item();
            var subdirName = subdir.Name;
            var indicatorStartIndex = subdirName.toLowerCase().indexOf(aujasIndicatorLowerCase);
            if (indicatorStartIndex >= 0) {
                FoundSigningLogFile = true;
                this.objHtmlRpt.WriteLine("<tr style='font-size:14px; width:100%'>");

                // project name
                // example: 1009-Before_AUJAS
                var projName = "default";
                if (indicatorStartIndex > 0) {
                    projName = subdirName.substring(0, indicatorStartIndex);
                    var i = 0;
                    if ( 0 < ( i = projName.indexOf('-') ) && !isNaN(projName.substring(0, i)) ) {
                        projName = projName.substr(i + 1);		
                    }
                }

                this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'>" + projName + "</td>");
                this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'>" + aujasSignTool + "</td>");

                // status & unsigned file list
                var filesNotConfirmed = [];
                var filesNotSigned = [];
                var files = new Enumerator(this.objFSO.GetFolder(subdir).Files);
                for (; !files.atEnd(); files.moveNext()) {
                    var file = files.item();
                    var fileName = file.Name;

                    var list = [];
                    if (fileName.toLowerCase().indexOf("files_not_confirmed-") >= 0) {
                        list = filesNotConfirmed;
                    }
                    else if (fileName.toLowerCase().indexOf("files_not_signed-") >= 0) {
                        list = filesNotSigned;
                    }
                    else {
                        continue;
                    }

                    var fObj = this.objFSO.OpenTextFile(file);
                    while( !fObj.AtEndOfStream ) {
                        var fLine = fObj.ReadLine();
                        if (fLine) {
                            // example: E:/FT\QTP\win32_release\14.0.1009.77_clean\SetupBuilder\Output\UFT\Content\Win32\TARGETDIR\bin\HP.Utt.View.dll
                            var fLineOri = fLine;
                            var str = "\\targetdir\\";
                            var i = fLineOri.toLowerCase().indexOf(str);
                            if (i >= 0) {
                                fLine = fLineOri.substr(i + str.length);
                            }
                            if (!fLine) {
                                i = fLineOri.toLowerCase().indexOf(this.buildNumber);
                                if (i >= 0) {
                                    fLine = fLineOri.substr(i);
                                }
                            }
                            if (!fLine) {
                                fLine = fLineOri;
                            }
                            list.push(fLine);
                        }
                    }
                    fObj.Close();
                }
                if ( filesNotConfirmed.length == 0 && filesNotSigned.length == 0 ) {
                    // no error
                    this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'><b style='color:green;'>Passed</b></td>");
                    this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'></td>");
                } else {
                    if (filesNotSigned.length > 0) // has error
                        this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'><b style='color:red;'>Failed</b></td>");
                    else // has warning
                        this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'><b style='color:orange;'>Warning</b></td>");
                    
                    this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'>");
                    if (filesNotSigned.length > 0) {
                        this.objHtmlRpt.WriteLine("<p><b>-- Not Signed (" + filesNotSigned.length + ") --</b><br/>");
                        this.objHtmlRpt.WriteLine(filesNotSigned.join("<br/>"));
                        this.objHtmlRpt.WriteLine("</p>");
                    }
                    else if (filesNotConfirmed.length > 0) {
                        this.objHtmlRpt.WriteLine("<p><b>-- Not Confirmed (" + filesNotConfirmed.length + ") --</b><br/>");
                        this.objHtmlRpt.WriteLine(filesNotConfirmed.join("<br/>"));
                        this.objHtmlRpt.WriteLine("</p>");
                    }
                    this.objHtmlRpt.WriteLine("</td>");
                }
                this.objHtmlRpt.WriteLine("</tr>");
            }
        }
        

        //////////////////////////// FOR SignHP ////////////////////////////////////
        // try to find SignHP logs by enumerate all sub directories
        var signHPSignTool = "SignHP";
        var signHPIndicatorLowerCase = "_signhp";
        var subdirs = new Enumerator(this.objFSO.GetFolder(this.buildlogPath).SubFolders);
        for (; !subdirs.atEnd(); subdirs.moveNext()) {
            var subdir = subdirs.item();
            var subdirName = subdir.Name;
            var indicatorStartIndex = subdirName.toLowerCase().indexOf(signHPIndicatorLowerCase);
            if (indicatorStartIndex >= 0) {
                FoundSigningLogFile = true;
                this.objHtmlRpt.WriteLine("<tr style='font-size:14px; width:100%'>");

                // project name
                // example: 1009-Before_MSI_SignHP
                var projName = "default";
                if (indicatorStartIndex > 0) {
                    projName = subdirName.substring(0, indicatorStartIndex);
                    var i = 0;
                    if ( 0 < ( i = projName.indexOf('-') ) && !isNaN(projName.substring(0, i)) ) {
                        projName = projName.substr(i + 1);		
                    }
                }

                this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'>" + projName + "</td>");
                this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'>" + signHPSignTool + "</td>");

                // status & unsigned file list
                var filesNotConfirmed = [];
                var filesNotSigned = [];
                var files = new Enumerator(this.objFSO.GetFolder(subdir).Files);
                for (; !files.atEnd(); files.moveNext()) {
                    var file = files.item();
                    var fileName = file.Name;

                    var list = [];
                    if (fileName.toLowerCase().indexOf("files_not_confirmed-") >= 0) {
                        list = filesNotConfirmed;
                    }
                    else if (fileName.toLowerCase().indexOf("files_not_signed-") >= 0) {
                        list = filesNotSigned;
                    }
                    else {
                        continue;
                    }

                    var fObj = this.objFSO.OpenTextFile(file);
                    while( !fObj.AtEndOfStream ) {
                        var fLine = fObj.ReadLine();
                        if (fLine) {
                            // example: E:/FT\QTP\win32_release\14.0.1009.77_clean\SetupBuilder\Output\UFT\Content\Win32\TARGETDIR\bin\HP.Utt.View.dll
                            var fLineOri = fLine;
                            var str = "\\targetdir\\";
                            var i = fLineOri.toLowerCase().indexOf(str);
                            if (i >= 0) {
                                fLine = fLineOri.substr(i + str.length);
                            }
                            if (!fLine) {
                                i = fLineOri.toLowerCase().indexOf(this.buildNumber);
                                if (i >= 0) {
                                    fLine = fLineOri.substr(i);
                                }
                            }
                            if (!fLine) {
                                fLine = fLineOri;
                            }
                            list.push(fLine);
                        }
                    }
                    fObj.Close();
                }
                if ( filesNotConfirmed.length == 0 && filesNotSigned.length == 0 ) {
                    // no error
                    this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'><b style='color:green;'>Passed</b></td>");
                    this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'></td>");
                } else {
                    if (filesNotSigned.length > 0) // has error
                        this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'><b style='color:red;'>Failed</b></td>");
                    else // has warning
                        this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'><b style='color:orange;'>Warning</b></td>");
                    
                    this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'>");
                    if (filesNotSigned.length > 0) {
                        this.objHtmlRpt.WriteLine("<p><b>-- Not Signed (" + filesNotSigned.length + ") --</b><br/>");
                        this.objHtmlRpt.WriteLine(filesNotSigned.join("<br/>"));
                        this.objHtmlRpt.WriteLine("</p>");
                    }
                    else if (filesNotConfirmed.length > 0) {
                        this.objHtmlRpt.WriteLine("<p><b>-- Not Confirmed (" + filesNotConfirmed.length + ") --</b><br/>");
                        this.objHtmlRpt.WriteLine(filesNotConfirmed.join("<br/>"));
                        this.objHtmlRpt.WriteLine("</p>");
                    }
                    this.objHtmlRpt.WriteLine("</td>");
                }
                this.objHtmlRpt.WriteLine("</tr>");
            }
        }
        

        //////////////////////////// FOR HPCSS ////////////////////////////////////
        // try to find code sign logs by enumerate all files
        var hpcssSignTool = "HPCSS";
        var hpcssIndicatorLowerCase = "_codesign";
        var files = new Enumerator(this.objFSO.GetFolder(this.buildlogPath).Files);
        for (; !files.atEnd(); files.moveNext()) {
            //s += files.item();
            //s += "<br />";
            var file = files.item();
            var fileName = file.name;
            var projName = "";
            if ( /*fileName.substr(fileName.length - 3,3).toLowerCase() == "txt" &&*/ fileName.toLowerCase().indexOf(hpcssIndicatorLowerCase) >= 0) {

                FoundSigningLogFile = true
                this.objHtmlRpt.WriteLine("<tr style='font-size:14px; width:100%'>");
                var s = /.txt/g;
                var s2 = /\"/g;
                
                var is = isNaN("ab");
                var is2 = isNaN("12");
                projName = fileName.replace(s,"");
                var i = 0;
                if ( 0 <= ( i = projName.indexOf('-') ) && !isNaN(projName.substr(0, i)) ) {
                    projName = projName.substring( i + 1, projName.length);		
                }

                this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'>" + projName + "</td>");
                this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'>" + hpcssSignTool + "</td>");

                var logFile = this.objFSO.OpenTextFile(file);
                var passed = true;
                var writeResult = false;
                while( !logFile.AtEndOfStream ) {
                    var logLine = logFile.ReadLine();
                    //C# App log
                    var index = -1;
                    var unsignPath = "";
                    
                       if ( logLine.indexOf("[ERROR]") >= 0 && 0 <= (index = logLine.indexOf("File failed to verify"))) {
                           //get filepath
                           unsignPath = logLine.substring(index + prefixCS, logLine.length);
                           passed = false;
                           WScript.Echo(unsignPath);
                           if ( writeResult ) {
                               this.objHtmlRpt.WriteLine("<br>" + unsignPath);
                           }
                        // c# in case the sign server was down and no file was signed
                       } else if ( logLine.indexOf("Sign Server seems down") >= 1) {
                        unsignPath = "ERROR: Sign Server seems down.\n None of the files were signed";
                        passed = false;
                        WScript.Echo(logLine);
                        if ( writeResult ) {
                               this.objHtmlRpt.WriteLine("<br>" + logLine);
                           }
                    }
                    //VB Script Log 
                       else if ( 0 <= (index = logLine.indexOf("ERROR: Not Signed"))){ 
                        //get filepath

                           unsignPath = logLine.substring(index + prefixVB, logLine.length).replace(s2, "");
                           WScript.Echo(unsignPath);
                           passed = false;
                           if ( writeResult ) {
                               this.objHtmlRpt.WriteLine("<br>" + unsignPath);
                           }
                    }

                    if ( !writeResult && !passed) {
                        this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'><b style='color:red;'>Failed</b></td>");
                        this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'>" + unsignPath);
                        writeResult = true;
                    }
                }
                logFile.Close();
                if ( passed ) {
                    this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'><b style='color:green;'>Passed</b></td>");
                    this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'></td>");
                } else {
                    this.objHtmlRpt.WriteLine("</td>");
                }
                this.objHtmlRpt.WriteLine("</tr>");
                
               }
        
        }
        
        this.objHtmlRpt.WriteLine("</tbody>");
        this.objHtmlRpt.WriteLine("</table>");
        if (!FoundSigningLogFile) {
            this.objHtmlRpt.WriteLine("<td valign='top' style='padding:2px'><b style='color:red;'>No SignHP/CodeSign logs were found in this build!</b></td>");
        }
        
    },

    init : function () {
        var objArgs = WScript.Arguments;
        if ( objArgs.length < 3 )
            return false;

        this.buildNumber = objArgs(0);
        this.repositoryName = objArgs(1);
        this.rootPath = objArgs(1);
        this.mailList = objArgs(2);
        if ( objArgs.length >= 4 )
            this.signMethodName = objArgs(3);

        var pathExist = false;
        this.rootPath += "\\build";
        if (this.objFSO.FolderExists(this.rootPath)) {
            this.buildReportPath = this.rootPath;
            this.buildlogPath = this.rootPath + "\\logs\\";
            this.repositoryName = "UFT";
            pathExist = true;
        } else {
            var path = this.rubiconPath + this.repositoryName + "\\win32_release\\" + this.buildNumber + "\\build";
            if ( this.objFSO.FolderExists(path)) {
                this.buildReportPath = path + "\\reports\\";
                this.buildlogPath = path + "\\logs\\";
                pathExist = true;
            } else {
                path = this.rubiconPath +  this.repositoryName + "\\win32_debug\\" + this.buildNumber + "\\build";
                if ( this.objFSO.FolderExists(path)) {
                    this.buildReportPath = path + "\\reports\\";
                    this.buildlogPath = path + "\\logs\\";
                    pathExist = true;
                }
            }

        }
        

        

        
        WScript.Echo("Path of build log : " + this.buildlogPath);
        return pathExist;

    },
    doWork : function() {
        
        if (!this.init())
            return;

        this.generateReport();
        
        this.sendmail();
    }
};


( function() {
    signReport.doWork();
} )();

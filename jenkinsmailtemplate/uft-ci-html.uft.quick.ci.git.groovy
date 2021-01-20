<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
        <head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><title></title></head>
        <style type="text/css">
                /* Client-specific Styles */
                #outlook a {padding:0;}
                body{
                        width:100% !important;
                        -webkit-text-size-adjust:100%;
                        -ms-text-size-adjust:100%;
                        margin:0;
                        padding:5;
                        font-family:Century
                }
                /* Hotmail */
                a:active, a:visited, a[href^="tel"], a[href^="sms"] { text-decoration: none; color: #000001 !important; pointer-events: auto; cursor: default;}
                table { margin-top: 10px; }
                table td {valign: top; margin:4px}
                .SUCCESS {color: Green;}
                .FAILURE {color: Red;}
                .UNSTABLE {color: Yellow;}
                .shadow {border-radius: 5px; box-shadow: 1px 1px 1px 1px darkgray; }
                .build_detail_td { width:25%;}
          </style>

        <body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" style="margin: 0px; padding: 0px; background-color: #e2e2e2;" bgcolor="#e2e2e2">
                <%
                        import hudson.model.*
                        import com.tikal.jenkins.plugins.multijob.*;
                        import groovy.transform.Field
                        // To fetch build logs
                        import hudson.console.ConsoleNote

                        def env = build.getEnvironment()
                        def build_status_icon = env.JENKINS_URL + "static/ad512159/images/32x32/" + ((build.result.toString() == "SUCCESS") ? "blue.png" : (build.result.toString() == "FAILURE") ? "red.png" : "yellow.png")
                        def icon_base64=new URL("${build_status_icon}").getBytes( useCaches: true, allowUserInteraction: false, requestProperties: ["User-Agent": "Groovy Sample Script"])
                        //def cartoon_url = env.JENKINS_URL + "static/ad512159/images/" + ((build.result.toString() == "SUCCESS") ? "happy_duck.png" : "sad_duck.png")
                        //def image_cartoon=new URL("${cartoon_url}").getBytes( useCaches: true, allowUserInteraction: false, requestProperties: ["User-Agent": "Groovy Sample Script"])

                        def getEncodedImage(URL url){
                                def byteCode = url.getBytes( useCaches: true, allowUserInteraction: false, requestProperties: ["User-Agent": "Groovy script"])
                                return byteCode.encodeBase64().toString()
                        }
                        def getGitEncodedImage(authorName){
                                authorName = java.net.URLEncoder.encode(authorName, "UTF-8")
                                return getEncodedImage(new URL("https://avatars.github.houston.softwaregrp.net/" + authorName + "?size=100"))
                        }

                        // Get repositories from XML files
                        def getRepositories(buildName, xmlFileName){
                                List repositories = []

                                if(buildName != null && buildName.getParent().getWorkspace().child(xmlFileName).exists()){
                                        def report = new XmlParser().parseText(buildName.getWorkspace().child(xmlFileName).readToString())
                                        repositories = report.Repository
                                }

                                return repositories
                        }


                        //Compilation Build
                        Build CompilationBuild;

                        build.getBuilders().each {
                          subBuild ->
                                //get sub build's project
                                subProject = hudson.model.Hudson.instance.getItem(subBuild.getJobName())
                                //get sub build
                                RealsubBuild = subProject.getBuildByNumber(subBuild.getBuildNumber())

                                if (subProject.getName().indexOf('UFT.Quick.CI.Compile') >= 0) {
                                  CompilationBuild = RealsubBuild
                                }
                        }

                        def ProjectName= (build.getProject().name) ?: ""
                        def Type = env.Type ?: "Nightly"
                        def JobUrl = "${env.JENKINS_URL} + ${build.url}"
                        def Duration = build.durationString
                        def Branch = CompilationBuild.getEnvironment().Configuration
                        def ServerName = (build.getBuiltOn().getDisplayName()) ?: ""
                        def Configuration = (env.Configuration) ?: ""


                        // For fatch build failure
                        class FailureBuildfinder {

                          def failureBuildName = null

                          def ExceptionString = null

                          def rootbuild = null

                          def rootbuildName = null

                          def FailureBuildfinder() {}

                          static def isAfailureBuild(def buildobj) {
                                if ( buildobj == null) return false
                                return hudson.model.Result.FAILURE == buildobj.result || hudson.model.Result.UNSTABLE ==  buildobj.result
                          }

                          def getFailureBuild(def buildjob) {
                                failureBuildName = null
                                rootbuild = buildjob
                                rootbuildName = buildjob == null ? "" : buildjob.getParent().getName()

                                return searchFailureBuild(buildjob)
                          }
                          def searchFailureBuild(def buildjob) {

                                def failureBuild = buildjob
                                try {

                                  if (!isAfailureBuild(buildjob))
                                        return null

                                  if ( null == failureBuildName ) {
                                        def buildName = buildjob.getParent().getName()
                                        if (!buildName.equals(rootbuildName))
                                          failureBuildName = buildName
                                  }

                                  if (buildjob instanceof com.tikal.jenkins.plugins.multijob.MultiJobBuild  ) {
                                        failureBuild = searchFailureMultiBuild(buildjob)
                                  }
                                  else if (buildjob instanceof hudson.model.FreeStyleBuild  ) {
                                        failureBuild = searchFailurefreeStyleBuild(buildjob)
                                  } else {
                                        failureBuild = searchFailureotherStyleBuild(failureBuild)
                                  }
                                }
                                catch (Exception e) {
                                  if ( null == ExceptionString)
                                        ExceptionString = e.getMessage()
                                  return null
                                }
                                return failureBuild == null ? buildjob : failureBuild
                          }

                          ///this method is just used to search the failure freestyle job
                          def searchFailureBuildWithConsoleLog(def buildjob) {
                                def failureBuild = null
                                def triggersBuilder = buildjob.getProject().getBuilders()
                                def hasTrigger = false

                                for(def trigger : triggersBuilder) {
                                  if(trigger instanceof hudson.plugins.parameterizedtrigger.TriggerBuilder) {
                                        def configs = trigger.getConfigs()
                                        for(def config : configs) {
                                          if (config.getBlock() != null) {
                                                hasTrigger = true
                                          }
                                        }
                                  }
                                }

                                if (hasTrigger) {
                                  //Scan the console log
                                  def reader = buildjob.getLogReader()
                                  BufferedReader bufferedReader = new BufferedReader(reader);
                                  for (def line = bufferedReader.readLine(); line != null; line = bufferedReader.readLine()) {
                                        line = ConsoleNote.removeNotes(line);
                                        def matcher = line=~/(.*) #(\d+) completed. Result was FAILURE/
                                        if(matcher){
                                          def innerBuild = matcher[0][1]
                                          def innerBuildNumber = Integer.parseInt(matcher[0][2])
                                          def foundBuild = hudson.model.Hudson.instance.getItem(innerBuild).getBuildByNumber(innerBuildNumber)
                                          failureBuild = searchFailureBuild(foundBuild)
                                          if ( null != failureBuild) {
                                                break
                                          }
                                        }
                                  }
                                  bufferedReader.close()

                                }
                                return failureBuild == null ? buildjob : failureBuild
                          }

                          def searchFailureMultiBuild(def buildjob) {
                                def failureBuild = null
                                def Builders = buildjob.getBuilders()
                                if (Builders.size() == 0 ) {
                                  failureBuild = searchFailureBuildWithConsoleLog(buildjob)
                                  return failureBuild == null ? buildjob : failureBuild
                                }

                                for(subBuild in Builders) {
                                  def subProject = hudson.model.Hudson.instance.getItem(subBuild.getJobName())
                                  def innerBuild = subProject.getBuildByNumber(subBuild.getBuildNumber())
                                  failureBuild = searchFailureBuild(innerBuild)
                                  if ( null != failureBuild) {
                                        break
                                  }
                                }

                                return failureBuild == null ? buildjob : failureBuild
                          }

                          def searchFailurefreeStyleBuild(def buildjob) {
                                buildjob = searchFailureBuildWithConsoleLog(buildjob)
                                return buildjob
                          }

                          def searchFailureotherStyleBuild(def buildjob) {
                                return buildjob
                          }

                        }


                %>
                <table width="100%" cellpadding="0" cellspacing="0"><tr><td valign="center"><tr><td>
                        <table style="background-color: #FFF" bgcolor="#FFF" class="shadow" width="80%" align="center" cellpadding="5" cellspacing="0">
                                <tr>
                                        <td>
                                                <!-- show image -->
                                                <table width="20%"  align="left" cellpadding="0" cellspacing="0">
                                                        <tr>
                                                                <td style="width:5%">
                                                                        <!--<img width="50" height="50" src="data:image/png;base64,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">-->
                                                                        <img src="data:image/png;base64, ${icon_base64.encodeBase64().toString()}" />
                                                                </td>
                                                        </tr>
                                                </table>
                                        </td>
                                </tr>
                                <tr>
                                        <td>
                                                <span><b>${Type} &nbsp;|&nbsp;Execution Time - ${Duration} </b></span>
                                                <table width="100%" align="left" cellpadding="0" cellspacing="0" style="border-top:1px solid #A8A8A8">
                                                        <tr>
                                                                <td class="build_detail_td">Build Version</td>
                                                                <td valign="top">${env.BuildVersion}</td>
                                                        </tr>
                                                        <tr>
                                                                <td class="build_detail_td">Project Name</td>
                                                                <td valign="top" >${ProjectName}</td>
                                                        </tr>
                                                        <% if (null != CompilationBuild) { %>
                                                                <tr>
                                                                        <td class="build_detail_td">Compilation Status</td>
                                                                        <td valign="top" class="${CompilationBuild.result.toString()}" >${CompilationBuild.result.toString()}</td>
                                                                </tr>
                                                        <% } %>
                                                        <tr>
                                                                <td class="build_detail_td">Job URL</td>
                                                                <td valign="top" ><a href="${JobUrl}">${ProjectName}</a></td>
                                                        </tr>
                                                        <tr>
                                                                <td class="build_detail_td">Branch</td>
                                                                <td valign="top">${Branch}</td>
                                                        </tr>
                                                        <tr>
                                                                <td class="build_detail_td">ServerName</td>
                                                                <td valign="top">${ServerName}</td>
                                                        </tr>
                                                        <tr>
                                                                <td class="build_detail_td">Configuration</td>
                                                                <td valign="top">${Configuration}</td>
                                                        </tr>
                                                </table>
                                                <br />
                                        </td>
                                </tr>
                                <tr>
                                        <td>
                                                <br />
                                                <br />
                                                <!-- Fatch repositories -->
                                                <table class="shadow" width="100%" style="border: 1px solid #e2e2e2" cellpadding="0" cellspacing="0">
                                                        <tr style="background-color: #A8A8A8" bgcolor="#A8A8A8" ><td><h3 style="color: White">Imported Repository List</h3></td></tr>
                                                        <tr><td>
                                                                <table width="100%" cellpadding="0" cellspacing="0">
                                                                        <%
                                                                          def report = null
                                                                          if( CompilationBuild != null && CompilationBuild.getParent().getWorkspace().child("build/reports/Imported_Repository_List.xml").exists()){
                                                                                report = new XmlParser().parseText(CompilationBuild.getWorkspace().child("build/reports/Imported_Repository_List.xml").readToString())
                                                                          }

                                                                          if ( null != report ) {
                                                                        %>
                                                                                <tr style="border-bottom: 1px solid #e2e2e2" >
                                                                                        <th align="left">Repository</th>
                                                                                        <th align="left">Configuration</th>
                                                                                        <th align="left">Group</th>
                                                                                        <th align="left">Build Id</th>
                                                                                        <th align="left">Branch</th>
                                                                                        <th align="left">Tag/Revision</th>
                                                                                </tr>

                                                                        <% report.Repository.each { it -> %>
                                                                            <tr>
                                                                                <td valign="top">${it.attribute('product')}</td>
                                                                                <td valign="top">${it.attribute('config')}</td>
                                                                                <td valign="top">${it.attribute('group')}</td>
                                                                                <td valign="top">
                                                                                        <a target="_blank" href="file:${env.PRODUCTS_STORAGE_WIN}\\${it.attribute('group')}\\${it.attribute('product')}\\${it.attribute('config')}\\${it.attribute('build')}">
                                                                                                ${it.attribute('build')}
                                                                                        </a>
                                                                                </td>
                                                                                <td valign="top">${it.attribute('svnbranch')}</td>
                                                                                <td valign="top">${it.attribute('svnrevision') ?: it.attribute('svntag')}</td>
                                                                            </tr>
                                                                        <% }
                                                                        }else {
                                                                        %>
                                                                        <tr><td><span>File 'build/reports/Imported_Repository_List.xml' not found.</span></td><tr>
                                                                        <% } %>
                                                                </table>
                                                        </td></tr>
                                                </table>
                                                <br />
                                                <br />
                                                <!-- Fatch repository end -->
                                        </td>
                                </tr>
                                <tr>
                                        <td>
                                                <!-- Console Logs -->
                                                <%
                                                if ( build.getEnvironment().BUILD_FAILURE == "Compilation Failed" ||  build.getEnvironment().BUILD_FAILURE == "CompilationFailed" ||  build.getEnvironment().BUILD_FAILURE == "BUILD Failed") {
                                                %>
                                                        <TABLE class="shadow" width="100%" style="border: 1px solid #e2e2e2" cellpadding="0" cellspacing="0">
                                                         <TR style="background-color: #A8A8A8" bgcolor="#A8A8A8"><TD><h3 style="color: White"Compilation Errors</h3></TD></TR>
                                                         <%
                                                                         def i=0
                                                                         build.getParent().getWorkspace().child("build/logs/MSBExe_Build.log").readToString().eachLine(){ line ->

                                                                                if ( line =~ /error / && !(line =~ /^  /) ){
                                                                                        i= i + 1
                                                        %>
                                                                                        <TR><TD class="console">${line}</TD></TR>
                                                        <%              }
                                                                        }
                                                        %>
                                                        <TR><TD class="console">Error(s) found: ${i}  <A href="${build.getEnvironment().rubicon_full_global_path}/build/logs/MSBExe_Build.log">(Full Log)</A></TD></TR>
                                                        </TABLE>
                                                        <BR/>

                                                <% } else if(build.result==hudson.model.Result.FAILURE || build.result==hudson.model.Result.UNSTABLE) { %>
                                                        <TABLE class="shadow" width="100%" style="border: 1px solid #e2e2e2" cellpadding="0" cellspacing="0">
                                                        <TR style="background-color: #A8A8A8" bgcolor="#A8A8A8"><TD><h3 style="color: White">Console Output</h3></TD></TR>
                                                        <%

                                                          FailureBuildfinder failureBuildfinder = new FailureBuildfinder()
                                                          def thefailureBuild = failureBuildfinder.getFailureBuild(CompilationBuild)

                                                          if (thefailureBuild != null) {
                                                        %>
                                                                <TR><TD class="console"> <h2 style="color:red">The step ${failureBuildfinder.failureBuildName} failed</h2></TD></TR>
                                                                <TR><TD class="console"> <A href="${rooturl}${thefailureBuild.getUrl()}consoleText">${rooturl}${thefailureBuild.getUrl()}consoleText</A></TD></TR>
                                                        <%
                                                                def reader = thefailureBuild.getLogReader()
                                                                def bufReader = new BufferedReader(reader)
                                                                def finderrline = false
                                                                def lineNumber = 0
                                                                def lineNumber2 = 0
                                                                for (def line = bufReader.readLine(); line != null; line = bufReader.readLine()) {
                                                                        ++lineNumber
                                                                        line = ConsoleNote.removeNotes(line)
                                                                        if (finderrline) {
                                                                                lineNumber2++
                                                                                if ( lineNumber2 > 15) break
                                                        %>
                                                                                <TR><TD class="console">${line}</TD></TR>
                                                        <%                      continue
                                                                        }
                                                                        if ( line =~ /error / && !(line =~ /^  /) ) {
                                                                                finderrline = true
                                                                                lineNumber2 = 1
                                                        %>
                                                                                <TR><TD class="console">${line}</TD></TR>
                                                        <%              }
                                                                }
                                                                bufReader.close()

                                                                if (!finderrline) {
                                                                        reader = thefailureBuild.getLogReader()
                                                                        bufReader = new BufferedReader(reader)
                                                                        for (def line = bufReader.readLine(); line != null; line = bufReader.readLine()) {
                                                                                if ( lineNumber <= 15) {
                                                                                        line = ConsoleNote.removeNotes(line)
                                                        %>
                                                                                        <TR><TD class="console">${line}</TD></TR>
                                                        <%                      }
                                                                                --lineNumber
                                                                        }
                                                                        bufReader.close()
                                                                }
                                                                if (failureBuildfinder.ExceptionString != null) {
                                                        %>
                                                                   <TR><TD class="console">${failureBuildfinder.ExceptionString}</TD></TR>
                                                        <%      }
                                                        %>

                                                        <%}%>
                                                        </TABLE>
                                                        <BR/>
                                                <% } %>

                                                <!-- Console Logs end -->
                                        </td>
                                </tr>
                                <tr>
                                        <td>
                                                <!-- Show GIT commit changes -->
                                                <table class="shadow" width="100%" style="border: 1px solid #e2e2e2" cellpadding="5" cellspacing="5">
                                                        <tr style="background-color: #A8A8A8" bgcolor="#A8A8A8" ><td><h3 style="color: White">GIT History</h3></td></tr>
                                                        <tr>
                                                                <td>
                                                                        <%
                                                                                def svnfile = null
                                                                                def gitfile = null
                                                                                def gitfiles = build.getWorkspace().list("Build_*_Git_Commits.xml")

                                                                                def repoName = ""
                                                                                gitfiles.each {
                                                                                        try {
                                                                                                repoName = it.getBaseName().replace("Build_", "").replace("_Git_Commits", "")
                                                                                                def repoUrl = "https://github.houston.softwaregrp.net/uft/${repoName}"
                                                                                                gitfile = it.readToString()

                                                                                                def committers1 = new XmlSlurper().parseText(gitfile)
                                                                                                if (committers1.logentry != null && committers1.logentry.size() > 0) {
                                                                        %>
                                                                                                        <table width="100%" style="border: 1px solid #e2e2e2" cellpadding="0" cellspacing="0">
                                                                                                                <tr><td colspan="4" style="border-bottom: 1px solid #e2e2e2"><b>- ${repoName} -</b></td></tr>
                                                                                                                <%
                                                                                                                        committers1.logentry.each { it2 ->
                                                                                                                                try {
                                                                                                                %>
                                                                                                                                        <tr>
                                                                                                                                                <td style="width:15%" valign="top"><a href="${repoUrl}/commit/${it2.@revision}"><i>${it2.@revision}</i></a></td>
                                                                                                                                                <td style="width:20%" valign="top">
                                                                                                                                                        <!--<img
                                                                                                                                                                style="border-radius: 20%;"
                                                                                                                                                                src="data:image/png;base64,${getGitEncodedImage(it2.author[0].text())}" /> &nbsp;  -->
                                                                                                                                                        <b>${it2.author[0].text()}</b></td>
                                                                                                                                                <td style="width:20%" valign="top">${it2.date}</td>
                                                                                                                                                <td style="width:45%" valign="top"><B> ${it2.msg.text()} </B></td>
                                                                                                                                        </tr>

                                                                                                                <%              }catch (Exception e) { %>
                                                                                                                                        <tr><td colspan="4"><B>${e.getMessage()}</B></td></tr>
                                                                                                                <%
                                                                                                                                }
                                                                                                                        }
                                                                                                                %>
                                                                                                        </table>
                                                                                                        <br />
                                                                        <%                      }
                                                                                        }catch (Exception e) {
                                                                        %>
                                                                                                <table width="100%" style="border: 1px solid #e2e2e2"  cellpadding="0" cellspacing="0">
                                                                                                        <tr>
                                                                                                                <td><b>${e.getMessage()}</b></td>
                                                                                                        </tr>
                                                                                                </table>
                                                                        <%              }
                                                                                }
                                                                        %>
                                                                </td>
                                                        </tr>
                                                </table>
                                                <br />
                                                <br />
                                        </td>
                                </tr>
                        </table>
                        <br />
                        <br />
                        <!-- Footer -->
                        <table align="center" width="80%" cellpadding="5" cellspacing="0">
                                <tr>
                                        <td>
                                                <p align="center" style="color: darkgray">
                                                        This is an auto-generated email. You received this email because you are either a member of UFT One or committed code in uft repositories. If you don't want to hear from us or need assistance, contact UFT <a href="mailto:narendrakumar.cheajra@microfocus.com">DevOps</a> team.
                                                </p>
                                                <hr align="center" width="40%" />
                                        </td>
                                </tr>
                        </table>
                </td></tr></table>
        </body>
</html>

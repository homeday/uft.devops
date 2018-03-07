<STYLE>
BODY, TABLE, TD, TH, P, PRE {
  font-family:Verdana,Helvetica,sans serif;
  font-size:14px;
  color:black;
}
h1 { color:black; }
h2 { color:black; }
h3 { color:black; }
TD.bg1 { color:white; background-color:#0000C0; font-size:120%; padding: 5px 0 }
TD.bg5 { color:white; background-color:#a08eb2; font-size:120% }
TD.bg2_, TD.bg2_ PRE, TD.bg2_ A { color:white; background-color:#8C8CFF; font-size:100% }
TD.bg2, TD.bg2 PRE, TD.bg2 A { color:blue; background-color:#ECECFF; font-size:100%  }
TD.bg2, TD.bg2_ { padding: 3px; vertical-align: top }
TD.bg4 { color:blue; background-color:#ECECFF; font-size:105% }
TD.bg3 { color:white; background-color:#8080FF; }
TD.bg6 { color:red; background-color:white; font-size:107%; padding: 3px; vertical-align: top }
TD.bg7 { color:black; background-color:#e9e9e9; font-size:107%; font-weight:bold; padding: 1px 3px }
TD.bg8 { color:#5e6e7e; background-color:#dfdfdf; font-size:105%; font-style:italic; padding: 4px 3px }
.red { color:red; background-color:red; font-size:110%  }
TD.test_passed { background-color:LimeGreen; }
TD.test_failed { background-color:red; }
TD.test_skipped { background-color:Orange; }
TR.test_passed { border-bottom: thin solid LimeGreen; }
TR.test_failed { border-bottom: thin solid red; }
TR.test_skipped { border-bottom: thin solid Orange; }
P.cons { font-family:Courier New;}
TD.info_label { padding-right: 10px; }
TD.console { }
TD.console-log { padding: 8px 0; border-bottom: 1px dashed #dedede; }
</STYLE>
<BODY>

<%
/*
def buildNumber = null

try {
def buildInfoXml = new XmlParser().parseText(build.getParent().getWorkspace().child("build/BuildInfo.xml").readToString());
buildNumber = buildInfoXml.value()[0].value()[0];
}catch(e) {
    println e
}
*/

def junit = build.getTestResultAction()
def junitResultList = null
if (junit){
    junitResultList = junit.getResult()
}

import hudson.model.*
import com.tikal.jenkins.plugins.multijob.*;
import groovy.transform.Field

//Compilation Build
Build CompilationBuild;

/*
def getBuildersRecursive(Build builder) {
  if ( builder instanceof hudson.model.FreeStyleBuild ) {

    } else if ( com.tikal.jenkins.plugins.multijob)
}
*/

// try to get compilation build
def allBuilders = build.getBuilders()
for (subBuild in allBuilders) {
  //get sub build's project
  def subProject = hudson.model.Hudson.instance.getItem(subBuild.getJobName())
  //get sub build
  def realSubBuild = subProject.getBuildByNumber(subBuild.getBuildNumber())
  if (subProject.getName().indexOf('Build.Compile') >= 0) {
    CompilationBuild = realSubBuild
    //println "*!* ${CompilationBuild} | ${CompilationBuild.getClass()}<br>"
    //println "*!* found Compilation<br>"
    break
  }
}


//println "${CompilationBuild} | ${CompilationBuild.getClass()}<br>"
//if (null != SetupBuild)
//println "${SetupBuild} | ${SetupBuild.getClass()}<br>"


 %>

<TABLE>
  <TR><TD valign="center"><B style="font-size: 200%; font-family: Verdana; color:<%= build.result.toString() == 'SUCCESS' ? "green" : build.result.toString() == 'UNSTABLE' ? "gold" : "red"%>">${build.result}</B></TD></TR>
</TABLE>

<TABLE>
<!-- ROW SECTION: Build Information -->
  <!-- ROW: Build Number -->
  <TR><TD class="info_label"><b>Build Number</b></TD><TD>${build.getEnvironment().FTQA_Version_Full}</TD></TR>

<% if (null != CompilationBuild) {%>
  <!-- ROW: Compilation Status -->
  <TR><TD class="info_label"><b>Compilation Status</b></TD><TD><SPAN style="color:white;background-color:<%= CompilationBuild.result.toString() == 'SUCCESS' ? "green" : "red"%>">${CompilationBuild.result}</SPAN></TD></TR>
<%}%>

  <!-- ROW: Build Type -->
  <TR><TD class="info_label"><b>Build Type</b></TD><TD>${build.getEnvironment().FTQA_SPEC_BuildType} Build</TD></TR>

  <!-- ROW: Compile Configuration -->
  <TR><TD class="info_label"><b>Configuration</b></TD><TD>${build.getEnvironment().FTQA_CompileConfig}</TD></TR>

  <!-- ROW: Published Assets -->
  <TR><TD class="info_label" style="padding-bottom:3px"><b>Publish</b></TD><TD><A href="${build.getEnvironment().FTQA_Publish_RootPath}\\${build.getEnvironment().FTQA_CompileConfig}\\${build.getEnvironment().FTQA_Version_Full}">Publish Link</A></TD></TR>
<!-- END OF - ROW SECTION: Build Information -->


<!-- ROW SECTION: SNV Information -->
  <!-- ROW: SVN Repository -->
  <TR><TD class="info_label"><b>SVN Repository</b></TD><TD>${build.getEnvironment().FTQA_SvnRepoName}</TD></TR>

  <!-- ROW: SVN Trunk/Branch -->
  <TR><TD class="info_label"><b>SVN Trunk/Branch</b></TD><TD>${build.getEnvironment().FTQA_SvnPath}</TD></TR>

  <!-- ROW: SVN Revision -->
<%
def isSVNChangeFound = build.getEnvironment().FTQA_SVN_IsChangeFound
def startRev = build.getEnvironment().FTQA_SVN_FirstChangedRevision
def endRev = build.getEnvironment().FTQA_SVN_FinalBuildRevision
if (isSVNChangeFound == "yes") {
%>
  <TR><TD class="info_label"><b>SVN Revisions</b></TD><TD>${startRev} - ${endRev}</TD></TR>
<%
} else {
%>
  <TR><TD class="info_label" style="padding-bottom:3px"><b>SVN Revision</b></TD><TD>${endRev}</TD></TR>
<%
}
%>
<!-- END OF - ROW SECTION: SNV Information -->


<!-- ROW SECTION: Project|Job Statistics -->
  <!-- ROW: Project -->
  <!--<TR><TD class="info_label"><b>Project</b></TD><TD>${project.name}</TD></TR>-->

  <!-- ROW: Job URL -->
  <TR><TD class="info_label"><b>Job&nbsp; URL</b></TD><TD><A href="${rooturl}${build.url}">Job Link</A></TD></TR>

  <!-- ROW: Build Server -->
  <TR><TD class="info_label"><b>Build Server</b></TD><TD>${build.getBuiltOn().getDisplayName()}</TD></TR>

  <!-- ROW: Build Start Timestamp -->
  <TR><TD class="info_label"><b>Start</b></TD><TD>${build.getEnvironment().BUILD_TIMESTAMP}</TD></TR>

  <!-- ROW: Build Duration -->
  <TR><TD class="info_label" style="padding-bottom:3px"><b>Duration</b></TD><TD>${build.durationString}</TD></TR>
<!-- END OF - ROW SECTION: Project|Job Statistics -->


<!-- ROW SECTION: Compile Logs -->
<%
  if (null != CompilationBuild) {
    def relDir = "BUILD/logs/"
    def relDirWin = "BUILD\\logs\\"
    // 12.54.1234.9
    def version = CompilationBuild.getEnvironment().FTQA_Version_Full
    // Build/Rebuild
    def msbuildTarget = CompilationBuild.getEnvironment().FTQA_Compile_MSBTarget
    // \\mydastr01.hpeswlab.net\products\ST\ST
    def publishRoot = CompilationBuild.getEnvironment().FTQA_Publish_RootPath
    // win32_release
    def compileConfig = CompilationBuild.getEnvironment().FTQA_CompileConfig

    // msbuild log file
    // BUILD/logs/msbuild_FTQA_12.54.1234.9_Build.log
    def msbuildLogFile = "msbuild_FTQA_" + version + "_" + msbuildTarget + ".log"
    //println "*!* ${msbuildLogFile}<br>"
    if (CompilationBuild.getParent().getWorkspace().child(relDir + msbuildLogFile).exists()) {
      // SAMPLE: \\mydastr01.hpeswlab.net\products\ST\ST\win32_release\12.54.1234.9\BUILD\logs\msbuild_FTQA_12.54.1234.9_Build.log
      def msbuildLogFileOnRubicon = publishRoot + "\\" + compileConfig + "\\" + version + "\\" + relDirWin + msbuildLogFile
      //println "*!* MSBuild File = ${msbuildLogFileOnRubicon}<br>"
%>

  <!-- ROW: MSBuild Log -->
  <TR><TD class="info_label"><b>MSBuild Log</b></TD><TD><A href="${msbuildLogFileOnRubicon}">MSBuild Log</A></TD></TR>

<%
    }
%>

<%
    // FTQA_Solution.log
    def ftqaSolutionLogFile = "FTQA_Solution.log"
    if (CompilationBuild.getParent().getWorkspace().child(relDir + ftqaSolutionLogFile).exists()) {
      // SAMPLE: \\mydastr01.hpeswlab.net\products\ST\ST\win32_release\12.54.1234.9\BUILD\logs\FTQA_Solution.log
      def ftqaSolutionLogFileOnRubicon = publishRoot + "\\" + compileConfig + "\\" + version + "\\" + relDirWin + ftqaSolutionLogFile
      //println "*!* FTQA_Solution File = ${ftqaSolutionLogFileOnRubicon}<br>"
%>

  <!-- ROW: FTQA_Solution Log -->
  <TR><TD class="info_label"><b>FTQA_Solution Log</b></TD><TD><A href="${ftqaSolutionLogFileOnRubicon}">FTQA_Solution Log</A></TD></TR>

<%
    }
%>

<%
    // Warnings
    def warningsFile = "buildlog_warnings_total.txt"
    if (CompilationBuild.getParent().getWorkspace().child(relDir + warningsFile).exists()) {
      // SAMPLE: \\mydastr01.hpeswlab.net\products\ST\ST\win32_release\12.54.1234.9\BUILD\logs\buildlog_warnings_total.txt
      def warningsFileOnRubicon = publishRoot + "\\" + compileConfig + "\\" + version + "\\" + relDirWin + warningsFile
      //println "*!* Warnings File = ${warningsFileOnRubicon}<br>"
%>

  <!-- ROW: Warnings -->
  <TR><TD class="info_label"><b>Warnings</b></TD><TD><A href="${warningsFileOnRubicon}">Compile Log: Warnings</A></TD></TR>

<%
    }
%>
<%
  }
%>
<!-- END OF - ROW SECTION: Compile Logs -->
</TABLE>
<BR/>


<!-- MAVEN ARTIFACTS -->
<%
try {
  def mbuilds = build.moduleBuilds
  if(mbuilds != null) { %>
  <TABLE width="100%">
      <TR><TD class="bg1"><B>ARTIFACTS</B></TD></TR>
<%
    try {
        mbuild.each() { m -> %>
        <TR><TD class="bg2"><B>${m.key.displayName}</B></TD></TR>
<%              m.value.each() { mvnbld ->
                        def artifactz = mvnbld.artifacts
                        if(artifactz != null && artifactz.size() > 0) { %>
      <TR>
        <TD>
<%                              artifactz.each() { f -> %>
            <li>
              <a href="${rooturl}${mvnbld.url}artifact/${f}">${f}</a>
            </li>
<%                              } %>
        </TD>
      </TR>
<%                      }
                }
       }
    } catch(e) {
        // we don't do anything
    }  %>
  </TABLE>
<BR/>
<% }

}catch(e) {
        // we don't do anything
}
%>




<!-- CONSOLE OUTPUT -->
<%


%>

<%

import hudson.model.*
import com.tikal.jenkins.plugins.multijob.*
import groovy.transform.Field
import hudson.console.ConsoleNote

class FailureBuildfinder {

  def failureBuildName = null

  def ExceptionString = null

  def rootbuild = null

  def rootbuildName = null

  def FailureBuildfinder() {

  }

  static def isAfailureBuild(def buildobj) {
    if ( buildobj == null)
      return false
    return hudson.model.Result.FAILURE == buildobj.result ||
      hudson.model.Result.UNSTABLE ==  buildobj.result
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

if(build.result==hudson.model.Result.FAILURE || build.result==hudson.model.Result.UNSTABLE) { %>
<TABLE width="100%" cellpadding="0" cellspacing="0">
<TR><TD class="bg1"><B>Console Output</B></TD></TR>
<%     
  
  FailureBuildfinder failureBuildfinder = new FailureBuildfinder()
  def thefailureBuild = failureBuildfinder.getFailureBuild(CompilationBuild)
  if (thefailureBuild == null) {
    thefailureBuild = failureBuildfinder.getFailureBuild(SetupBuild)
  }
 
  if (thefailureBuild != null) {%>
    <TR><TD class="console"> <h2 style="color:red;height:0.6em">The step "${failureBuildfinder.failureBuildName}" failed</h2></TD></TR>
    <TR><TD class="console" style="padding-bottom:10px"> <A href="${rooturl}${thefailureBuild.getUrl()}consoleText">${rooturl}${thefailureBuild.getUrl()}consoleText</A></TD></TR>
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
        if ( lineNumber2 > 15) break%>
        <TR><TD class="console console-log">${line}</TD></TR>
      <% continue
      }
      if ( line =~ /error / && !(line =~ /^  /) ) {
        finderrline = true
        lineNumber2 = 1 %>
        <TR><TD class="console console-log">${line}</TD></TR>
      <%}
    }
    bufReader.close()

    if (!finderrline) {
      reader = thefailureBuild.getLogReader()
      bufReader = new BufferedReader(reader)
      for (def line = bufReader.readLine(); line != null; line = bufReader.readLine()) {
        if ( lineNumber <= 15) {
          line = ConsoleNote.removeNotes(line)%>
          <TR><TD class="console console-log">${line}</TD></TR>
        <%} 
        --lineNumber
      }
      bufReader.close()
    }
    

    if (failureBuildfinder.ExceptionString != null) { %>
       <TR><TD class="console console-log">${failureBuildfinder.ExceptionString}</TD></TR>
    <%}%>

<%}%>
</TABLE>
<BR/>
<% } %>


<!-- CHANGE SET -->
<%
if (build.getEnvironment().FTQA_SVN_IsChangeFound == "yes") {
%>
<TABLE width="100%">
  <TR><TD class="bg1" colspan="4"><B>SVN Changes</B></TD></TR>
  <TR>
    <TD class="bg7" style="min-width:80px;width:8%">Revision</TD>
    <TD class="bg7" style="min-width:100px;width:16%">Author</TD>
    <TD class="bg7" style="min-width:100px;width:16%">Date</TD>
    <TD class="bg7">Message</TD>
  </TR>

<% 
  def svnCommentsFile = "committers_comments.xml"
  def commentsContent = null
  if (build.getWorkspace().child(svnCommentsFile).exists()) {
    commentsContent = build.getWorkspace().child(svnCommentsFile).readToString() 
  }

  if (commentsContent != null) {
    try {
      def committers = new XmlSlurper().parseText(commentsContent)
      def committersShownCount = 0
      def altBgFlag = true
      def maxShowCountWithMsg = 50
      committers.logentry.each {
        // increase shown count
        committersShownCount++

        // prepare alternative background
        altBgFlag = !altBgFlag
        def bgClassName = altBgFlag ? "bg2" : "bg2_"

        // check whether exceed the max show count (with message), if so, show a 
        if (committersShownCount == maxShowCountWithMsg + 1) {
          // this is the first one that exceed the max show count
%>

  <TR>
    <TD class="bg8" colspan="4">More than <B>${maxShowCountWithMsg}</B> committers, the <B>Message</B>s below will not be shown anymore...</TD>
  </TR>

<%
        } // end if [committersShownCount == maxShowCountWithMsg + 1]

        def oriDateStr = it.date.text()
        def dateParts = oriDateStr.tokenize('T.') as String[] // example: 2016-05-20T18:20:31.789339Z => [2016-05-20, 18:20:31, 789339Z]
        def refinedDateStr = oriDateStr
        if (dateParts != null && dateParts.length >= 2) {
          refinedDateStr = dateParts[0] + " " + dateParts[1]
        }

        // p1=0=UTC; p2=110=Israel; p3=237=China; p4=367=Ukraine; p5=49=Romania; p6=218=Vietnam
        def dateConvLink = "http://www.timeanddate.com/worldclock/converted.html?iso=" + oriDateStr + "&p1=0&p2=110&p3=237&p4=367&p5=49&p6=218"
        def msgTxt = (committersShownCount <= maxShowCountWithMsg) ? it.msg.text() : "..."
%>

  <TR>
    <TD class="${bgClassName}">${it.@revision}</TD>
    <TD class="${bgClassName}">${it.author[0].text()}</TD>
    <TD class="${bgClassName}">

<%      if (refinedDateStr) {
%>

      <SPAN>${refinedDateStr} <A href="${dateConvLink}">UTC</A></SPAN>

<%      } // end if [refinedDateStr]
%>

    </TD>
    <TD class="${bgClassName}"><PRE>${msgTxt}</PRE></TD>
  </TR>

<%
      } // end each
    } catch (Exception e) {
%>

  <TR><TD class="bg6" colspan="4">${e.getMessage()}</TD></TR>

<% } // end catch
%>

</TABLE>
<BR/>

<% } // end if [commentsContent != null]
} // end if [FTQA_SVN_IsChangeFound == "yes"]
%>


</BODY>

<STYLE>
BODY, TABLE, TD, TH, P {
  font-family:Verdana,Helvetica,sans serif;
  font-size:14px;
  color:black;
}
h1 { color:black; }
h2 { color:black; }
h3 { color:black; }
TD.bg1 { color:white; background-color:#0000C0; font-size:120% }
TD.bg5 { color:white; background-color:#a08eb2; font-size:120% }
TD.bg1_ { color:#4d4d4d; background-color:#CCCCFF; font-size:115% }
TD.bg2 { color:blue; background-color:#ECECFF; font-size:110% }
TD.bg4 { color:blue; background-color:#ECECFF; font-size:105% }
TD.bg3 { color:white; background-color:#8080FF; }
TD.bg6 { color:red; background-color:white; font-size:107% }
.red { color:red; background-color:red; font-size:110%  }
TD.test_passed { background-color:LimeGreen; }
TD.test_failed { background-color:red; }
TD.test_skipped { background-color:Orange; }
TR.test_passed { border-bottom: thin solid LimeGreen; }
TR.test_failed { border-bottom: thin solid red; }
TR.test_skipped { border-bottom: thin solid Orange; }
P.cons { font-family:Courier New;}
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
//Setup build
Build SetupBuild;

/*
def getBuildersRecursive(Build builder) {
  if ( builder instanceof hudson.model.FreeStyleBuild ) {

    } else if ( com.tikal.jenkins.plugins.multijob)
}
*/
build.getBuilders().each {
  subBuild -> 
    //get sub build's project
    subProject = hudson.model.Hudson.instance.getItem(subBuild.getJobName())
    //get sub build
    RealsubBuild = subProject.getBuildByNumber(subBuild.getBuildNumber())
    
    if (subProject.getName().indexOf('Compilation') >= 0) {
      CompilationBuild = RealsubBuild
     // println "${CompilationBuild} | ${CompilationBuild.getClass()}<br>"
    //  println "found Compilation<br>"
    } else if ( subProject.getName().indexOf('Setup.Generation') >= 0) {
      SetupBuild = RealsubBuild
     // println "${SetupBuild} | ${SetupBuild.getClass()}<br>"
     // println "found Setup<br>"
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
<%
if ( build.getEnvironment().BUILD_FAILURE ) {
%>
  <TR><TD ><b>Failure cause</b></td><td class="red"><b>${build.getEnvironment().BUILD_FAILURE}!!!</b></TD></TR>
<% }
%>
  <TR><TD><b>Build ID</b></TD><TD>${build.getEnvironment().BuildVersion}</TD></TR>
<%
  if (null != CompilationBuild) {%>
  <TR><TD><b>Compilation Status</b></TD><TD>${CompilationBuild.result}</TD></TR>
<%}%>
  <%
if ( null != SetupBuild && (build.result == hudson.model.Result.SUCCESS ||
  build.result == hudson.model.Result.UNSTABLE ) ) {
%>
   <TR><TD><b>UFT Setup</b></TD><TD><A href="${build.getEnvironment().PRODUCTS_STORAGE_WIN}\\FT\\QTP\\${build.getEnvironment().Configuration}\\${SetupBuild.getEnvironment().versionNumber}\\DVD_Wix\\Setup.exe">Installation Link</A></TD></TR>
   <TR><TD><b>QCPlugin Setup</b></TD><TD><A href="${build.getEnvironment().PRODUCTS_STORAGE_WIN}\\FT\\QTP\\${build.getEnvironment().Configuration}\\${SetupBuild.getEnvironment().versionNumber}\\DVD_Wix\\ALMPlugin\\MSI\\HP_Unified_Functional_Add-in_for_ALM.msi">Installation Link</A></TD></TR>
   <TR><TD><b>UFTRepView Setup</b></TD><TD><A href="${build.getEnvironment().PRODUCTS_STORAGE_WIN}\\FT\\QTP\\${build.getEnvironment().Configuration}\\${SetupBuild.getEnvironment().versionNumber}\\DVD_Wix\\RunResultsViewer\\MSI\\HP_Run_Results_Viewer.msi">Installation Link</A></TD></TR>
   <TR><TD><b>ExtAccTool Setup</b></TD><TD><A href="${build.getEnvironment().PRODUCTS_STORAGE_WIN}\\FT\\QTP\\${build.getEnvironment().Configuration}\\${SetupBuild.getEnvironment().versionNumber}\\DVD_Wix\\Extensibility and Toolkits\\ExtAccTool\\MSI\\HP_Extensibility_Accelerator_Tool.msi">Installation Link</A></TD></TR>
<% } else if (build.result == hudson.model.Result.SUCCESS) { %>
   <TR><TD><b>UFT Setup</b></TD><TD><A href="${build.getEnvironment().PRODUCTS_STORAGE_WIN}\\FT\\QTP\\${build.getEnvironment().Configuration}\\${build.getEnvironment().BuildVersion}\\MSI\\">${build.getEnvironment().PRODUCTS_STORAGE_WIN}\\FT\\QTP\\${build.getEnvironment().Configuration}\\${build.getEnvironment().BuildVersion}\\MSI\\</A></TD></TR>
<%}
%>
  <TR><TD><b>Project</b></TD><TD>${project.name}</TD></TR>
  <TR><TD><b>Job&nbsp; URL</b></TD><TD><A href="${rooturl}${build.url}">${rooturl}${build.url}</A></TD></TR>
  <TR><TD><b>Type</b></TD><TD>${build.getEnvironment().Type}</TD></TR>
 <% if (build.getParent().getWorkspace().child("build/logs/MSBExe_Build.log").exists()) { %>
  <TR><TD><b>Compile&nbsp;log</b></TD><TD><A href="${build.getEnvironment().rubicon_full_global_path}/build/logs/MSBExe_Build.log">${build.getEnvironment().rubicon_full_global_path}/build/logs/MSBExe_Build.log</A></TD></TR>
<% } %>
  <TR><TD><b>Date&nbsp;of&nbsp;build</b></TD><TD>${build.getEnvironment().BUILD_TIMESTAMP}</TD></TR>
  <TR><TD><b>Duration</b></TD><TD>${build.durationString}</TD></TR>
  <%
  if (null != CompilationBuild) {%>

  <TR><TD><b>Branch</b></TD><TD>${CompilationBuild.getEnvironment().Branch}</TD></TR>
  <%}%>
  <TR><TD><b>ServerName</b></TD><TD>${build.getBuiltOn().getDisplayName()}</TD></TR>
  <TR><TD><b>Configuration</b></TD><TD>${build.getEnvironment().Configuration}</TD></TR>

   <% if ( build.getEnvironment().MACHINEIP != null ) { %>
  <TR><TD><b>ServerIP</b></TD><TD>${build.getEnvironment().MACHINEIP}</TD></TR>
   <% } %>
<% if (build.getParent().getWorkspace().child("build/logs/buildlog_warnings_total.txt").exists()) { %>
  <TR><TD><b>Build&nbsp;warnings</b></TD><TD><A href="${build.getEnvironment().rubicon_full_global_path}\\build\\logs\\buildlog_detailed_results.csv">${build.getParent().getWorkspace().child("build/logs/buildlog_warnings_total.txt").readToString()}</A></TD></TR>
<% } %>
</TABLE>
<BR/>

<%
try {
 
%>
    <TABLE >
    
<%
  //def importedListPath = "/products/FT/QTP/" + build.getEnvironment().Configuration + "/" + build.getEnvironment().BuildVersion + "/build/reports/Imported_Repository_List.xml"
  
  //def report = new XmlParser().parse(new File(importedListPath))

  def report = null
  if( CompilationBuild != null && CompilationBuild.getParent().getWorkspace().child("build/reports/Imported_Repository_List.xml").exists()){
    report = new XmlParser().parseText(CompilationBuild.getWorkspace().child("build/reports/Imported_Repository_List.xml").readToString())
  }
  else if ( SetupBuild != null && SetupBuild.getWorkspace().child("build/reports/Imported_Repository_List.xml").exists()) {
    report = new XmlParser().parseText(SetupBuild.getWorkspace().child("build/reports/Imported_Repository_List.xml").readToString())
  } 

  if ( null != report ) {

  // report = new XmlParser().parseText(build.getParent().getWorkspace().child("build/reports/Imported_Repository_List.xml").readToString())

%>
   <TR><TD class="bg1" colspan="6"><B>Imported Repository List</B></TD></TR>
<TR align="left">
<TH align="left">Repository</TH>
<TH align="left">Configuration</TH>
<TH align="left">Group</TH>
<TH align="left">Build ID</TH>
<TH align="left">Branch</TH>
<TH align="left">Tag/Revision</TH>
</TR>
<%
report.Repository.each{ it ->
%>
<TR>
<TD>${it.attribute('product')}</TD>
<TD>${it.attribute('config')}</TD>
<TD>${it.attribute('group')}</TD>
<TD><a target="_blank" href="file:${build.getEnvironment().PRODUCTS_STORAGE_WIN}\\${it.attribute('group')}\\${it.attribute('product')}\\${it.attribute('config')}\\${it.attribute('build')}" > ${it.attribute('build')} </a></TD>
<TD>${it.attribute('svnbranch')}</TD>
<TD>${it.attribute('svnrevision') ? it.attribute('svnrevision') : it.attribute('svntag')}</TD>
</TR>
<%}
}%>

  </TABLE>
<BR/>
<%
}catch(e) {
    // println "File build/reports/Imported_Repository_List.xml not found.<br/>"+e
}
%>


<%

// @GrabResolver(name='restlet', root='http://mydtbld0028.isr.hp.com:8081/nexus/content/groups/public/')
// @Grab(group='org.apache.directory', module='groovyldap', version='0.1')
import javax.naming.Context;
import javax.naming.NamingEnumeration;
import javax.naming.directory.Attribute;
import javax.naming.directory.Attributes;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import javax.naming.directory.SearchControls;
import javax.naming.directory.SearchResult;

import java.net.HttpURLConnection;
import java.net.URL;

def thumb_url( userName ) {

try {
    String base = "ou=Users,ou=Accounts";
    String filter = '(&(objectClass=user)(objectCategory=person)(|(sAMAccountName='+userName+')(name='+userName+')(displayname='+userName+')))'
    SearchControls sc = new SearchControls();
    String[] attributeFilter = [ "cn", "employeeid", "samaccountname" ];
    sc.setReturningAttributes(attributeFilter);
    sc.setSearchScope(SearchControls.SUBTREE_SCOPE);

    String re = "eu"
    Hashtable cenv = new Hashtable();
    cenv.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
    cenv.put(Context.PROVIDER_URL, "ldap://emea.cpqcorp.net:389/dc=emea,dc=cpqcorp,dc=net");
    cenv.put(Context.SECURITY_PRINCIPAL, 'almtoolsbuild@EMEA.hpqcorp.net');
    cenv.put(Context.SECURITY_CREDENTIALS, "\$eNaofayroel");
    DirContext dctx = new InitialDirContext(cenv);

    NamingEnumeration results = dctx.search(base, filter, sc);

    if ( !results.hasMore() ) {
       dctx.close();
       re = "ap"
       cenv.put(Context.PROVIDER_URL, "ldap://asiapacific.cpqcorp.net:389/dc=asiapacific,dc=cpqcorp,dc=net");
       cenv.put(Context.SECURITY_PRINCIPAL, 'almtoolsbuild1@asiapacific.hpqcorp.net');
       cenv.put(Context.SECURITY_CREDENTIALS, "fox.fit.hit-187");
       dctx = new InitialDirContext(cenv);

       results = dctx.search(base, filter, sc);

    }

    while (results.hasMore()) {
      SearchResult sr = (SearchResult) results.next();
      Attributes attrs = sr.getAttributes();

      String samaccountname = attrs.get("samaccountname").get();
      String employeeid = attrs.get("employeeid").get();
      url = "http://g6t0022.atlanta.hp.com/images/thumb_${re}_${samaccountname}_${employeeid.substring(employeeid.length()-4)}.jpg"
      img = "<div><img style='max-height:40px;' src='${url}' /></div>"

      try {
         HttpURLConnection.setFollowRedirects(false);
         // note : you may also need
         //        HttpURLConnection.setInstanceFollowRedirects(false)
         HttpURLConnection con = (HttpURLConnection) new URL(url).openConnection();
         con.setRequestMethod("HEAD");
         if (con.getResponseCode() == HttpURLConnection.HTTP_OK) {
             dctx.close();
             return img
         }
      }
      catch (Exception e) {
          e.printStackTrace();
          dctx.close();
          return ""
      }
      return "<div><img src='http://mydtbld0028.isr.hp.com:8081/nexus/content/repositories/alm_devops/jenkins/photos/anonymous/1/anonymous-1.gif'/><br/><a href='https://g6t0022.atlanta.hp.com/protected/people/view/person/normal/'>Click here to upload your photo.</a></div>";

    }
    dctx.close();
  }
    catch (Exception ex){
  }
    return ""
}
%>



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

if ( build.getEnvironment().BUILD_FAILURE == "Compilation Failed" ||  build.getEnvironment().BUILD_FAILURE == "CompilationFailed" ||  build.getEnvironment().BUILD_FAILURE == "BUILD Failed") {
  /* def i=0
  build.getParent().getWorkspace().child("build/logs/MSBExe_Build.log").readToString().eachLine(){
    i= i+1
  } */ %>
 <TABLE width="100%" cellpadding="0" cellspacing="0">
 <TR><TD class="bg1"><B>Compilation Errors</B></TD></TR>
 <%
         def i=0
         build.getParent().getWorkspace().child("build/logs/MSBExe_Build.log").readToString().eachLine(){ line ->
            // if ( i < 30 )
            if ( line =~ /error / && !(line =~ /^  /) )
            { 
               i=i+1%>
         <TR><TD class="console">${line}</TD></TR>
 <%      } } %>
         <TR><TD class="console">Error(s) found: ${i}  <A href="${build.getEnvironment().rubicon_full_global_path}/build/logs/MSBExe_Build.log">(Full Log)</A></TD></TR>

 </TABLE>
 <BR/>

<% } else if(build.result==hudson.model.Result.FAILURE || build.result==hudson.model.Result.UNSTABLE) { %>
<TABLE width="100%" cellpadding="0" cellspacing="0">
<TR><TD class="bg1"><B>Console Output</B></TD></TR>
<%     
  
  FailureBuildfinder failureBuildfinder = new FailureBuildfinder()
  def thefailureBuild = failureBuildfinder.getFailureBuild(CompilationBuild)
  if (thefailureBuild == null) {
    thefailureBuild = failureBuildfinder.getFailureBuild(SetupBuild)
  }
 
  if (thefailureBuild != null) {%>
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
        if ( lineNumber2 > 15) break%>
        <TR><TD class="console">${line}</TD></TR>
      <% continue
      }
      if ( line =~ /error / && !(line =~ /^  /) ) {
        finderrline = true
        lineNumber2 = 1 %>
        <TR><TD class="console">${line}</TD></TR>
      <%}
    }
    bufReader.close()

    if (!finderrline) {
      reader = thefailureBuild.getLogReader()
      bufReader = new BufferedReader(reader)
      for (def line = bufReader.readLine(); line != null; line = bufReader.readLine()) {
        if ( lineNumber <= 15) {
          line = ConsoleNote.removeNotes(line)%>
          <TR><TD class="console">${line}</TD></TR>
        <%} 
        --lineNumber
      }
      bufReader.close()
    }
    

    if (failureBuildfinder.ExceptionString != null) { %>
       <TR><TD class="console">${failureBuildfinder.ExceptionString}</TD></TR>
    <%}%>





<%}%>

</TABLE>
<BR/>
<% } %>


<!-- CHANGE SET -->
<TABLE width="100%">
<TR><TD class="bg1" colspan="4"><B>GIT Changelogs</B></TD></TR><BR/>

<% 

def svnfile = null
def gitfile = null
def gitfiles = build.getWorkspace().list("Build_*_Git_Commits.xml")

def repoName = ""
gitfiles.each {
  try {
    repoName = it.getBaseName().replace("Build_", "").replace("_Git_Commits", "")
    def repoUrl = "https://github.houston.softwaregrp.net/uft/${repoName}"
    gitfile = it.readToString()  %>
    <%
    def committers1 = new XmlSlurper().parseText(gitfile)
    if (committers1.logentry != null && committers1.logentry.size() > 0) {
    %>
    
    <TR><TD class="bg1_" colspan="4"><B>-- ${repoName} --</B></TD></TR>
    <%
      committers1.logentry.each {
        it2 ->
        try {
      %>
        <TR>
        <TD class="bg2"><A href="${repoUrl}/commit/${it2.@revision}"><I>${it2.@revision}</I></A></TD>
        <TD class="bg2"><B> ${it2.author[0].text()}</B></TD>
        <TD class="bg2">${it2.date}</TD>
        <TD class="bg2"><B> ${it2.msg.text()} </B></TD>
        </TR>
        <TR>
        </TR>
      <%}
        catch (Exception e) {%>
            <TR><TD class="bg2" colspan="4"><B>${e.getMessage()}</B></TD></TR>
        <%}
      }
    }
  }
  catch (Exception e) {%>
    <TR><TD class="bg2" colspan="4"><B>${e.getMessage()}</B></TD></TR>
<%}
}%>

</TABLE>




</BODY>

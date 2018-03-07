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
TD.bg2_ { color:white; background-color:#4040FF; font-size:110% }
TD.bg2 { color:blue; background-color:#ECECFF; font-size:107% }
TD.bg3 { color:white; background-color:#8080FF; }
.red { color:white; background-color:red; font-size:110%  }
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
 %>

<TABLE>
  <TR><TD align="right"><IMG SRC="${rooturl}static/e59dfe28/images/32x32/<%= build.result.toString() == 'SUCCESS' ? "blue.gif" : build.result.toString() == 'FAILURE' ? 'red.gif' : 'yellow.gif' %>" />
 </TD><TD valign="center"><B style="font-size: 200%; font-family: Verdana">${build.result}</B></TD></TR>
</TABLE>

<TABLE>

  


  <TR><TD><b>Project</b></TD><TD>${project.name}</TD></TR>
  <TR><TD><b>Job&nbsp; URL</b></TD><TD><A href="${rooturl}${build.url}">${rooturl}${build.url}</A></TD></TR>
  <%
if(build.result==hudson.model.Result.SUCCESS ) {
%>
  <TR><TD><b>Artifacts</b></TD><TD><A href="${build.getEnvironment().PRODUCTS_STORAGE_WIN}\\${build.getEnvironment().ProductLocation}\\${build.getEnvironment().BuildVersion}">${build.getEnvironment().PRODUCTS_STORAGE_WIN}\\${build.getEnvironment().ProductLocation}\\${build.getEnvironment().BuildVersion}</A></TD></TR>
<% }
%>
  <TR><TD><b>Date&nbsp;of&nbsp;build</b></TD><TD>${it.timestampString}</TD></TR>
  <TR><TD><b>Duration</b></TD><TD>${build.durationString}</TD></TR>
  <TR><TD><b>Server</b></TD><TD>${build.getBuiltOn().getDisplayName()}</TD></TR>
  <TR><TD><b>Platform</b></TD><TD>${build.getEnvironment().Configuration}</TD></TR>
  <TR><TD><b>Branch</b></TD><TD>${build.getEnvironment().Branch}</TD></TR>
  <TR><TD><b>Build&nbsp;ID</b></TD><TD>${build.getEnvironment().BuildVersion}</TD></TR>
  <TR><TD><b>GIT&nbsp;path</b></TD><TD>https://${build.getEnvironment().GITHUB_SERVER}/uft/${build.getEnvironment().Git_Repo}.git</TD></TR>
  <TR><TD><b>GIT&nbsp;revisions</b></TD><TD>${build.getEnvironment().LastSuccessfulRevision} - ${build.getEnvironment().GIT_COMMIT}</TD></TR>

</TABLE>
<BR/>

<%
try {

%>
    <TABLE >
<%

   def report = new XmlParser().parseText(build.getParent().getWorkspace().child("build/reports/Imported_Repository_List.xml").readToString())

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
<%}%>

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
    cenv.put(Context.SECURITY_CREDENTIALS, "\$eNaroigdami");
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


<!-- CHANGE SET -->
<TABLE width="100%">
<TR><TD class="bg1" colspan="3"><B>Git Changes</B></TD></TR>
<% 

def svnfile = null

if ( build.getEnvironment().LastSuccessfulRevision == build.getEnvironment().GIT_COMMIT) { %>
  <TD class="bg2"><B> no changes </B></TD>
<%} else {
  if (null != build && build.getWorkspace().child("build/info/Build_Git_Commits.xml").exists()) {
    svnfile = build.getWorkspace().child("build/info/Build_Git_Commits.xml").readToString() 
  }
if ( svnfile != null) {
    try {
    def committers1 = new XmlSlurper().parseText(svnfile)

    committers1.logentry.each{ 
   
 %>

<TR>
<TD class="bg2"> Revision <B> ${it.@revision} </B> by <B>${it.author.text()}</B></TD>
<TD class="bg2"> Date <B> ${it.date.text()} </B></TD>
<TD class="bg2"> Message <B> ${it.msg.text()} </B></TD>
</TR>
<TR>

 </TR>
<% }

} catch (Exception e) {%>

  <TR>
    <TD>
      ${e.getMessage()}

    </TD>
  </TR>
 <% } %>
  </TABLE>
  <BR/>
  <% }} %>
  




<!-- ARTIFACTS -->
<% def artifacts = build.artifacts
if(artifacts != null && artifacts.size() > 0) { %>
  <TABLE width="100%">
    <TR><TD class="bg1"><B>ARTIFACTS</B></TD></TR>
    <TR>
      <TD>
<%              artifacts.each() { f -> %>
          <li>
            <a href="${rooturl}${build.url}artifact/${f}">${f}</a>
          </li>
<%              } %>
      </TD>
    </TR>
  </TABLE>
<BR/>
<% } %>

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

<!-- SANITY TEST -->
  <%/*def junit = build.getTestResultAction()
    if (junit != null && build.getEnvironment().Configuration=="win32_release"){
    def junitResultList = junit.getResult() */
  if(junitResultList && build.getEnvironment().Configuration=="win32_release" /* && junitResultList.isEmpty()!=true*/ ) { %>


  <TABLE width="100%" style="border-collapse: collapse; border_: 1px; word-wrap:break-word; ">
    <TR><TD class="bg1" colspan="4"><B>UnitTests</B></TD></TR></TABLE>
       <br> 
       <% def errorCount; %>
        <% errorCount = 0;
           junitResultList.each() { junitResult -> 
             junitResult.getChildren().each() { packageResult ->
               packageResult.getChildren().each() { classResult ->
                 classResult.getChildren().each() { testResult ->
                 if (testResult.getFailCount()) {
                   errorCount++;
                   if ( errorCount == 1) { %>
<TABLE width="100%" style="border-collapse: collapse; border: 1px;">
<tr><td class="red"><B>All Failed Tests:</b></td></tr>
                <% }
                   println "<tr><td style='color: red;'>${packageResult.getName()} - ${classResult.getName()} - ${testResult.getName()}</td></tr>" } %>
           <%    } 
               } 
             }

          if ( errorCount ) {%>
            </TABLE>
            <BR/>
          <%}
           }%>

      <% junitResultList.each() { junitResult -> %>
        <% junitResult.getChildren().each() { packageResult -> %>
  <TABLE width="100%" style="border-collapse: collapse; border_: 1px; word-wrap:break-word; ">
    <TR><TD class="bg1" colspan="4"><B>Test <% println "group: ${packageResult.getName()} Failed: ${packageResult.getFailCount()} test(s), Passed: ${packageResult.getPassCount()} test(s), Skipped: ${packageResult.getSkipCount()} test(s), Total: ${packageResult.getPassCount()+packageResult.getFailCount()+packageResult.getSkipCount()} test(s)" %> </B></TD></TR>
    <TR><TH>Status</TH><TH>Class name</TH><TH>Test name</TH><TH>Duration</TH></TR>

        <% packageResult.getChildren().each() { classResult -> %>
        <% classResult.getChildren().each() { testResult -> %>
    <TR
        <% def style;
           if (testResult.getSkipCount()) { style="test_skipped" }
           if (testResult.getPassCount()) { style="test_passed" }
           if (testResult.getFailCount()) { style="test_failed" }
           println "class='$style'";
%>
><%

        if (testResult.getSkipCount()) { println "<td class='$style'> Skipped </td>" }
        else if (testResult.getPassCount()) { println "<td class='$style'> Passed </td>" }
        else if (testResult.getFailCount()) { println "<td class='$style'> Failed </td>" }
println "<td > ${classResult.getName()} </td><td > ${testResult.getName()} </td><td> ${testResult.getDuration()} </td>";
        /* if (testResult.getSkipCount()) { println "<td class='$style'>Skipped</td>" }
        else if (testResult.getPassCount()) { println "<td class='$style'>Passed</td>" }
        else if (testResult.getFailCount()) { println "<td class='$style'>Failed</td>" }  */
%>
    </TR>

          <% } %>
          <% } %>






  </TABLE>
<BR/>
        <%
    // }

       }
    }%>

        <% errorCount = 0;
           junitResultList.each() { junitResult -> 
             junitResult.getChildren().each() { packageResult ->
               packageResult.getChildren().each() { classResult ->
                 classResult.getChildren().each() { testResult ->
                 if (testResult.getFailCount()) {
                   errorCount++;
                   if ( errorCount == 1) { %>
<TABLE width="100%" style="border-collapse: collapse; border: 1px;">
<tr><td class="red"><B>Failed Tests Details:</b></td></tr>
                <% }
                   println "<tr><td style='color: red;'>${packageResult.getName()} - ${classResult.getName()} - ${testResult.getName()}</td></tr><tr class='test_failed'><td style='word-wrap:break-word; '><pre>MESSAGE:\n${testResult.getErrorDetails()}\n\nSTACK:\n${testResult.getErrorStackTrace()}</pre></td></tr>" } %>
           <%    } 
               } 
             }

          if ( errorCount ) {%>
            </TABLE>
            <BR/>
          <%}
           }%>

<%}%>


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
  def thefailureBuild = failureBuildfinder.getFailureBuild(build)
 
 
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



</BODY>

<STYLE>
BODY, TABLE, TD, TH, P {
  font-family:Verdana,Helvetica,sans serif;
  font-size:11px;
  color:black;
}
h1 { color:black; }
h2 { color:black; }
h3 { color:black; }
TD.bg1 { color:white; background-color:#0000C0; font-size:120% }
TD.bg5 { color:white; background-color:#a08eb2; font-size:120% }
TD.bg2_ { color:white; background-color:#4040FF; font-size:110% }
TD.bg2 { color:blue; background-color:#ECECFF; font-size:107% }
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
 %>

<TABLE>
  <TR><TD align="right"><IMG SRC="${rooturl}static/e59dfe28/images/32x32/<%= build.result.toString() == 'SUCCESS' ? "blue.gif" : build.result.toString() == 'FAILURE' ? 'red.gif' : 'yellow.gif' %>" />
 </TD><TD valign="center"><B style="font-size: 200%; font-family: Verdana">${build.result}</B></TD></TR>
</TABLE>

<TABLE>
<%
if ( build.getEnvironment().BUILD_FAILURE ) {
%>
  <TR><TD ><b>Failure cause</b></td><td class="red"><b>${build.getEnvironment().BUILD_FAILURE}!!!</b></TD></TR>
<% }
%>

  <TR><TD><b>Project</b></TD><TD>${project.name}</TD></TR>
  <TR><TD><b>Job&nbsp; URL</b></TD><TD><A href="${rooturl}${build.url}">${rooturl}${build.url}</A></TD></TR>
  <TR><TD><b>Type</b></TD><TD>${build.getEnvironment().Type}</TD></TR>
 <% if (build.getParent().getWorkspace().child("build/logs/MSBExe_Build.log").exists()) { %>
  <TR><TD><b>Compile&nbsp;log</b></TD><TD><A href="${build.getEnvironment().rubicon_full_global_path}/build/logs/MSBExe_Build.log">${build.getEnvironment().rubicon_full_global_path}/build/logs/MSBExe_Build.log</A></TD></TR>
<% } %>
  <TR><TD><b>Date&nbsp;of&nbsp;build</b></TD><TD>${it.timestampString}</TD></TR>
  <TR><TD><b>Duration</b></TD><TD>${build.durationString}</TD></TR>
  <TR><TD><b>ServerName</b></TD><TD>${build.getBuiltOn().getDisplayName()}</TD></TR>
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
<TD><a target="_blank" href="file:\\\\rubicon.isr.hp.com\\products\\${it.attribute('group')}\\${it.attribute('product')}\\${it.attribute('config')}\\${it.attribute('build')}" > ${it.attribute('build')} </a></TD>
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

<!-- CHANGE SET -->

<% def changeSet = build.getEnvironment().changes
   def committers = build.getEnvironment().committers
if(changeSet != null) {
        def hadChanges = false %>
        <TABLE width="100%">
    <TR><TD class="bg1" colspan="2"><B>Changes</B></TD></TR>
	 <TR><TD><B>${committers}</B></TD></TR>
	 <TR><TD><B>${changeSet}</B></TD></TR>
  
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




<!-- CONSOLE OUTPUT -->


<%
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
<%      build.getLog(400).each() { line -> 
       if ( line.contains("status : FAILURE") )
	    {
		def (v,z,x) = line.split(' : ')
		def (jobname,with,status) = x.split(' ')
		def consolestring = "BuildConsole_"+jobname+".txt"
		def parentbuild = "BUILD_URL_CONSOLE="+rooturl+"job"
		def y=0
		%>
		 <TR><TD class="bg6">${line}</TD></TR>
		 <%
		if (build.getParent().getWorkspace().child(consolestring).exists()) {
		
        build.getParent().getWorkspace().child(consolestring).readToString().eachLine(){ line1 ->
	    def (result,result1) = line1.split(parentbuild)
		def url = rooturl+"job"+result1+"consoleText"
	    def urlFile = url.toURL()
		
		y=y+1%>
		
		 <TR><TD class="bg6">${jobname}</TD></TR>
	    
		 <TR><TD> <a target="_blank" href="${url}" > ${url} </a></TD></TR>
	   <%
		 
		def lineNumber=0
		urlFile.eachLine()  { currentLine ->
		if (lineNumber == 0 ) {
		newline = currentLine 
		
		}
		
		if ( newline =~ /error / ) { 
		lineNumber=lineNumber+1 %>		
		<TR><TD class="console">${currentLine}</TD></TR>  
		  
       	<% } 
		
		if ( lineNumber == 20 ) {
		 lineNumber= 0
  	    } 
		
		} 
        %>
		
		
		

		
		
				
	     <%  } }  else { %>
        
  <%	       }  } } %>
</TABLE>
<BR/>
<% } %>


<!-- SANITY TEST -->
  <%/*def junit = build.getTestResultAction()
    if (junit != null ){
    def junitResultList = junit.getResult() */
  if(junitResultList  && junitResultList.isEmpty()!=true ) { %>
   
  <TABLE width="100%" style="border-collapse: collapse; border_: 1px; word-wrap:break-word; ">
    <TR><TD class="bg1" colspan="4"><B>UnitTests</B></TD></TR></TABLE>
       <br> 
       <% def errorCount; %>
        <% errorCount = 0;
           junitResultList.each() { junitResult -> 
             junitResult.getChildren().each() { packageResult ->
               packageResult.getChildren().each() { classResult ->
			   %>
			  
			   <B> "ttttt"${classResult.getChildren().each()} </B>
			   <%
			   if ( classResult.getChildren().each()  > 0 ){
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
			}

          if ( errorCount ) {%>
            </TABLE>
            <BR/>
          <%}
           }%>

      <% junitResultList.each() { junitResult -> %>
        <% junitResult.getChildren().each() { packageResult -> %>
  <TABLE width="100%" style="border-collapse: collapse; border_: 1px; word-wrap:break-word; ">
    <TR><TD class="bg5" colspan="4"><B>Test <% println "group: ${packageResult.getName()} Failed: ${packageResult.getFailCount()} test(s), Passed: ${packageResult.getPassCount()} test(s), Skipped: ${packageResult.getSkipCount()} test(s), Total: ${packageResult.getPassCount()+packageResult.getFailCount()+packageResult.getSkipCount()} test(s)" %> </B></TD></TR>
	 <% if ( packageResult.getFailCount() > 1) { %>
	 
	
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

<% } %>
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


</BODY>

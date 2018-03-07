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
TD.bg2 { color:blue; background-color:#ECECFF; font-size:110% }
TD.bg4 { color:blue; background-color:#ECECFF; font-size:105% }
TD.bg3 { color:white; background-color:#8080FF; }
TD.bg6 { color:red; background-color:white; font-size:107% }
TD.bg7 { color:black; background-color:white; font-size:105% }
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
   <TR><TD><b>Date&nbsp;of&nbsp;build</b></TD><TD>${it.timestampString}</TD></TR>
  <TR><TD><b>Duration</b></TD><TD>${build.durationString}</TD></TR>
  <TR><TD><b>ServerName</b></TD><TD>${build.getBuiltOn().getDisplayName()}</TD></TR>


 </TABLE>
 <TABLE width="100%">
<%

def changeSet = build.changeSet
if(changeSet != null) {
  def hadChanges = false %>
   
   <TR><TD class="bg1" colspan="1"><B>Changes in this build</B></TD></TR>

<% changeSet.each() { cs -> hadChanges = true %>
  <% cs.metaClass.hasProperty('commitId') ? cs.commitId : cs.metaClass.hasProperty('revision') ? cs.revision : cs.metaClass.hasProperty('changeNumber') ? cs.changeNumber : "" %>
  <TR><TD class="bg7" colspan="4"><B>
	<%= cs.author %> 
	</B></TD></TR>
	<%
	cs.affectedFiles.each() 
	 {p -> %>
	 <TR><TD>
	 [<%= cs.commitId[0..6] %>]: <%= cs.msgAnnotated %> |  File: <%= p.path %> | Change type: <%= p.editType.name %>  
	 </TD></TR>
	  <BR/>
	  <% }
	   
   }     
    if(!hadChanges) { %>
      No changes
    <% }     
} %>


</TABLE>
tttt
<TABLE width="100%" cellpadding="0" cellspacing="0">
  <% 
 if(build.result==hudson.model.Result.FAILURE) { 
 %>
  
   <TR><TD class="bg1" colspan="1"><B>CONSOLE OUTPUT</B></TD></TR>
     
   
 <% build.getLog(400).each() { line -> 
	if ( line.contains("Result was FAILURE")) {
	%>
	<TR><TD class="bg6"><B>${line}</B></TD></TR>
	<% } else { %>
	<TR><TD>${line}</TD></TR>
	<%}
	
   } %>
<BR/>
  <% } %>
	</TABLE>
	
</BODY>

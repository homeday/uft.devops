<style>
BODY, TABLE, TD, TH, P, PRE {
    font-family: Calibri,Verdana,Helvetica,sans serif;
    font-size: 12pt;
    color: black;
}
H2, A {
    color: #1F497D;
}
SPAN.emphasize {
    background-color: green;
    font-weight: bolder;
    color: white;
    font-size: 110%;
}
SPAN.emphasize2 {
    font-weight: bolder;
    font-size: 110%;
}
SPAN.emphasize3 {
    background-color: yellow;
    font-weight: bolder;
    color: red;
    font-size: 110%;
}
</style>
<body>

<%
import hudson.model.*
import com.tikal.jenkins.plugins.multijob.*;
import groovy.transform.Field

def build_num = build.getEnvironment().UFT_Build_Number
def rel_major_num = build.getEnvironment().Release_Major_Number
def rel_minor_num = build.getEnvironment().Release_Minor_Number
def release_num = rel_major_num + "." + rel_minor_num
def sprint_num = build.getEnvironment().Sprint_Number
def branch_name = build.getEnvironment().GIT_Branch_Name
def code_freeze_phase = "true".equalsIgnoreCase(build.getEnvironment().Code_Freeze_Phase)
def unlock_job_url = "http://mydtbld0211.swinfra.net:8080/view/Products/view/Self%20Services/job/Github.PullRequest.StatusChecks.ForceUnlock/build"
def status_checks = "cd/releases/${rel_major_num}_${rel_minor_num}/code_freeze"
%>


    <h2>UFT ${release_num} Sprint ${sprint_num} sanity has passed!</h2>

<%
if (code_freeze_phase) {
%>
    <p>
        <span class="emphasize2">SPECIAL REMINDER:</span> <span class="emphasize3">WE ARE IN UFT ${release_num} CODE FREEZE PHASE!</span><br/><br/>
        Approvals from <a href="mailto:avi.genshaft@microfocus.com"><span class="emphasize2">Avi</span></a>,
        <a href="mailto:peng-ji.yin@microfocus.com"><span class="emphasize2">Jerry</span></a>,
        <a href="mailto:ran.bachar@microfocus.com"><span class="emphasize2">Ran</span></a> and
        <a href="mailto:jia.xue2@microfocus.com"><span class="emphasize2">James</span></a> are required for any exceptions
        before using <a href="${unlock_job_url}">force unlock job</a> (context: <code>${status_checks}</code>)!
    </p>
<%
} else {
%>
    <p>
        Code freeze is <span class="emphasize">&nbsp;OFF&nbsp;</span> now!<br/>
        You are able to merge your approved pull requests to official branches.
    </p>
<%
}
%>

    <p>
        <br/>
        Thank you for your cooperation!<br/>
        <a href="mailto:uft.devops.cn@microfocus.com">UFT DevOps Team</a>
    </p>
</body>

<style>
BODY, P, PRE {
    font-family: Calibri,Verdana,Helvetica,sans serif;
    font-size: 12pt;
    color: black;
}
div.caption {
    text-decoration: underline;
    font-size: 105%;
    font-weight: bold;
    margin: 30px 0 10px 0;
}
SPAN.emphasize {
    background-color: yellow;
    font-weight: bolder;
    color: red;
    font-size: 110%;
}
SPAN.emphasize2 {
    font-weight: bolder;
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
def today = new Date().format('MMM.dd, YYYY')
def rubicon_install_link = "file:///\\\\mydastr01.hpeswlab.net\\products\\FT\\QTP\\win32_release\\" + build_num + "\\DVD_Wix\\Setup.exe"
def sh206_install_link = "file:///\\\\10.5.32.206\\Builds\\" + build_num
def unlock_job_url = "http://mydtbld0120.hpeswlab.net:8080/view/Products/view/Git/job/Github.PullRequest.StatusChecks.ForceUnlock/build"
def status_checks = "cd/releases/${rel_major_num}_${rel_minor_num}/sprint${sprint_num}/sanity"
%>


    <p>Hi All,</p>

    <p>UFT Nightly build <span class="emphasize">${build_num}</span> has passed!</p>

    <div class="caption">Code Freeze Reminder</div>
    <div>
<%
if (code_freeze_phase) {
    status_checks = status_checks + "; cd/releases/${rel_major_num}_${rel_minor_num}/code_freeze"
%>
        <span class="emphasize2">SPECIAL REMINDER:</span> <span class="emphasize">WE ARE IN UFT ${release_num} CODE FREEZE PHASE!</span><br/><br/>
<%
}
%>
        We are in <b>UFT ${release_num} Sprint ${sprint_num} Sanity</b> <span class="emphasize">code freeze</span> now.<br/><br/>
        The <b>${branch_name}</b> branch of all <b>QTP</b> repositories, <b>UFTBase</b> and <b>ST</b> are locked and merging to this branch is not allowed,
        however, you are still able to work on the other branches, create and review pull requests.<br/><br/>
        Approvals from <a href="mailto:vika.milgrom@microfocus.com"><span class="emphasize2">Vika</span></a>,
        <a href="mailto:tsachi.ben-zur@microfocus.com"><span class="emphasize2">Tsachi</span></a>,
        <a href="mailto:peng-ji.yin@microfocus.com"><span class="emphasize2">Jerry</span></a>,
        <a href="mailto:ran.bachar@microfocus.com"><span class="emphasize2">Ran</span></a> and
        <a href="mailto:jia.xue2@microfocus.com"><span class="emphasize2">James</span></a> are required for any exceptions
        before using <a href="${unlock_job_url}">force unlock job</a> (context: <code>${status_checks}</code>)!
    </div>

    <div class="caption">UFT ${release_num} Sprint ${sprint_num} Sanity - ${build_num}</div>
    <div>
        Please start sanity as soon as possible and we aim to finish this sanity by the end of day 
        <span class="emphasize">${today}</span>!<br/>
        Please reply with your sanity statuses to this thread only.<br/>
    </div>

    <div class="caption">UFT Installation - ${build_num}</div>
    <ul>
        <li>Install from <a href="${rubicon_install_link}">Rubicon</a></li>
        <li>Install from <a href="${sh206_install_link}">Shanghai 206 Server</a> (need unzip and then install)</li>
        <li>The <b>Lab’s Virtual Machines</b> shall be deployed automatically. (Re)install this build manually in case of any failures.</li>
    </ul>

    <p>
        <br/>
        Thank you for your cooperation!<br/>
        <a href="mailto:uft.devops.cn@microfocus.com">UFT DevOps Team</a>
    </p>
</body>
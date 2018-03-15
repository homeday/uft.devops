<style>
BODY, TABLE, TD, TH, P, PRE {
    font-family: Calibri,Verdana,Helvetica,sans serif;
    font-size: 12pt;
    color: black;
}
H3, A {
    color: #1F497D;
}
SPAN.emphasize {
    font-weight: bolder;
    font-size: 110%;
}
SPAN.emphasize2 {
    font-weight: bolder;
    font-size: 120%;
    color: red;
}
TH, TD {
    padding-right: 10px;
}
TH {
    background-color: #c2d6f0;
}
TD.value > SPAN {
    color: #1F497D;
    font-size: 105%;
    font-weight: bold;
}
PRE {
    color: #1F497D;
}
</style>
<body>

<%
import hudson.model.*
import com.tikal.jenkins.plugins.multijob.*;
import groovy.transform.Field

def org_name = build.getEnvironment().Github_Organization_Name
def repo_name = build.getEnvironment().Github_Repository_Name
def pr_id = build.getEnvironment().Github_PullRequest_ID

def github_url = "https://github.houston.softwaregrp.net/${org_name}/${repo_name}/pull/${pr_id}"

def req_user = build.getEnvironment().Request_UserName
def req_msg = build.getEnvironment().Request_Message

def jenkins_job_url = build.getEnvironment().BUILD_URL + "consoleText"
%>


    <h3>
        Attention! <span class="emphasize2">${req_user}</span> has requested a forced pull request approving review!
    </h3>

    <table>
        <tr>
            <td class="label">Jenkins Job:</td>
            <td class="value"><a href="${jenkins_job_url}"><span>Link</span></a></td>
        </tr>
        <tr>
            <td class="label">Repository:</td>
            <td class="value"><span>${org_name}/${repo_name}</span></td>
        </tr>
        <tr>
            <td class="label">Pull Request:</td>
            <td class="value"><a href="${github_url}"><span>PR #${pr_id}</span></a></td>
        </tr>
        <tr>
            <td class="label">Requested By:</td>
            <td class="value"><span>${req_user}</span></td>
        </tr>
    </table>

    <p>
        Following is the message from <span class="emphasize">${req_user}</span>:<br/>

        <pre>${req_msg}</pre>
    </p>

    <p>
        <br/>
        If you have already acknowledged and approved this request, please ignore this email.<br/><br/>

        Thanks,<br/>
        <a href="mailto:uft.devops.cn@hpe.com">UFT DevOps Team</a>
    </p>
</body>
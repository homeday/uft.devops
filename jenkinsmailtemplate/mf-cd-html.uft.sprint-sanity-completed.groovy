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
%>


    <h2>UFT ${release_num} Sprint ${sprint_num} sanity has passed!</h2>

    <p>
        Code freeze is <span class="emphasize">&nbsp;OFF&nbsp;</span> now!<br/>
        You are able to merge your approved pull requests to official branches.
    </p>

    <p>
        <br/>
        Thank you for your cooperation!<br/>
        <a href="mailto:uft.devops.cn@hpe.com">UFT DevOps Team</a>
    </p>
</body>
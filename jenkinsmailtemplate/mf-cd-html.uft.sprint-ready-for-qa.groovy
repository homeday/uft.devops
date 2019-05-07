<style>
BODY, TABLE, TD, TH, P, PRE {
    font-family: Calibri,Verdana,Helvetica,sans serif;
    font-size: 12pt;
    color: black;
}
H2, A {
    color: #1F497D;
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
TABLE.t2 TD.value A {
    font-size: 85%;
}
SPAN.emphasize {
    background-color: green;
    font-weight: bolder;
    color: white;
    font-size: 110%;
}
TABLE.pre TD {
    background-color: yellow;
}
TABLE.pre PRE {
    font-weight: bold;
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
def build_label = "UFT_${rel_major_num}_${rel_minor_num}_SPRINT_${sprint_num}"
def build_notes_url = "https://rndwiki.houston.softwaregrp.net/confluence/display/UFT/UFT+${rel_major_num}.${rel_minor_num}+Build+Notes"

def msi_root_uri = "\\\\mydanas01.swinfra.net\\products\\FT\\QTP\\win32_release\\${build_label}"
def uft_msi_uri = "${msi_root_uri}\\DVD\\Unified Functional Testing\\MSI"
def alm_plugin_msi_uri = "${msi_root_uri}\\DVD\\ALMPlugin\\MSI"
def rrv_msi_uri = "${msi_root_uri}\\DVD\\RunResultsViewer\\MSI"
def pftw_setup_uri = "${msi_root_uri}\\UFTSetup.exe"
def hotfix_uri = "${msi_root_uri}\\HotFix"

def prepend_msg = build.getEnvironment().Prepend_Messages
%>

<%
if (prepend_msg?.trim()) {
%>
    <table class="pre">
        <tr><td><pre>${prepend_msg}</pre></td></tr>
    </table>
    <br/>
<%
}
%>

    <h2>UFT ${release_num} Sprint ${sprint_num} is ready for QA!</h2>

    <table>
        <tr>
            <td class="label">Build Label:</td>
            <td class="value"><span>${build_label}</span></td>
        </tr>
        <tr>
            <td class="label">Build Number:</td>
            <td class="value"><span>${build_num}</span></td>
        </tr>
        <tr>
            <td class="label">Build Notes:</td>
            <td class="value"><a href="${build_notes_url}"><span>Click here</span></a></td>
        </tr>
    </table>

    <br/>

    <table class="t2">
        <tr><th>PRODUCT</th><th>LOCATION</th></tr>
        <tr><td class="label">UFT ${release_num}</td><td class="value"><a href="file:///${uft_msi_uri}">${uft_msi_uri}</a></td></tr>
        <tr><td class="label">ALMPlugin ${release_num}</td><td class="value"><a href="file:///${uft_msi_uri}">${alm_plugin_msi_uri}</a></td></tr>
        <tr><td class="label">UFT Result Viewer ${release_num}</td><td class="value"><a href="file:///${uft_msi_uri}">${rrv_msi_uri}</a></td></tr>
        <tr><td class="label">PFTW ${release_num}</td><td class="value"><a href="file:///${uft_msi_uri}">${pftw_setup_uri}</a></td></tr>
        <tr><td class="label">UFT ${release_num} HotFix</td><td class="value"><a href="file:///${uft_msi_uri}">${hotfix_uri}</a></td></tr>
    </table>

    <p>
        <br/>
        Thank you for your cooperation!<br/>
        <a href="mailto:uft.devops.cn@microfocus.com">UFT DevOps Team</a>
    </p>
</body>

<STYLE>
  BODY, TABLE, TD, TH, P, PRE {
    font-family:Verdana,Helvetica,sans serif;
    font-size:12px;
    color:black;
  }

  TABLE {
    border-spacing: 0;
  }

  .error {
    color: red;
    font-weight: bold;
  }

  TH, TD {
    padding: 5px 10px;
  }

  TH {
    color:white;
    background-color:#0000C0;
    font-size:120%;
    text-align: left;
  }

  .online {
    color: green;
  }

  .offline, .disk-warn2 {
    color: white;
    background-color: red;
    font-weight: bold;
    font-size: 110%;
  }

  .disk-warn {
    color: red;
    font-weight: bold;
    font-size: 110%;
  }

  .disk-ok {
    color: green;
  }

</STYLE>

<%
File nodeStatusFile = new File(build.workspace.toString() + "/nodes_status.tmp");
def nodeStatusFileExist = nodeStatusFile.exists();
if (nodeStatusFileExist) {
  nodeStatusFile.eachLine { line ->
    def tmplist = line.tokenize('|');
    if (tmplist && tmplist.size() > 0) {

    }
  };
}
%>

<BODY>

  <H3>Disk Space Alarms</H3>

<% if (!nodeStatusFileExist) { %>
  <H3 class="error">The node status file does not exist!</H3>
<% } else { %>

  <!-- Table 1: alarms table -->
  <TABLE width="100%">

    <TR>
      <TH>Computer</TH>
      <TH>Online</TH>
      <TH>Drive</TH>
      <TH>Threshold</TH>
      <TH>Disk: Avail / Total</TH>
      <TH>Disk: Available (%)</TH>
      <TH> Action </TH>
    </TR>

<%nodeStatusFile.eachLine { line ->
    def tmplist = line.tokenize('|');

    def nodeStatus = '';
    def computer = '';
    def online = '';
    def drive = '';
    def threshold = '';
    def totalDisk = '';
    def availDisk = '';
    def availPercent = '';

    if (tmplist) {
      if (tmplist.size() > 0)
        nodeStatus = tmplist[0];
      if (tmplist.size() > 1)
        computer = tmplist[1];
      if (tmplist.size() > 2)
        online = tmplist[2];
      if (tmplist.size() > 3)
        drive = tmplist[3];
      if (tmplist.size() > 4)
        threshold = tmplist[4];
      if (tmplist.size() > 5)
        totalDisk = tmplist[5];
      if (tmplist.size() > 6)
        availDisk = tmplist[6];
      if (tmplist.size() > 7)
        availPercent = tmplist[7];
    }

    if (nodeStatus != 'OK') {
%>

    <TR>
      <TD>${computer}</TD>

    <% if (online == 'Online') { %>
      <TD class="online">Online</TD>
    <% } else { %>
      <TD class="offline">Offline</TD>
    <%} %>

      <TD>${drive}</TD>

      <TD>${threshold}</TD>

    <% if (availDisk) { %>
      <TD><span class="disk-warn">${availDisk}</span> / <span>${totalDisk}</span></TD>
    <% } else { %>
      <TD></TD>
    <% } %>

      <TD class="disk-warn2">${availPercent}</TD>
    <% if (online == 'Offline') { %>
      <TD><a href="http://mydtbld0211.swinfra.net:8080/job/Bring_Slave_Online/buildWithParameters?token=UFTBUILDTOKEN&host_name=${computer}">Make it online!</TD>
    <% } %>
    </TR>

<% }}; %>

  </TABLE>


  <H3>Other Computers</H3>

  <!-- Table 2: other computers table -->
  <TABLE width="100%">

    <TR>
      <TH>Computer</TH>
      <TH>Online</TH>
      <TH>Drive</TH>
      <TH>Threshold</TH>
      <TH>Disk: Avail / Total</TH>
      <TH>Disk: Available (%)</TH>
    </TR>

<%nodeStatusFile.eachLine { line ->
    def tmplist = line.tokenize('|');

    def nodeStatus = '';
    def computer = '';
    def online = '';
    def drive = '';
    def threshold = '';
    def totalDisk = '';
    def availDisk = '';
    def availPercent = '';

    if (tmplist) {
      if (tmplist.size() > 0)
        nodeStatus = tmplist[0];
      if (tmplist.size() > 1)
        computer = tmplist[1];
      if (tmplist.size() > 2)
        online = tmplist[2];
      if (tmplist.size() > 3)
        drive = tmplist[3];
      if (tmplist.size() > 4)
        threshold = tmplist[4];
      if (tmplist.size() > 5)
        totalDisk = tmplist[5];
      if (tmplist.size() > 6)
        availDisk = tmplist[6];
      if (tmplist.size() > 7)
        availPercent = tmplist[7];
    }

    if (nodeStatus == 'OK') {
%>

    <TR>
      <TD>${computer}</TD>

<%if (online == 'Online') { %>
      <TD class="online">Online</TD>
<%} else { %>
      <TD class="offline">Offline</TD>
<%} %>

      <TD>${drive}</TD>

      <TD>${threshold}</TD>

<%if (availDisk) { %>
      <TD><span class="disk-ok">${availDisk}</span> / <span>${totalDisk}</span></TD>
<%} else { %>
      <TD></TD>
<%} %>

      <TD class="disk-ok">${availPercent}</TD>

    </TR>

<% }}; %>

  </TABLE>

<% } %>

</BODY>

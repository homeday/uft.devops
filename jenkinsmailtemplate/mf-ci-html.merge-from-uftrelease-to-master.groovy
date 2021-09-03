<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><title></title></head>
	<style type="text/css">
		/* Client-specific Styles */
		#outlook a {padding:0;}
		body{
			width:100% !important; 
			-webkit-text-size-adjust:100%; 
			-ms-text-size-adjust:100%; 
			margin:0; 
			padding:5;
			font-family:Century
		} 
		/* Hotmail */
		a:active, a:visited, a[href^="tel"], a[href^="sms"] { text-decoration: none; color: #000001 !important; pointer-events: auto; cursor: default;}
		table { margin-top: 10px; }
		table td {valign: top; margin:4px}
		.SUCCESS {color: Green;}
		.FAILURE {color: Red;}
		.UNSTABLE {color: Yellow;}
		.shadow {border-radius: 5px; box-shadow: 1px 1px 1px 1px darkgray; }
		.build_detail_td { width:25%;}
		.merge-result.merged {color: Green;}
		.merge-result.not-merged {color: Red;}
		.repo-Include {color: Green;}
		.repo-Exclude {color: Red;}
		.error-message {color: Red; font-weight: bold;}
	  </style>
	
	<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" style="margin: 0px; padding: 0px; background-color: #e2e2e2;" bgcolor="#e2e2e2">
		<%
			import hudson.model.*
			import com.tikal.jenkins.plugins.multijob.*;
			import groovy.transform.Field
			// To fetch build logs
			import hudson.console.ConsoleNote
			
			def env = build.getEnvironment()

			def JobUrl = env.BUILD_URL
			def ProjectName= (build.getProject().name) ?: ""
			def ServerName = (build.getBuiltOn().getDisplayName()) ?: ""
			
			def build_status_icon = env.JENKINS_URL + "static/ad512159/images/32x32/" + ((build.result.toString() == "SUCCESS") ? "blue.png" : (build.result.toString() == "FAILURE") ? "red.png" : "yellow.png")
			def icon_base64=new URL("${build_status_icon}").getBytes( useCaches: true, allowUserInteraction: false, requestProperties: ["User-Agent": "Groovy Sample Script"])

			def sourceBranch = env.Source_Branch
			def targetBranch = env.Target_Branch
			def excludeRepos = env.exclude_repos

			def mergeResultsFile = build.getWorkspace().child("merge_results.txt")
			def errorFile = build.getWorkspace().child("error.txt")

			def dismissUrlBase = "http://mydtbld0211.swinfra.net:8080/job/Merge.From.UFTRelease.To.master.CommitDismission/buildWithParameters?token=UFT_TOKEN"
			dismissUrlBase.concat("&cause=").concat(java.net.URLEncoder.encode("Via link from merge job email", "UTF-8"))
		%>
		<table width="100%" cellpadding="0" cellspacing="0"><tr><td valign="center"><tr><td>
			<table style="background-color: #FFF" bgcolor="#FFF" class="shadow" width="80%" align="center" cellpadding="5" cellspacing="0">
				<!-- status image and text -->
				<tr>
					<td>
						<table width="20%"  align="left" cellpadding="0" cellspacing="0">
							<tr>
								<td style="width:5%">
									<img src="data:image/png;base64, ${icon_base64.encodeBase64().toString()}" />
								</td>
								<td>
									<span style="font-size: 28px" class="${build.result.toString()}"><b>${build.result}</b></span>
								</td>
							</tr>
						</table>
					</td>
				</tr>

				<!-- major description -->
				<tr>
					<td>
						<span style="font-size: 20px">Merge: <b>${sourceBranch} --&gt; ${targetBranch}</b></span>
					</td>
				</tr>

				<!-- parameters and environment info -->
				<tr>
					<td style="border-top:1px solid #A8A8A8; padding-top: 8px">
						<table width="100%" align="left" cellpadding="0" cellspacing="0">
							<tr>
								<td class="build_detail_td">Job URL</td>
								<td valign="top" ><a href="${JobUrl}">${ProjectName}</a></td>
							</tr>
							<tr>
								<td class="build_detail_td">Built On</td>
								<td valign="top">${ServerName}</td>
							</tr>
							<tr>
								<td class="build_detail_td">Date of Build</td>
								<td valign="top">${it.timestampString}</td>
							</tr>
						</table>
					</td>
				</tr>
				<br />

				<!-- merged repositories -->
				<tr>
					<td>
						<span>Please merge the <b>Exclude</b> repositories manually if any changes are detected!</span>
						<br />
						<span>You can also dismiss the <b>Not Merged</b> commit if it is certain that the commit shall never be merged. 
						A blank page will be shown when the dismission link is clicked.</span>
						<br />
						<table class="shadow" width="100%" style="border: 1px solid #e2e2e2" cellpadding="0" cellspacing="0">
							<tr style="background-color: #A8A8A8" bgcolor="#A8A8A8" ><td><h3 style="color: White">Merged Repositories</h3></td></tr>
							<tr><td><table width="100%" cellpadding="0" cellspacing="0">
								<%
									if (mergeResultsFile.exists()) {
								%>

								<tr style="border-bottom: 1px solid #e2e2e2" >
									<th align="left">Repository</th>
									<th align="left">Include/Exclude</th>
									<th align="left">Ahead</th>
									<th align="left">Last Commit</th>
									<th align="left">Merge Result</th>
									<th align="left">Dismission</th>
								</tr>

								<% 		
										mergeResultsFile.readToString().eachLine(){ line -> 
											def splitArray = line.split(',')
											def repo = splitArray.size() > 0 ? splitArray[0] : ''
											def incOrExc = splitArray.size() > 1 ? splitArray[1] : ''

											def commitSHAOrErrorInd = splitArray.size() > 2 ? splitArray[2] : ''
											if (commitSHAOrErrorInd == '[ERROR]') {
												def errorMessage = splitArray.size() > 3 ? splitArray[3..-1].join(',') : ''
								%>

								<tr>
									<td valign="top">${repo}</td>
									<td valign="top"><span class="repo-${incOrExc}">${incOrExc}</span></td>
									<td class="error-message" valign="top" colspan="4">${errorMessage}</td>
								</tr>

								<%
												return
											}

											def commitSHA = commitSHAOrErrorInd
											if (commitSHA == 'null') { commitSHA = '' }
											def dimissionState = splitArray.size() > 3 ? splitArray[3] : ''
											if (dimissionState == 'null') { dimissionState = '' }
											def aheadBefore = splitArray.size() > 4 ? splitArray[4] : '0'
											if (aheadBefore == '' || aheadBefore == 'null') { aheadBefore = '0' }
											def aheadAfter = splitArray.size() > 5 ? splitArray[5] : '0'
											if (aheadAfter == '' || aheadAfter == 'null') { aheadAfter = '0' }
											def isMerged = aheadBefore != '0' && aheadAfter == '0'
											if (incOrExc == 'Include' && !isMerged && aheadBefore == '0') return
											def mergeResultClass = isMerged ? 'merged' : 'not-merged'
											def mergeResultText = isMerged ? 'Merged' : 'Not Merged'
											def dismissFullUrl = dismissUrlBase
												.concat("&Repository=").concat(java.net.URLEncoder.encode(repo, "UTF-8"))
												.concat("&BranchName=").concat(java.net.URLEncoder.encode(sourceBranch, "UTF-8"))
												.concat("&CommitSHA=").concat(java.net.URLEncoder.encode(commitSHA, "UTF-8"))

											def commitShortSHA = commitSHA.length() >= 7 ? commitSHA[0..6] : commitSHA
											def commitGHEUrl = "https://github.houston.softwaregrp.net/uft/${repo}/commit/${commitSHA}"
								%>

								<tr>
									<td valign="top">${repo}</td>
									<td valign="top"><span class="repo-${incOrExc}">${incOrExc}</span></td>
									<td valign="top">${aheadBefore}</td>
									<td valign="top"><a href="${commitGHEUrl}" target="_blank">${commitShortSHA}</a></td>
									<td valign="top"><span class="merge-result ${mergeResultClass}">${mergeResultText}</span></td>
									<td valign="top">
								<%			if (dimissionState == "Dismissed") { %>
										<span><b>Dismissed (No need to merge)</b></span>
								<%			} else if (!isMerged && incOrExc == 'Include' && aheadBefore != '0') { %>
										<a href="${dismissFullUrl}" target="_blank">Don't merge this commit ${commitSHA}</a>
								<%			} %>
									</td>
								</tr>

								<% 		
										}
									}
								%>
							</table></td></tr>
						</table>
					</td>
				</tr>
			</table>
			<br />
			<!-- Footer -->
			<table align="center" width="80%" cellpadding="5" cellspacing="0">
				<tr>
					<td>
						<p align="center" style="color: darkgray">
							This is an auto-generated email. If you don't want to receive this mail anymore, contact UFT <a href="mailto:narendrakumar.cheajra@microfocus.com">DevOps</a> team.
						</p>
						<hr align="center" width="60%" />
					</td>
				</tr>
			</table>
		</td></tr></table>
	</body>
</html>

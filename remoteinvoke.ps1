[CmdletBinding(SupportsShouldProcess=$True)]
param (
	[Parameter(Mandatory=$true)]
    [string]$RemoteJobLink = $null,
    [Parameter(Mandatory=$true)]
	[string]$RemoteJobToken = $null,
    [string]$RemoteJobLinkParams = $null
)


$InvokenURL = ""
if (!$RemoteJobLinkParams) {
    $InvokenURL = "{0}/build?token={1}&delay=0sec" -f $RemoteJobLink,$RemoteJobToken
} else {
    $InvokenURL = "{0}/buildWithParameters?{2}&token={1}&delay=10sec" -f $RemoteJobLink,$RemoteJobToken,$RemoteJobLinkParams
}

Write-Output "Invoke URL = ${InvokenURL}"

$Rsp = Invoke-WebRequest -Uri $InvokenURL -Method Post 
$Headers = $Rsp.Headers
$QueueItemURL = "{0}api/json" -f $Headers.Location 
$Rsp = Invoke-WebRequest -Uri $QueueItemURL -Method Get 
$JobURL = ""
while ($Rsp.StatusCode -eq 200) {
    #try to get job url
    try {
        $Content = $Rsp.Content | ConvertFrom-Json
        $executable  = Get-Member -InputObject $Content | where-object {$_.Name -eq "executable"} 
        if ( $executable ) {
            $JobURL = $Content.executable.url
            Write-Output "Get Job URL result = ${JobURL}"
            break
        }
        Start-Sleep -seconds 5
        $Rsp = Invoke-WebRequest -Uri $QueueItemURL -Method Get 
    }
    catch [Exception] {
        Write-Output $_.Exception|format-list -force
        Write-Output "Get Job URL error"
        throw
    }
}

$result = "FAILURE"
$Rsp = Invoke-WebRequest -Uri "${JobURL}api/json" -Method Get 
while ($Rsp.StatusCode -eq 200) {
    #Pending for job complete
    try {
        $Content = $Rsp.Content | ConvertFrom-Json
        $building  = Get-Member -InputObject $Content | where-object {$_.Name -eq "building"} 
        if ( $building -And $Content.building -eq $false ) {
            #job has complete
            $result = $Content.result
            break
        }
        Start-Sleep -seconds 30
        Write-Output "Job is running now"
        $Rsp = Invoke-WebRequest -Uri "${JobURL}api/json" -Method Get
    }
    catch [Exception] {
        Write-Output $_.Exception|format-list -force
        Write-Output "Get Job result error"
        throw
    }
}

$Rsp = Invoke-WebRequest -Uri "${JobURL}/consoleText" -Method Get
$Content = $Rsp.Content 
Write-Output "The output log from remote job:"
Write-Output "======================================================="
Write-Output $Content
Write-Output "======================================================="
switch ($result) {
    "FAILURE" { 
        exit 1
    }
    "ABORT" { 
        exit 1
    }
    "SUCCESS" { 
        exit 0
    }
    "UNSTABLE" { 
        exit 0
    } 
}










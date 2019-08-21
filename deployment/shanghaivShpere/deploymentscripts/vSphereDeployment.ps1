[CmdletBinding(SupportsShouldProcess=$True)]
param (
	[Parameter(Mandatory=$true)]
    [string]$MachineName,
    [Parameter(Mandatory=$true)]
    [string]$BuidlVersion,
    [Parameter(Mandatory=$true)]
    [string]$Application = "uft",
    [string]$CleanMode = "resnapshot",
    [string]$GAVersion = "",
    [string]$PatchID = "",
    [string]$NotifyUri = ""
)

function Update-DeploymentsToDB {
    #[CmdletBinding(SupportsProcess=$True)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$NotifyUri,
        [Parameter(Mandatory=$true)]
        [string]$name,
        [Parameter(Mandatory=$true)]
        [string]$state
    )
    if ("" -eq $NotifyUri) {
        return
    }
        
    $Body = @{
        name = $name
        state = $state
        version = $BuidlVersion
    }
    $json = $Body | ConvertTo-Json
    $contentType = "application/json"  
    $Rsp = $null
    try {
        
        Write-Host "NotifyUri = ${NotifyUri}" -ForegroundColor Green -BackgroundColor Black
        $Rsp = Invoke-WebRequest -Uri $NotifyUri -Method Put -Body $json -ContentType $contentType -UseBasicParsing
        Write-Host $name ":" $state ":" $Rsp.StatusCode -ForegroundColor Green -BackgroundColor Black
    }
    catch [Exception] {
        Write-Host $_.Exception -force -ForegroundColor Red -BackgroundColor Black | format-list 
        Write-Host "Update-DeploymentsToDB " $name -ForegroundColor Red -BackgroundColor Black
    }
}

Add-PSSnapin "VMware.VimAutomation.Core"
Update-DeploymentsToDB -NotifyUri $NotifyUri -name $MachineName.Split(".")[0] -state "deploying"
Import-Module -Force ".\vSphereDeployment.psm1"

$result=$false
try {
	Write-Host "Install ${BuidlVersion} ${Application} at machine ${MachineName} with ${CleanMode} mode Start" -ForegroundColor Green -BackgroundColor Black
	$result = Install-Application -MachineName $MachineName `
            -BuidlVersion $BuidlVersion `
            -CleanMode $CleanMode `
            -Application $Application `
            -GAVersion $GAVersion -PatchID $PatchID
}
catch [Exception] {
	Write-Host $_.Exception -force -ForegroundColor Red -BackgroundColor Black | format-list 
	Update-DeploymentsToDB -NotifyUri $NotifyUri -name $MachineName.Split(".")[0] -state "failure"
}
            
if ($result -eq $true) {
    Write-Host "It is successful to install ${BuidlVersion} at machine ${MachineName} with ${CleanMode} mode " -ForegroundColor Green -BackgroundColor Black
    Update-DeploymentsToDB -NotifyUri $NotifyUri -name $MachineName.Split(".")[0] -state "success"
    exit 0
}
Write-Host "It is failed to install ${BuidlVersion} at machine ${MachineName} with ${CleanMode} mode " -ForegroundColor Red -BackgroundColor Black
Update-DeploymentsToDB -NotifyUri $NotifyUri -name $MachineName.Split(".")[0] -state "failure"
exit 1

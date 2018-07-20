
#using module ".\CSADeployment.psm1"
[CmdletBinding(SupportsShouldProcess=$True)]
param (
	[Parameter(Mandatory=$true)]
    [string]$CSAName,
    [Parameter(Mandatory=$true)]
    [string]$BuidlVersion,
    [Parameter(Mandatory=$true)]
    [string]$Application = "uft",
    [string]$CleanMode = "uninstall",
    [string]$SUBSCRIPTION_ID = "",
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
        $Rsp = Invoke-WebRequest -Uri $NotifyUri -Method Put -Body $json -ContentType $contentType
        Write-Host $name ":" $state ":" $Rsp.StatusCode -ForegroundColor Green -BackgroundColor Black
    }
    catch [Exception] {
        Write-Host $_.Exception | format-list -force -ForegroundColor Red -BackgroundColor Black
        Write-Host "Update-DeploymentsToDB " $name -ForegroundColor Red -BackgroundColor Black
    }
}

Update-DeploymentsToDB -NotifyUri $NotifyUri -name $CSAName.Split(".")[0] -state "deploying"
#subscription id = 8a471d9161ccf744016261c2513543e5
Import-Module -Force ".\CSADeployment.psm1"

Write-Host "Install ${BuidlVersion} ${Application} at machine ${CSAName} with ${CleanMode} mode Start" -ForegroundColor Green -BackgroundColor Black
$result = Install-Application -CSAName $CSAName `
            -BuidlVersion $BuidlVersion `
            -CleanMode $CleanMode `
            -SUBSCRIPTION_ID $SUBSCRIPTION_ID -Application $Application `
            -GAVersion $GAVersion -PatchID $PatchID
if ($result -eq $true) {
    Write-Host "It is successful to install ${BuidlVersion} at machine ${CSAName} with ${CleanMode} mode " -ForegroundColor Green -BackgroundColor Black
    Update-DeploymentsToDB -NotifyUri $NotifyUri -name $CSAName.Split(".")[0] -state "success"
    exit 0
}
Write-Host "It is failed to install ${BuidlVersion} at machine ${CSAName} with ${CleanMode} mode " -ForegroundColor Red -BackgroundColor Black

Update-DeploymentsToDB -NotifyUri $NotifyUri -name $CSAName.Split(".")[0] -state "failure"

exit 1



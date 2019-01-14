
#using module ".\CSADeployment.psm1"
[CmdletBinding(SupportsShouldProcess=$True)]
param (
	#[Parameter(Mandatory=$true)]
    [string]$CSAName="myd-hvm00241.swinfra.net",
    #[Parameter(Mandatory=$true)]
    [string]$BuidlVersion="14.52.2233.0",
    #[Parameter(Mandatory=$true)]
    [string]$Application = "rpa",
    [string]$CleanMode = "resnapshot",
    [string]$SUBSCRIPTION_ID = "2c90d38b6832aec7016835acda59127c",
    [string]$GAVersion = "",
    [string]$PatchID = "",    
    [string]$NotifyUri = ""
    
)

function Update-DeploymentsToDB {
    #[CmdletBinding(SupportsProcess=$True)]
    param (
        [string]$NotifyUri,
        [string]$name,
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
        Write-Host "NotifyUri = " $NotifyUri -ForegroundColor Green -BackgroundColor Black
        $Rsp = Invoke-WebRequest -Uri $NotifyUri -Method Put -Body $json -ContentType $contentType
        Write-Host $name ":" $state ":" $Rsp.StatusCode -ForegroundColor Green -BackgroundColor Black
    }
    catch [Exception] {
        Write-Host $_.Exception -force -ForegroundColor Red -BackgroundColor Black | format-list 
        Write-Host "Update-DeploymentsToDB " $name -ForegroundColor Red -BackgroundColor Black
    }
}


$env:Rubicon_Username="EMEA\btoabuild"
$env:Rubicon_Password="aid.sat-63"
$env:CSAAccount="swinfra.net\_ft_auto"
$env:CSAPassword="W3lcome1"

Update-DeploymentsToDB -NotifyUri $NotifyUri -name $CSAName.Split(".")[0] -state "deploying"
#subscription id = 8a471d9161ccf744016261c2513543e5
Import-Module -Force ".\CSADeployment.psm1"

Write-Host "Install ${BuidlVersion} ${Application} at machine ${CSAName} with ${CleanMode} mode Start" -ForegroundColor Green -BackgroundColor Black
$result= $false
try {
    $result = Install-Application -CSAName $CSAName `
            -BuidlVersion $BuidlVersion `
            -CleanMode $CleanMode `
            -SUBSCRIPTION_ID $SUBSCRIPTION_ID -Application $Application `
            -GAVersion $GAVersion -PatchID $PatchID
}
catch [Exception] {
    Write-Host $_.Exception -force -ForegroundColor Red -BackgroundColor Black | format-list 
    Update-DeploymentsToDB -NotifyUri $NotifyUri -name $CSAName.Split(".")[0] -state "failure"
}
if ($result -eq $true) {
    Write-Host "It is successful to install ${BuidlVersion} at machine ${CSAName} with ${CleanMode} mode " -ForegroundColor Green -BackgroundColor Black
    Update-DeploymentsToDB -NotifyUri $NotifyUri -name $CSAName.Split(".")[0] -state "success"
    exit 0
}
Write-Host "It is failed to install ${BuidlVersion} at machine ${CSAName} with ${CleanMode} mode " -ForegroundColor Red -BackgroundColor Black

Update-DeploymentsToDB -NotifyUri $NotifyUri -name $CSAName.Split(".")[0] -state "failure"

exit 1



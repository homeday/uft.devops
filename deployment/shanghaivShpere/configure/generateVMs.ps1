
[CmdletBinding(SupportsShouldProcess=$True)]
param (
    [Parameter(Mandatory=$true)]
    [string]$DeployFile = ".\DeploymentVMs.xml",
    [Parameter(Mandatory=$true)]
    [string]$PRODUCT_RELEASE = "shvCenter",
    [Parameter(Mandatory=$true)]
    [string]$BUILD_NUMBER = "UFT_14_50_Setup_Last"
    
)
#Set-ExecutionPolicy RemoteSigned

$HasDeployments=$false
$DevOpsPortalURL=""
$DevOpsPortalIP=""
$DevOpsPortalPort=""
$GlobalDict=@{}

function Read-HasDeployments {
    # [CmdletBinding(SupportsShouldProcess=$True)]
    # param (
    #     [string]$PatchID = ""
    # )
    $HasDeployments = $false
    $ReqUri = $DevOpsPortalURL + $ReleasePath
    try {  
        $Rsp = Invoke-WebRequest -Uri $ReqUri -Method Get
        if ($Rsp.StatusCode -eq 200) {  
            #try to get job url
            $Content = $Rsp.Content | ConvertFrom-Json
            if ($Content.Length -gt 0) 
            {
                $HasDeployments = $Content[0].hasdeployments -And $Content[0].isvalid
            } 
        }  
    }
    catch [Exception] {
        Write-Host $_.Exception|format-list -force
        Write-Host "Get Rsp error " + $ReqUri 
    }
    return $HasDeployments
}

function Read-DeploymentsFromDB {
    param (
        [ref]$DeploymentsFromDB,
        [ref]$DeploymentsDel
    )
    
    $ReqUri = $DevOpsPortalURL + $DeploymentsPath
    try {
        $Rsp = Invoke-WebRequest -Uri $ReqUri -Method Get
        if ($Rsp.StatusCode -eq 200) {
         #try to get job url
            $DeploymentsFromDB.Value.Clear()
            $DeploymentsDel.Value.Clear()
            $Content = $Rsp.Content | ConvertFrom-Json
            if ($Content.Length -gt 0) {
                $Content | ForEach-Object { 
                    $DeploymentsFromDB.Value[$_.name] = $_
                    $DeploymentsDel.Value.Add($_.name)
                }
            }
        }
    }
    catch [Exception] {
        Write-Host $_.Exception|format-list -force
        Write-Host "Read-DeploymentsFromDB " + $ReqUri
    }
    
}

function Update-DeploymentsToDB {
    #[CmdletBinding(SupportsProcess=$True)]
    param (
        [System.Collections.Hashtable]$DeploymentItemFile,
        [ref]$DeploymentsDel,
        [ref]$DeploymentsFromDB
    )
    $name = $DeploymentItemFile["VM_NAME"]
    $DeploymentsDel.Value.Remove($name)
    $ReqUri = $DevOpsPortalURL + $DeploymentsPath
    $Body = @{
        name = $DeploymentItemFile["VM_NAME"]
        ip = $DeploymentItemFile["VM_IP"]
        domain = $DeploymentItemFile["VM_DOMAIN"]
        team = $DeploymentItemFile["VM_Description"] 
        #comments = "<div><div>username : appsadmin</div><div>password : appsadmin</div></div>"  
    }
    $json = $Body | ConvertTo-Json
    $contentType = "application/json"  
    $Rsp = $null
    try {
        if ($DeploymentsFromDB.Value.Contains($name)) {
            #update DB  -ContentType "application/json"
            $Rsp = Invoke-WebRequest -Uri $ReqUri -Method Put -Body $json -ContentType $contentType
        } else {
            $Rsp = Invoke-WebRequest -Uri $ReqUri -Method Post -Body $json -ContentType $contentType
        }
        Write-Host $name
        Write-Host $Rsp.StatusCode
    }
    catch [Exception] {
        Write-Host $_.Exception | format-list -force
        Write-Host "Update-DeploymentsToDB " + $name
    }
}

function Remove-DeploymentsInDB {
    param (
        $DeploymentsDel
    )
    $DeploymentsDel | ForEach-Object { 
        $ReqUri = $DevOpsPortalURL + $DeploymentsPath
        $Body = @{
            name = $_
        }
        $contentType = "application/json"
        $json = $Body | ConvertTo-Json
        try {
            $Rsp = Invoke-WebRequest -Uri $ReqUri -Method Delete -Body $json -ContentType $contentType
            Write-Host $name
            Write-Host $Rsp.StatusCode
        } catch [Exception] {
            Write-Host $_.Exception | format-list -force
            Write-Host "Remove-DeploymentsInDB"
        }
    }
}


try {
    $GlobalDict=@{}
    $DeployXML = [xml] (Get-Content $DeployFile)

    <#---------------------- Get Global Variables --------------------- #>
    $GlobalPropXML = $DeployXML.SelectSingleNode("//GlobalProperties")
    $GlobalPropertiesSTR = ""
    $GlobalPropXML.ChildNodes | 
        ForEach-Object { 
            $GlobalDict.Set_Item($_.Name, $_.InnerText)
            if ( $_.Name -eq "DevOpsPortalIP" ) { $DevOpsPortalIP=$_.InnerText}
            if ( $_.Name -eq "DevOpsPortalPort" ) { $DevOpsPortalPort=$_.InnerText}
            #$GlobalPropertiesSTR += $_.Name.ToUpper() + "=" + $_.InnerText + "`n" 
        }
    $GlobalDict.Set_Item("BUILD_NUMBER", $BUILD_NUMBER)   

    $DevOpsPortalURL="http://" + $DevOpsPortalIP + ":" + $DevOpsPortalPort
    $ReleasePath="/api/releases/" + $PRODUCT_RELEASE.ToLower()
    $DeploymentsPath="/api/deployments/" + $PRODUCT_RELEASE.ToLower()     
    <# ---------------------------------------------------------------- #>

    $HasDeployments = Read-HasDeployments
    $DeploymentsFromDB=@{}
    $DeploymentsDel=New-Object System.Collections.ArrayList
    if ($HasDeployments) {
        Read-DeploymentsFromDB([ref]$DeploymentsFromDB) ([ref]$DeploymentsDel)
    }


    $DeployXML.SelectNodes("//hosts/host") | 
    ForEach-Object { 
        $GlobalDictForItem = $GlobalDict.Clone()
        $HostName = ""
        $machineDomain = $GlobalDictForItem["VM_DOMAIN"]
        $_.ChildNodes | 
        ForEach-Object {
                    if ($_.Name -eq "VM_NAME") { $HostName = $_.InnerText }
                    if ($_.Name -eq "VM_DOMAIN") { $machineDomain = $_.InnerText }
                    if ($_.Name -eq "USER_EMAIL") { 
                        $GlobalDictForItem.Set_Item("NOTIFICATION_EMAIL", $GlobalDictForItem["NOTIFICATION_EMAIL"] + "," + $_.InnerText)
                    } else {
                        $GlobalDictForItem.Set_Item($_.Name, $_.InnerText)
                    }
                 }
        $PerHostSTR = ""
        $IP = (Test-Connection -ComputerName "${HostName}.${machineDomain}" -count 1).IPV4Address.IPAddressToString
        $PerHostSTR += "VM_IP=" + $IP + "`n"
        $GlobalDictForItem.Set_Item("MAIL_SUBJECT", "UFT Deployment: ${HostName} $($GlobalDictForItem["BUILD_NUMBER"]) Deployment is")
        $GlobalDictForItem.Set_Item("VM_IP", $IP)
        if ($HasDeployments -eq $True) {
            $GlobalDictForItem.Set_Item("NotifyUri", $DevOpsPortalURL + $DeploymentsPath)
        }
        $GlobalDictForItem.GetEnumerator() | ForEach-Object {
            $PerHostSTR  += $_.Name + "=" + $_.Value + "`n"
        }
    
        $PerHostSTR | Out-File -FilePath "$HostName.txt" -Encoding "ASCII"
        Write-Output "$HostName.txt `n===============`n$PerHostSTR"

        if ($HasDeployments) {
            Update-DeploymentsToDB($GlobalDictForItem) ([ref]$DeploymentsDel) ([ref]$DeploymentsFromDB)
        }
    }

    if ($HasDeployments) {
        Remove-DeploymentsInDB($DeploymentsDel)
    }
    exit 0
}
catch [Exception]{
    exit 1
}



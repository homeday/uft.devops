[CmdletBinding(SupportsShouldProcess=$True)]
param (
    [Parameter(Mandatory=$true)]
    [string]$DeployFile = "UFT_14_50_RnD_Deploy.xml",
    [Parameter(Mandatory=$true)]
    [string]$BUILD_NUMBER = "UFT_14_50_Setup_Last"   
)
$GlobalDict=@{}
$DeployXML = [xml] (Get-Content $DeployFile)
<#---------------------- Get Global Variables --------------------- #>
$GlobalPropXML = $DeployXML.SelectSingleNode("//GlobalProperties")
$GlobalPropertiesSTR = ""
$GlobalPropXML.ChildNodes | 
    ForEach-Object { 
        $GlobalDict.Set_Item($_.Name, $_.InnerText)
    } # $GlobalPropertiesSTR += $_.Name + "=" + $_.InnerText + "`n" }
    $GlobalDict.Set_Item("BUILD_NUMBER", $BUILD_NUMBER)
<# ---------------------------------------------------------------- #>



$DeployXML.SelectNodes("//hosts/host") | 
ForEach-Object { 
    $GlobalDictForItem = $GlobalDict.Clone()
    $HostName = ""
    $machineDomain = $GlobalDictForItem["CSADomain"]
    $_.ChildNodes | 
    ForEach-Object {
        if ($_.Name -eq "VM_NAME") { $HostName = $_.InnerText }
        if ($_.Name -eq "CSADomain") { $machineDomain = $_.InnerText }
        if ($_.Name -eq "USER_EMAIL") { 
            $GlobalDictForItem.Set_Item("NOTIFICATION_EMAIL", $GlobalDictForItem["NOTIFICATION_EMAIL"] + "," + $_.InnerText)
        } else {
            $GlobalDictForItem.Set_Item($_.Name, $_.InnerText)
        }
    }
    $PerHostSTR = ""
    $PerHostSTR += "VM_IP=" + (Test-Connection -ComputerName "${HostName}.${machineDomain}" -count 1).IPV4Address.IPAddressToString + "`n"
    $GlobalDictForItem.Set_Item("MAIL_SUBJECT", "UFT Deployment: ${HostName} $($GlobalDictForItem["BUILD_NUMBER"]) Deployment is")

    $GlobalDictForItem.GetEnumerator() | ForEach-Object {
        $PerHostSTR  += $_.Name + "=" + $_.Value + "`n"
    }

    $PerHostSTR | Out-File -FilePath "$HostName.txt" -Encoding "ASCII"
    Write-Output "$HostName.txt `n===============`n$PerHostSTR"
}

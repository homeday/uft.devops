
[CmdletBinding(SupportsShouldProcess=$True)]
param (
    [Parameter(Mandatory=$true)]
    [string]$DeployFile = "C:\configuation\DeploymentVMs.xml"
)
Set-ExecutionPolicy RemoteSigned

try {
    $DeployXML = [xml] (Get-Content $DeployFile)

    <#---------------------- Get Global Variables --------------------- #>
    $GlobalPropXML = $DeployXML.SelectSingleNode("//GlobalProperties")
    $GlobalPropertiesSTR = ""
    $GlobalPropXML.ChildNodes | foreach { $GlobalPropertiesSTR += $_.Name.ToUpper() + "=" + $_.InnerText + "`n" }
    <# ---------------------------------------------------------------- #>


    $DeployXML.SelectNodes("//hosts/host") | 
    foreach { 
        $PerHostSTR = ""
        $HostName = ""
        $PerHostSTR += $GlobalPropertiesSTR
        $_.ChildNodes | 
        foreach {
                    if ($_.Name -eq "VM_NAME") { $HostName = $_.InnerText }
                    $PerHostSTR += $_.Name.ToUpper() + "=" + $_.InnerText + "`n"
                 }
        #$PerHostSTR += "VM_IP=" + (Test-Connection -ComputerName $HostName -count 1).IPV4Address.IPAddressToString + "`n"
        $PerHostSTR | Out-File -FilePath "$HostName.txt" -Encoding "ASCII"
        Write-Output "$HostName.txt `n===============`n$PerHostSTR"
    }
    exit 0
}
catch [Exception]{
    exit 1
}



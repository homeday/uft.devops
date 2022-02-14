#Define CLI Params
param(
    [string]$hostname="",
    [string]$username="_ft_auto@swinfra.net",
    [string]$pass="W3lcome1"
)


($credential = New-Object System.Management.Automation.PSCredential($username, (ConvertTo-Securestring $pass -AsPlainText -Force)))

$iloop=0
$WinRmSvr = $null

do {

    if ($iloop -ne 0) {
        Start-Sleep 30
    }
    
    $WinRmSvr = Invoke-Command -Credential $credential  -ComputerName $hostname -ScriptBlock {Get-Service -Name winrm}
    Write-Host "[Info]: winrm service status: '$WinRmSvr'" -ForegroundColor Green -BackgroundColor Black
    Write-Host $WinRmSvr -ForegroundColor Green -BackgroundColor Black

    $iloop = $iloop + 1

} until (($null-ne $WinRmSvr -and $WinRmSvr[0].Status -eq "Running") -or $iloop -gt 5)

if ($null -eq $WinRmSvr) {
    throw("WinRm Services must be started!")
}

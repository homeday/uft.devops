using module '.\machinestate.psm1'
[CmdletBinding(SupportsShouldProcess=$True)]
param (
	[parameter(mandatory=$true)]
    [string]$apiurl
)

$ReleaseURI = "{0}/releases/?hasbuilds=true&isvalid=true" -f $apiurl
[MachineContext]::apiurl = $apiurl
try {
    $Releases = $null
    $Rsp = Invoke-WebRequest -Uri $ReleaseURI -Method Get
    Write-Host "Get all vaildate releases :" $Rsp.StatusCode -ForegroundColor Green -BackgroundColor Black
    if ( $Rsp.StatusCode -eq 200 -and $null -ne $Rsp.Content) {
        $Releases = $Rsp.Content | ConvertFrom-Json
    }
    if ($null -ne $Releases ) {
        $DeploymentsURI = "{0}/deployments/{1}" -f $apiurl, $_.name
        $Releases |  Foreach-Object {
            $Release = $_.name
            $DeploymentsURI = "{0}/deployments/{1}" -f $apiurl, $_.name
            try {
                $Rsp = Invoke-WebRequest -Uri $DeploymentsURI -Method Get
                Write-Host "Get all deployments for release" $Release ":" $Rsp.StatusCode -ForegroundColor Green -BackgroundColor Black
                $Deployments = $null
                if ( $Rsp.StatusCode -eq 200 -and $null -ne $Rsp.Content) {
                    $Deployments = $Rsp.Content | ConvertFrom-Json
                }
                if ($null -ne $Deployments ) {
                    $Deployments |  Foreach-Object {
                        Write-Host "Updating machine" $_.fullname "for release :" $Release -ForegroundColor Green -BackgroundColor Black
                        ([MachineContext]::new($_.name, $Release)).doAction()
                    }
                }
            }
            catch [Exception] {
                Write-Host $_.Exception -force -ForegroundColor Red -BackgroundColor Black | format-list 
            }



        }
        
    }
}
catch [Exception] {
    Write-Host $_.Exception -force -ForegroundColor Red -BackgroundColor Black | format-list 
    
}






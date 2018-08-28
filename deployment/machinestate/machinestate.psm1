

[Flags()] enum State
{
    invalid
    deploying
    success
    failure
    outofdate
    error
}


[Flags()] enum RegType
{
    REG_SZ
    REG_EXPAND_SZ
    REG_BINARY
    REG_DWORD
    REG_MULTI_SZ
}

# enum RegHives
# {
#     HKCR = 2147483648
#     HKCU = 2147483649
#     HKLM = 2147483650
#     HKU = 2147483651
#     HKCC = 2147483653
#     HKDD = 2147483654
# }





# 'http://www.xtremevbtalk.com/archive/index.php/t-280073.html
# 'https://www.darkoperator.com/blog/2013/1/31/introduction-to-wmi-basics-with-powershell-part-1-what-it-is.html
class MachineState
{
    MachineState(
       
    ) {
    }

    [void]Handle([MachineContext]$machineContext) {
        $type = $this.GetType()
        if ($this.GetType() -eq [MachineState])
        {
            throw("Class $type must be inherited")
        }
    }

    [Boolean]CheckMachine([string]$fullname) {
        $Connectable = $false

        For ($i=0; $i -le 5; $i++) {
            $Connectable = Test-Connection -Quiet -Count 1 -ComputerName $fullname
            if ($Connectable -eq $true)
            {
                break
            }
        }
        return $Connectable
    }

    [string]CheckInstallerState([MachineContext]$machineContext) {
        try {
            #Read installation time from register
            $HighDateTime = $machineContext.ReadRegistry([MachineContext]::RegHives["HKLM"],
                            "SOFTWARE\Wow6432Node\Mercury Interactive\QuickTest Professional\CurrentVersion\InstallTime", 
                            "HighDateTime", [RegType]::REG_DWORD)
            $LowDateTime = $machineContext.ReadRegistry([MachineContext]::RegHives["HKLM"],
                            "SOFTWARE\Wow6432Node\Mercury Interactive\QuickTest Professional\CurrentVersion\InstallTime", 
                            "LowDateTime", [RegType]::REG_DWORD)

            $InstallTime = [DateTime]::FromFileTime(([System.Int64]$HighDateTime -shl 32) -bxor $LowDateTime )
            $CurrentTime = $machineContext.GetLocalTime()
            $gapHours = ($CurrentTime - $InstallTime).TotalHours
            Write-Host "machine :" $machineContext.MachineInfo.fullname "delta time is" $gapHours "hours" -ForegroundColor Green -BackgroundColor Black   
            if ( $gapHours -lt 24.0 ) {
                return "success"
            }
            return "outofdate"
        } catch [Exception] {
            Write-Host $_.Exception -force -ForegroundColor Red -BackgroundColor Black | format-list 
            return "failure"
        }

    }

    [string]GetRdpusers([MachineContext]$machineContext) {
        return $machineContext.GetRdpusers()
    }

    [string]GetOSDescription([MachineContext]$machineContext) {
        return "{0} - {1}" -f $machineContext.GetOSName(), $machineContext.GetOSUICulture()
    }
}

class MachineContext {
    static $RegHives = @{"HKCR" = 2147483648; "HKCU" = 2147483649; "HKLM" = 2147483650; "HKU" = 2147483651;"HKCC" = 2147483653; "HKDD" = 2147483654}
    hidden [string]$MachineName
    hidden [string]$Release
    hidden [State]$State
    static [string] $apiurl = "http://localhost:8091/api"
    [PSCustomObject]$MachineInfo
    [System.Management.Automation.PSCredential]$Credential = $null
    [System.Management.ManagementClass]$StdRegProv = $null
    [System.Management.ManagementObject]$Win32OSMgm = $null
    
    MachineContext(
        [string]$name,
        [string]$Release
    ) {
        $this.MachineName = $name
        $this.Release = $Release
        $this.State = [State]::error 
    }

    [System.Management.Automation.PSCredential]GetCredential() {
        if ($null -eq $this.Credential) {
            $SecPwd = ConvertTo-Securestring $this.MachineInfo.Password -AsPlainText -Force
            $this.Credential = New-Object System.Management.Automation.PSCredential($this.MachineInfo.Username, $SecPwd)
            Write-Host "Set Credential :" $this.Credential.UserName"::"$this.Credential.Password -ForegroundColor Green -BackgroundColor Black
        }
        return $this.Credential
    }

    [System.Object]ReadRegistry(
        [uint32]$hDefKey,
        [string]$sSubKeyName,
        [string]$sValueName,
        [RegType]$regType
    ) {
        $Result = $null
        $TmpStdRegProv = $this.GetRegistryReader()
        switch ([RegType]$regType) 
        {
            REG_DWORD 
            { 
                $Result = $TmpStdRegProv.GetDwordValue($hDefKey, $sSubKeyName, $sValueName) 
                If($Result.ReturnValue -ne 0)
                {
                    throw("ReadRegistry error $($Result.ReturnValue)")   
                }
                $Result = $Result.uValue
            }
            Default {}
        }
        return $Result
    }


    [DateTime]GetLocalTime() {
        $win32LocalTime = Get-WmiObject -Class Win32_LocalTime -Namespace "root\cimv2" -ComputerName $this.MachineInfo.fullname -Credential $this.GetCredential()
        
        return Get-Date  	-Year $win32LocalTime.Year `
						-Month $win32LocalTime.Month `
						-Day $win32LocalTime.Day `
                        -Hour $win32LocalTime.Hour `
                        -Minute $win32LocalTime.Minute `
                        -Second $win32LocalTime.Second
    }


    [System.Management.ManagementClass]GetRegistryReader() {
        if ($null -eq $this.StdRegProv) {
            $this.StdRegProv = Get-WmiObject -List StdRegProv -Namespace "root\default" -ComputerName $this.MachineInfo.fullname -Credential $this.GetCredential()
        }
        return $this.StdRegProv
    }

    
    [System.Management.ManagementObject]GetWin32OSMgm() {
        if ($null -eq $this.Win32OSMgm) {
            $this.Win32OSMgm = Get-WmiObject -Class Win32_OperatingSystem -Namespace "root\cimv2" -ComputerName $this.MachineInfo.fullname -Credential $this.GetCredential()
        }
        return $this.Win32OSMgm
    }

    [string]GetRdpusers() {

        try {
            $RDPUsers = @()
            $Res = Invoke-Command -ComputerName $this.MachineInfo.fullname -Credential $this.GetCredential() -ScriptBlock {cmd /c qwinsta}
            $Res = $Res | Where-Object {
                $_ -like "*Active*" 
            }

            if ($null -eq $Res) {
                return ""
            }
            $ResAry = @()
            if ( $Res -is [System.Array]) {
                $ResAry = $Res
            } else {
                $ResAry += $Res
            }
            
            $ResAry | ForEach-Object {
                $Tmp = $_
                $RDPUsers += $($Tmp -split " " |  Where-Object {
                    $_ -ne ""
                })[1]
            }

            if ( 0 -eq $RDPUsers.Length) {
                return ""
            }
            return $RDPUsers -join "; "


            # $TmpCredential = $this.GetCredential()
            # $RDPUsers = @()
            # $regexa = '.+Domain="(.+)",Name="(.+)"$' 
            # $regexd = '.+LogonId="(\d+)"$' 
            # $Sessions = @(Get-WmiObject -Query "Select * from Win32_LogonSession Where LogonType = 10" -ComputerName $this.MachineInfo.fullname -Credential $TmpCredential)
            # $SessionIDs = @()
            # $Sessions | Foreach-Object { 
            #     $SessionIDs += $_.LogonId
            # }

            # if ($SessionIDs.Length -eq 0) {
            #     return ""
            # }
            # $LogonUsers = @(Get-WmiObject -Query "Select * from win32_loggedonuser" -ComputerName $this.MachineInfo.fullname -Credential $TmpCredential)

            # $LogonUsers = $LogonUsers | Where-Object -FilterScript { 
            #     $_.dependent -match $regexd > $nul 
            #     $SessionID = $matches[1] 
            #     return $($SessionIDs | Where-Object {$_ -eq $SessionID}) -gt 0
            # }

            # $LogonUsers | Foreach-Object {
            #     $_.Antecedent -match $regexa > $nul 
            #     $username = $matches[2] 
            #     $RDPUsers += $username 
                
            # }
            # return $RDPUsers -join "; "
        }
        catch [Exception] {
            return ""
        }

    }

    [string]GetOSName() {
        try {
            return $this.GetWin32OSMgm().Name.Split("|")[0]
        }
        catch [Exception] {
            Write-Host $_.Exception -force -ForegroundColor Red -BackgroundColor Black | format-list 
            return ""
        }
    }

    [string]GetOSUICulture() {
        try {
            $Res = Invoke-Command -ComputerName $this.MachineInfo.fullname -Credential $this.GetCredential() -ScriptBlock {powershell.exe "(Get-UICulture).ThreeLetterWindowsLanguageName"}
            return $Res
        }
        catch [Exception] {
            Write-Host $_.Exception -force -ForegroundColor Red -BackgroundColor Black | format-list 
            return ""
        }
    }


    #https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-itempropertyvalue?view=powershell-5.1
    [void]doAction() {
        $currState = $this.getState()
        if ([State]::error -eq $currState) {
            return
        }

        $StateHandler = $null

        switch ([State]$currState) {
            error {
                break
            }
            invalid {
                $StateHandler = [InvalidState]::GetInstance()
                break
            }
            success {
                $StateHandler = [SuccessState]::GetInstance()
                break
            }
            failure {
                $StateHandler = [FailureState]::GetInstance()
                break
            }
            outofdate {
                $StateHandler = [OutofDateState]::GetInstance()
                break
            }
        }

        if ( $null -ne $StateHandler) {
            $StateHandler.Handle($this)
        }
    }

    [State]getState() {
        try {
            $Uri = "{0}/deployments/{1}/?name={2}" -f [MachineContext]::apiurl, $this.Release, $this.MachineName
            $Rsp = Invoke-WebRequest -Uri $Uri -Method Get 
            Write-Host "Get state for machine :" $this.Release"::"$this.MachineName $Rsp.StatusCode -ForegroundColor Green -BackgroundColor Black
            if ( $Rsp.StatusCode -eq 200 -and $null -ne $Rsp.Content) {
                $this.MachineInfo = $Rsp.Content | ConvertFrom-Json
                if ($this.MachineInfo -is [System.Array]) {
                    if ($this.MachineInfo.Length -gt 0) {
                        $this.MachineInfo = $this.MachineInfo[0]
                    } else {
                        $this.MachineInfo = $null
                    }
                }
                $this.State = $this.machineInfo.state 
                Write-Host "The state is :" $this.State -ForegroundColor Green -BackgroundColor Black
            }
        }
        catch [Exception] {
            Write-Host $_.Exception -force -ForegroundColor Red -BackgroundColor Black | format-list 
            Write-Host "Get state for machine : " $this.Release "::" $this.MachineName " error" -ForegroundColor Red -BackgroundColor Black
        }

        return $this.State 

    }

    [State]setState([State]$state) {
        try {
            $this.MachineInfo.state = $state.ToString()
            $Uri = "{0}/deployments/{1}" -f [MachineContext]::apiurl, $this.Release
            $contentType = "application/json; charset=utf-8"  
            $json = $this.MachineInfo  | ConvertTo-Json
            $Rsp = Invoke-WebRequest -Uri $Uri -Method Put -Body $json -ContentType $contentType
            Write-Host "Put state" $state.ToString() "for machine :" $this.Release"::"$this.MachineName $Rsp.StatusCode -ForegroundColor Green -BackgroundColor Black
            $this.State = $this.machineInfo.state 
        }
        catch [Exception] {
            Write-Host $_.Exception -force -ForegroundColor Red -BackgroundColor Black | format-list 
            Write-Host "Get state for machine : " $this.Release "::" $this.MachineName " error" -ForegroundColor Red -BackgroundColor Black
        }

        return $this.State 
    }
}


class InvalidState : MachineState {
    
    InvalidState (
    ) : base(
    ) {

    }
    static [InvalidState] $instance
    static [InvalidState] GetInstance() {
        if ($null -eq [InvalidState]::instance) { 
            [InvalidState]::instance = [InvalidState]::new() 
        }
        return [InvalidState]::instance
    }

    [void]Handle([MachineContext]$machineContext) {
        # 1. Check whether it is connentable or not
        $connectable = ([MachineState]$this).CheckMachine($machineContext.MachineInfo.fullname)
        Write-Host $machineContext.MachineInfo.fullname $connectable -ForegroundColor Green -BackgroundColor Black
        if (-Not $connectable) {
            $machineContext.setState([State]::invalid)
            Write-Host "machine :" $machineContext.MachineInfo.fullname "still can't be connectable!" -ForegroundColor Green -BackgroundColor Black    
            return
        }

        # 2. System infomation generation
        $osDescription = ([MachineState]$this).GetOSDescription($machineContext)
        Write-Host $machineContext.MachineInfo.fullname $osDescription -ForegroundColor Green -BackgroundColor Black

        # 3. Get Rdp users
        $rdpUsers = ([MachineState]$this).GetRdpusers($machineContext)
        Write-Host $machineContext.MachineInfo.fullname $rdpUsers -ForegroundColor Green -BackgroundColor Black

        # 4. Check installer infomation
        $installerRes = ([MachineState]$this).CheckInstallerState($machineContext)
        Write-Host $machineContext.MachineInfo.fullname $installerRes -ForegroundColor Green -BackgroundColor Black

        # 5. Update all properties
        $machineContext.MachineInfo.os = $osDescription
        $machineContext.MachineInfo.rdpusers = $rdpUsers

        switch ($installerRes) {
            "failure" {
                $machineContext.setState([State]::failure)
                break
            }
            "success" {
                $machineContext.setState([State]::success)
                break
            }
            "outofdate" {
                $machineContext.setState([State]::outofdate)
                break
            }
            Default {}
        }
    }
}

class DeployingState : MachineState {
    
    DeployingState (
    ) : base(
    ) {
        Write-Host "DeployingState::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    static [DeployingState] $instance
    static [DeployingState] GetInstance() {
        if ($null -eq [DeployingState]::instance) { 
            [DeployingState]::instance = [DeployingState]::new() 
        }
        return [DeployingState]::instance
    }

    [void]Handle([MachineContext]$machineContext) {
        #for deploying state, nothing need to be handled
        Write-Host "machine :" $machineContext.MachineInfo.fullname "is being deployed!" -ForegroundColor Green -BackgroundColor Black  
        return
    }
}

class SuccessState : InvalidState {
    
    SuccessState (
    ) : base(
    ) {
        
    }
    static [SuccessState] $instance
    static [SuccessState] GetInstance() {
        if ($null -eq [SuccessState]::instance) { 
            [SuccessState]::instance = [SuccessState]::new() 
        }
        return [SuccessState]::instance
    }

 
    [void]Handle([MachineContext]$machineContext) {
        ([InvalidState]$this).Handle($machineContext)
    }
}

class FailureState : MachineState {
    
    FailureState (
    ) : base(
    ) {
        
    }
    static [FailureState] $instance
    static [FailureState] GetInstance() {
        if ($null -eq [FailureState]::instance) { 
            [FailureState]::instance = [FailureState]::new() 
        }
        return [FailureState]::instance
    }

    [void]Handle([MachineContext]$machineContext) {
        # 1. System infomation generation
        $osDescription = ([MachineState]$this).GetOSDescription($machineContext)
        Write-Host $machineContext.MachineInfo.fullname $osDescription -ForegroundColor Green -BackgroundColor Black

        # 2. Get Rdp users
        $rdpUsers = ([MachineState]$this).GetRdpusers($machineContext)
        Write-Host $machineContext.MachineInfo.fullname $rdpUsers -ForegroundColor Green -BackgroundColor Black
        
        # 3. Update all properties
        $machineContext.MachineInfo.os = $osDescription
        $machineContext.MachineInfo.rdpusers = $rdpUsers
        # 4. Check whether it is connentable or not
        $connectable = ([MachineState]$this).CheckMachine($machineContext.MachineInfo.fullname)
        Write-Host $machineContext.MachineInfo.fullname $connectable -ForegroundColor Green -BackgroundColor Black
        if (-Not $connectable) {
            $machineContext.setState([State]::invalid)
            Write-Host "machine :" $machineContext.MachineInfo.fullname "still can't be connectable!" -ForegroundColor Green -BackgroundColor Black    
            return
        }
        $machineContext.setState([State]::failure)
    }
}


class OutofDateState : MachineState {

    OutofDateState (
    ) : base(
    ) {
        Write-Host "OutofDateState::constructor" -ForegroundColor Green -BackgroundColor Black
    }
    static [OutofDateState] $instance
    static [OutofDateState] GetInstance() {
        if ($null -eq [OutofDateState]::instance) { 
            [OutofDateState]::instance = [OutofDateState]::new() 
        }
        return [OutofDateState]::instance
    }

    [void]Handle([MachineContext]$machineContext) {
        # 1. System infomation generation
        $osDescription = ([MachineState]$this).GetOSDescription($machineContext)
        Write-Host $machineContext.MachineInfo.fullname $osDescription -ForegroundColor Green -BackgroundColor Black
        # 2. Get Rdp users
        $rdpUsers = ([MachineState]$this).GetRdpusers($machineContext)
        Write-Host $machineContext.MachineInfo.fullname $rdpUsers -ForegroundColor Green -BackgroundColor Black

        # 3. Update all properties
        $machineContext.MachineInfo.os = $osDescription
        $machineContext.MachineInfo.rdpusers = $rdpUsers

        # 4. Check whether it is connentable or not
        $connectable = ([MachineState]$this).CheckMachine($machineContext.MachineInfo.fullname)
        Write-Host $machineContext.MachineInfo.fullname $connectable -ForegroundColor Green -BackgroundColor Black
        if (-Not $connectable) {
            $machineContext.setState([State]::invalid)
            Write-Host "machine :" $machineContext.MachineInfo.fullname "still can't be connectable!" -ForegroundColor Green -BackgroundColor Black    
            return
        }
        $machineContext.setState([State]::outofdate)
    }
}





#$env:APIServer="http://localhost:8091/api/deployments" #uft_14_50?name=myd-vm08474"

#$machineContext = [MachineContext]::new("myd-vm08159", "uft_14_50")
#$machineContext.doAction()
# $machineState = [MachineState]::new()
# $machineState.Handle($machineContext)


# Get-WmiObject -query "SELECT * FROM meta_class"

# $server="myd-vma00413.swinfra.net"
#  $HKCR = [uint32]"0x80000000"
#     $sSubKeyName = "AppID\{54C92AE1-77C3-11D1-9B6C-00A024BF0B6D}"
#     $sValueName = "RemoteServerName"
#     $wmi = [wmiclass]"\\$server\ROOT\DEFAULT:StdRegProv" 
#     $wmi.GetStringValue($HKCR, $sSubKeyName, $sValueName)
	
	
	
# Get-WmiObject -Class StdRegProv 	
	
# $SecPwd = ConvertTo-Securestring "W3lcome1" -AsPlainText -Force
# $Credential = New-Object System.Management.Automation.PSCredential("swinfra.net\_ft_auto", $SecPwd)
# $strComputer = "myd-vma00413.swinfra.net"

# $StdRegProv = Get-WmiObject -List StdRegProv -Namespace "root\default" -ComputerName $strComputer -Credential $Credential

# $StdRegProv = Get-WmiObject -Query "select * from win32_service where name='StdRegProv'" -Namespace "root\default:StdRegProv" -ComputerName $strComputer -Credential $CSACredential

#  Get-WmiObject -List -Namespace "root\default" -ComputerName $strComputer -Credential $CSACredential
 
#  Get-WmiObject -Class StdRegProv -Namespace "root\default" -ComputerName $strComputer -Credential $CSACredential
 
#  Get-WmiObject -Class Win32_PrivilegesStatus             
#  Get-WmiObject -Class Win32_LocalTime

#  ([WMICLASS]"\\$server\ROOT\CIMV2:Win32_Process") 
 
#   System.Management.ManagementScope 
#   $conopt = New-Object System.Management.ConnectionOptions  
#   $conopt.Password="W3lcome1"
#   $conopt.Username="swinfra.net\_ft_auto"
#   $conopt.SecurePassword=$SecPwd
# 	$scope = New-Object System.Management.ManagementScope             
# 	$scope.Path = "\\$server\root\cimv2"             
# 	$scope.Options = $conopt
	
# 	$scope.Connect()
	
# 	$path = New-Object System.Management.ManagementPath            
# $path.ClassName = "StdRegProv"              
            
# $proc = New-Object System.Management.ManagementClass($scope, $path, $null) 
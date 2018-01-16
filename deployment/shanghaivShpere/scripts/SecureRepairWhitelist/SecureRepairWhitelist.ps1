[CmdletBinding(SupportsShouldProcess=$True)]
param (
    [Parameter(Mandatory=$true)]
    [string]$Path = "productkey.xml"
)

$FORMAT_PROCESSING = "In {0}, {1} Processing Product {2} - GUID {3}"
$FORMAT_SECUREREPAIRWHITELIST_CHECK_4_EXISTENCE = "In {0}, Checking if {1} - {2} exists?"
$FORMAT_SECUREREPAIRWHITELIST_ADDING = "In {0}, Adding {1} - {2} "
$FORMAT_PRODUCT_GUID = "{0}"
 
# XML Configuraton file
#$Path = "productkey.xml"


 
# ***********************************************************************************************
# MS14-049: Description of the security update for Windows Installer Service: August 12, 2014
# https://support.microsoft.com/en-us/kb/2918614
# ***********************************************************************************************
$registryPathBase = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
$registryPathSecureRepairWhitelist = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer\SecureRepairWhitelist"
$SecureRepairPolicyName = "SecureRepairPolicy"
$SecureRepairPolicyValue = "2"
$registryValue = $SecureRepairPolicy

############################################################################
# Why Doesn't Write-Debug Work? (and what's it for, anyway?) by Don Jones
# http://windowsitpro.com/blog/why-doesnt-write-debug-work-and-whats-it-anyway
# $DebugPreference
# 	SilentContinue
#   Continue
############################################################################
#$DebugPreference = "Continue"

<#
	Tim Dunn
	What is my function-name
	http://blogs.msdn.com/b/timid/archive/2009/09/24/powershell-one-liner-what-s-the-function-name.aspx
	These days, I just use $MyInvocation.MyCommand.Name
#>
function Get-FunctionName 
{ 

	(Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name;
	
}

 
<# Test Registry Paths #>
<# candee #>
<# http://blogs.msdn.com/b/candede/archive/2010/01/13/test-registry-paths.aspx #>
function Test-PathReg
{
 
    <# 
		.Synopsis 
		 Validates the existence of a registry key 
		
		.Description 
		 This function searches for the registry value (Property attribute) 
		 under the given registry key (Path attribute) and returns $true if it exists 
		
		.Parameter 
		  Path Specifies the Registry path 
		
		.Parameter Property 
		  Specifies the name of the registry property that 
		  will be searched for under the given Registry path 
		
		.Example Test-PathReg 
					-Path HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters 
					-Property Hostname 
		
		.Link 
			http://blogs.msdn.com/candede 
		
		.Notes 
			Author: Can Dedeoglu 
	#>
 
    param
    (
        [Parameter(mandatory=$true,position=0)]
        [string]$Path
         
        ,
        [Parameter(mandatory=$true,position=1)]
        [string]$Property
         
    )
	
	[Boolean] $bFound = $false;
	[Boolean] $bUseOriginalCode = $false;
 

	############################################################
	# Slight changes made by dadeniji to check for null
	############################################################
	
	$objBase = (Get-ItemProperty -LiteralPath $Path).psbase.members | %{$_.name} 
	
	if ($objBase)
	{
	
		$compare = $objBase | compare $Property -IncludeEqual -ExcludeDifferent
	
		if ($compare)
		{

			if($compare.SideIndicator -like "==") 
			{
				
				$bFound = $true
				
			} #if($compare.SideIndicator -like "==") 		
			
		} #if ($compare)
		
	} #if ($objBase)
		
	
	return ($bFound)
	
         
} #Test-PathReg
 
 
function addRegistryBase
{
 
    <# 
		.Synopsis Add Registry Base 
	
		.Description This function adds the registry base 
		
		.Parameter productPath Specifies the registry path 
		
		.Example addRegistryBase $registryPath registryPath 
		
		.Notes Author: Daniel Adeniji 
	#>
     
    param
    (
        [Parameter(mandatory=$true,position=0)]
        [string]$registryPath
         
    )
	
	[String]$registryName = $SecureRepairPolicyName
	[String]$registryValue = $SecureRepairPolicyValue
	[Boolean]$bRegistryPathExist = $false
	[String]$functionName = Get-FunctionName
 
    # ***********************************************************************
    # If Registry path exists
    # HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer
	#  http://blogs.technet.com/b/heyscriptingguy/archive/2010/03/10/hey-scripting-guy-march-10-2010.aspx
    # ***********************************************************************   

    $info = "In {0}, checking registry path $registryPath" -f $functionName
     
    Write-Debug $info;

	$bRegistryPathExist = Test-Path -Path $registryPath
	
	if ($bRegistryPathExist -eq $false)
    {

		$info = "In {0}, adding registry path $registryPath" -f $functionName
		 
		Write-Debug $info;
	
        New-Item -Path $registryPath -Force | Out-Null
 
    }
 
    # set SecureRepairPolicy to 2
	$info = "In {0}, for registry path {1}, setting name {2} to {3}" `
				 -f $functionName, $registryPath, $registryName, $registryValue
	 
	Write-Output -InputObject $info;
	
    New-ItemProperty `
					-Path $registryPath `
					-Name  $registryName `
					-Value $registryValue `
					-PropertyType DWORD -Force | Out-Null
 
} #addRegistryBase
 
function addRegistryProductKeysBase
{
    <# 
	
		.Synopsis Validates the existence of a registry key 
		.Description This function adds the product key 
		.Parameter productPath Specifies the registry path 
		.Parameter productKey Specifies the Product Key 
		.Example addRegistryProductKeys $registryPath registryPath -$productKey productGUID 
		.Notes Author: Daniel Adeniji 
	#>
     
    param
    (

		[Parameter(mandatory=$true,position=0)]
        [string]$registryPath
         
    )   
     
    [Boolean] $itemExist = $false;
	[String]  $itemKey = "SecureRepairWhitelist";
	[String]  $itemValue = "";
	[String]  $functionName = "";
	
	$functionName = $MyInvocation.MyCommand.Name;
     
    # HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer
    if(!(Test-Path $registryPath))
    {
 
        New-Item -Path $registryPath -Force | Out-Null
 
    }

	$registryPathItem = $registryPath + "\" + $itemKey
	
	$FORMAT = "Checking Registry path {0}"
    $info = $FORMAT -f $registryPathItem;
     
    Write-Debug $info;
	
    # Does Registry Item exists
	$itemExist = Test-Path $registryPathItem

	
    # If Registry Item not found
    if ( $itemExist -eq $false) 
    {
                 
        # Add product key       
        #New-ItemProperty -Path $registryPath `
		$FORMAT = "addRegistryProductKeysBase::New-Item::Set Registry path {0} to {1}"
		$info = $FORMAT -f $registryPath, $itemKey;
		 
		Write-Debug $info;
		
		New-Item `
			-Path 	$registryPath `
			-Name   $itemKey `
				| Out-Null

     
    }
     
} #addRegistryProductKeysBase
   
function addRegistryProductKeyItems
{
    <# 
		.Synopsis Validates the existence of a registry key
		.Description This function adds the product key 
		.Parameter productPath Specifies the registry path 
		.Parameter productKey Specifies the Product Key 
		.Example addRegistryProductKeyItems $registryPath registryPath -$productKey productGUID 
		.Notes Author: Daniel Adeniji 
	#>
     
    param
    (
        [Parameter(mandatory=$true,position=0)]
        [string]$registryPath
         
        ,[Parameter(mandatory=$true,position=1)]
        [string]$productKey
         
    )   
     
    [Boolean] $itemExist = $false;
	[String]  $functionName = "";
	
	$functionName = $MyInvocation.MyCommand.Name;
	
    $info = $FORMAT_SECUREREPAIRWHITELIST_CHECK_4_EXISTENCE `
				-f $functionName, $registryPath, $productKey;
     
    Write-Debug $info;

	
    # Does Registry Item exists
    $itemExist = Test-PathReg $registryPath $productKey

	
    # If Registry Item not found
    if ( $itemExist -eq $false)
    {

		$info = $FORMAT_SECUREREPAIRWHITELIST_ADDING `
				-f $functionName, $registryPath, $productKey;
     
		Write-Output -InputObject $info;
	
        # Add product key       
        New-ItemProperty `
				-Path 	$registryPath `
				-Name   $productKey `
				| Out-Null
     
    }
     
} #addRegistryProductKeyItems
   
# load it into an XML object:
$xml = New-Object -TypeName XML
$xml.Load($Path)
# note: if your XML is malformed, you will get an exception here
# always make sure your node names do not contain spaces
 
$key = "//Product"
 
#Add Registry Base
addRegistryBase $registryPathBase
 
[int]    $id = 0;
[string] $ProductGUIDFormatted;
[String] $functionName = Get-FunctionName
	
#Add Registry Product Key
addRegistryProductKeysBase $registryPathBase;
	
foreach($item in (Select-XML -Xml $xml -XPath $key ))
{
 
    $id = $id + 1;
     
    $ProductName = $item.node.ProductName;
    $ProductGUID = $item.node.ProductGUID;
     
    $info = $FORMAT_PROCESSING `
				-f $functionName, $id, $ProductName, $ProductGUID;
     
    Write-Output -InputObject $info;
     
    $ProductGUIDFormatted = $FORMAT_PRODUCT_GUID -f $ProductGUID;
     
     
    #Add Registry Product Key
    addRegistryProductKeyItems `
			$registryPathSecureRepairWhitelist $ProductGUIDFormatted;
 
}
 
 
# SIG # Begin signature block
# MIID+QYJKoZIhvcNAQcCoIID6jCCA+YCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzoGD/gcjc6ob5fqCscIH4Q1G
# 4j+gggIWMIICEjCCAX+gAwIBAgIQJAtycD9ClYRI6q83MkEVNzAJBgUrDgMCHQUA
# MBkxFzAVBgNVBAMTDkRhbmllbCBBZGVuaWppMB4XDTE1MDkwNzE3MjQ1OFoXDTM5
# MTIzMTIzNTk1OVowGTEXMBUGA1UEAxMORGFuaWVsIEFkZW5pamkwgZ8wDQYJKoZI
# hvcNAQEBBQADgY0AMIGJAoGBAJ7YlGUNyZMAD1tRjKdzJ21IIVc/ywsI8YSpOVg8
# 9R8aV5BijWxWEctgzJEP3DNnoUnUvKfyMQxYZlH9C+pA5uoxEFOY1+D0PukhhFu3
# ETAciP4wfJG+WZF5LhaLUgNdB3SWgMMasq4yTE2enowtnAKOvJAVjr5kmXtBTMhP
# dBTnAgMBAAGjYzBhMBMGA1UdJQQMMAoGCCsGAQUFBwMDMEoGA1UdAQRDMEGAEHDA
# gvaJCpT+ubbXBoeFLyShGzAZMRcwFQYDVQQDEw5EYW5pZWwgQWRlbmlqaYIQJAty
# cD9ClYRI6q83MkEVNzAJBgUrDgMCHQUAA4GBAJqw+WwP75Fxusyc37vR8UZcDuQz
# QLLsZyHT3DX2sGfLTK6ZEGz58/kjJD0s5HuKmUbtmU1FTN6gIhSClJuXZtFOe3Fh
# RzAKQZURIYFDX9GnP/Hyz9NDX8bfnM+xeiC4fylf5QDCMSH2Ei8I4KWylBnk9s1H
# NiptUTEauzrm/1qJMYIBTTCCAUkCAQEwLTAZMRcwFQYDVQQDEw5EYW5pZWwgQWRl
# bmlqaQIQJAtycD9ClYRI6q83MkEVNzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIB
# DDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEE
# AYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUmLNvZWpLhArT
# IqaolBT77IwV/b4wDQYJKoZIhvcNAQEBBQAEgYBSowtB325cNc+o+FujRBzOe1d8
# 8wP69fcUPyXqHO6HR5QywckSv4C6ddnkca1wKrkHfLUDQPbjIFMmK9QTxoypvgMB
# a5ZWgG/ARShNh1kIxrkhvsyUTtEnIvua63Z3r+QFP3hradBe6Z7VxSySIki14vFb
# UBZqtS2QMYzavcqq/A==
# SIG # End signature block
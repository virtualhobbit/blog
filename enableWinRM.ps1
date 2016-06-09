# Author:	@virtualhobbit
# Website:	http://virtualhobbit.com
# Ref:		https://virtualhobbit.com/2016/06/08/wednesday-tidbit-using-powershell-to-create-group-policy-objects/

# Variables
$modName = "C:\GPWmiFilter.psm1"
$GPOname = "Enable WinRM on 2008 R2+ servers"
$defaultNC = ( [ADSI]"LDAP://RootDSE" ).defaultNamingContext.Value
$domainRoot = $defaultNC
$WMIFilterName = 'Windows 2008 R2 onwards'

Write-Host -ForegroundColor Magenta "Warning! Before starting, make sure you download the GPWmiFilter.psm1 from:"
write-host "`n"
Write-Host -ForegroundColor Green "     http://gallery.technet.microsoft.com/scriptcenter/Group-Policy-WMI-filter-38a188f3"
write-host "`n"
Write-Host -ForegroundColor Magenta "And store in the same folder as this script. Otherwise this script will not work."

# Get the RFC number, exit if process not followed
$rfc = Read-Host "Before we start, please enter the RFC number:"
if ($rfc -eq [string]::empty){
    Write-Host -ForegoundColor Red "Error: The RFC cannot be blank. Exiting"
	
	Exit
}

# Unblock module
Unblock-File $modName

# Import modules
Import-Module ActiveDirectory
Import-Module GroupPolicy
Import-Module $modName -Force
if(!(Get-Module "GPWmiFilter")){
	Write-Host -ForegoundColor Red "Error: The correct module is not loaded. Exiting"
	
	Exit
}

# Create GPO shell
$GPO = New-GPO -Name $GPOname

# Disable User Configuration
$GPO.GpoStatus = "UserSettingsDisabled"

# Set the RFC number as the description
$GPO.Description = "Created as part of RFC $rfc" 

# Create WMI Filter
$filter = New-GPWmiFilter -Name $WMIFilterName -Expression 'SELECT * FROM Win32_OperatingSystem WHERE Version LIKE "6.0%" OR Version LIKE "6.1%" OR Version LIKE "6.2%" OR Version LIKE "6.3%"' -Description 'Queries for Windows Server 2008 R2 onwards' -PassThru

# Add WMI Filter to GPO
$GPO.WmiFilter = $filter

# Enable WinRM
$winrmkey = 'HKLM\Software\Policies\Microsoft\Windows\WinRM\Service'
$params = @{
    Key = $winrmkey;
    ValueName = 'AllowAutoConfig';
    Value = 1;
    Type = 'Dword';
}
$GPO | Set-GPRegistryValue @params

# Link GPO to domain root
New-GPLink -Name $GPOname -Target $domainRoot | Out-Null
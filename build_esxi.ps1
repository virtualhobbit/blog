# Variables

$esxi1 = "192.168.146.201"
$esxi2 = "192.168.146.202"
$username = "root"
$password = "password"
$rootPW = "VMware1!"
$ntpIP = "192.168.146.204"
$dnsIP = "192.168.146.204"
$domainname = "lab.mdb-lab.com"
$syslog = "udp://192.168.146.205:514"

ForEach ($esxi in $esxi1,$esxi2){

# Connect to the ESXi host
Connect-VIServer -Server $esxi -username $username -password $password

# Set NTP server
Add-VmHostNtpServer -NtpServer "$ntpIP"

# Set DNS server
Get-VMHostNetwork | Set-VMHostNetwork -DnsAddress $dnsIP

# Set DNS domain name
Get-VMHostNetwork | Set-VMHostNetwork -DomainName $domainname -SearchDomain $domainname -HostName $esxi

# Set the syslog server
Set-VMHostSysLogServer -SysLogServer $syslog

# Open firewall port for syslog
Get-VMHostFirewallException -Name syslog | Set-VMHostFirewallException -Enabled:$true

# Enable SSH
Get-VMHost | Foreach {Start-VMHostService -HostService ($_ | Get-VMHostService | Where { $_.Key -eq "TSM-SSH"} ) }

# Suppress shell warning
Get-VMHost | Get-AdvancedSetting -Name 'UserVars.SuppressShellWarning' | Set-AdvancedSetting -Value "1" -Confirm:$false

# Add iSCSI software adapter
Get-VMHostStorage -VMHost $esxi | Set-VMHostStorage -SoftwareIScsiEnabled $True

# Set power management policy to High Performance
$view = (Get-VMHost $esxi | Get-View)
(Get-View $view.ConfigManager.PowerSystem).ConfigurePowerPolicy(1)

# Reset root password
Set-VMHostAccount -UserAccount root -password $rootPW

Disconnect-VIServer -Server $esxi -confirm:$false
}
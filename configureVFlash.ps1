# Variables

$vc = "vc2.uk.mdb-lab.com"
$cred = Get-Credential
$cluster = "London Cluster"

# Connect to vCenter
Connect-VIServer -Server $vc -Credential $cred

Import-Module VMware.VimAutomation.Extensions

$myCluster = Get-Cluster $cluster
ForEach ($esxi in ($myCluster | Get-VMHost)) {
 
# Get current vFRC configuration   
Write-Host "Getting current vFRC configuration for" $esxi -foregroundcolor "magenta"  
$vFlashConfig = Get-VMHostVFlashConfiguration -VMHost $esxi

# Get SSD details
Write-Host "Getting" $esxi "host SSDs to be used by vFRC" -foregroundcolor "magenta"  
$vFlashDisk = (Get-ScsiLun -VMHost $esxi -CanonicalName mpx.vmhba1:C0:T1:L0 | Get-VMHostDisk)

# Enable vFRC on selected host   
Write-Host "Setting vFRC configuration for" $esxi -foregroundcolor "magenta"
Set-VMHostVFlashConfiguration -VFlashConfiguration $vFlashConfig -AddDevice $vFlashDisk

# Set vFRC host swap cache
Write-Host "Setting vFRC host swap cache for" $esxi -foregroundcolor "magenta"
Set-VMHostVFlashConfiguration -VFlashConfiguration $vFlashConfig -SwapCacheReservationGB 150

}
 
# Disconnect from vCenter
Disconnect-VIServer $vc -confirm:$false
# Variables
$vc = "vc2.uk.mdb-lab.com"
$credential = Get-Credential
$psp = "RoundRobin"

# Connect to the vCenter
Connect-VIServer $vc -Credential $credential

# Define the cluster
$cluster = "London_Lab"

# Retrieve disks and their associated PSP
Get-Cluster $cluster | Get-VMHost | Get-ScsiLun -LunType "disk" | where {$_.MultipathPolicy -ne $psp} | Format-Table CanonicalName,CapacityGB,Multipathpolicy -AutoSize

# Set the PSP to Round Robin
Get-Cluster $cluster | Get-VMHost | Get-ScsiLun -LunType "disk" | where {$_.MultipathPolicy -ne $psp} | Set-ScsiLun -MultipathPolicy $psp

# Disconnect from the vCenter
Disconnect-VIServer $vc
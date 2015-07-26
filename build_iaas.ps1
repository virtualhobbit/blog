# Variables

$vc = "vcsa.lab.mdb-lab.com"
$credential = Get-Credential
$cluster = "London_Lab"
$vmName = "iaas.lab.mdb-lab.com"
$numCPU = "2"
$numMem = "4096"
$numDisk = "51200"
$ds = "iSCSI"
$vmdkFormat = "Thick"
$net = "London Management VMs"
$guestOS = "windows8Server64Guest"
$ver = "v10"
$iso = "en_windows_server_2012_r2_with_update_x64_dvd_4065220.iso"
$cdpath = "[$ds] $iso"

Connect-VIServer $vc -credential $credential

$myCluster = Get-Cluster -Name $cluster

#Create VM
New-VM -name $vmName -ResourcePool $myCluster -numcpu $numCPU -memoryMB $numMem -DiskMB $numDisk -datastore $ds -DiskStorageFormat $vmdkFormat -Network $net -guestID $guestOS -cd -Version $ver

# Set network adapter to VMXNET3
Get-NetworkAdapter -VM $vmName | Set-NetworkAdapter -Type vmxnet3 -Confirm:$false

# Add CD drive with ISO
Get-CDDrive -VM $vmName | Set-CDDrive -IsoPath $cdpath -StartConnected $true -Confirm:$false

Disconnect-VIServer $vc -confirm:$false
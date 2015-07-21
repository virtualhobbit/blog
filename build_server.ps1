# Variables

$esxi1 = "192.168.146.201"
$username = "root"
$password = "VMware1!"
$vmName = "dc-lon.lab.mdb-lab.com"
$numCPU = "1"
$numMem = "2048"
$numDisk = "16384"
$ds = "TEMP-datastore"
$net = "VM Network"
$guestOS = "windows8Server64Guest"
$ver = "v10"
$iso = "en_windows_server_2012_r2_with_update_x64_dvd_4065220.iso"
$cdpath = "[$ds] $iso"

Connect-VIServer $esxi1 -username $username -password $password

#Create VM
New-VM -name $vmName -VMhost $esxi -numcpu $numCPU -memoryMB $numMem -DiskMB $numDisk -datastore $ds -Network $net -guestID $guestOS -cd -Version $ver

# Set network adapter to VMXNET3
Get-NetworkAdapter -VM $vmName | Set-NetworkAdapter -Type vmxnet3 -Confirm:$false

# Add CD drive with ISO
Get-CDDrive -VM $vmName | Set-CDDrive -IsoPath $cdpath -StartConnected $true -Confirm:$false

Disconnect-VIServer $esxi1 -confirm:$false
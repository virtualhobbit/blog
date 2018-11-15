# Author:	@virtualhobbit
# Website:	http://virtualhobbit.com
# Ref:		Building an advanced lab using VMware vRealize Automation – Part 8: Deploy and configure the vRA Appliance

# Variables

$vc = "vcsa.lab.mdb-lab.com"
$credential = Get-Credential
$esxi = "esxi1.lab.mdb-lab.com"
$vss = "vSwitch0"
$pg = "Temp for vApp deployment"
$ova = "C:\VMware-vCAC-Appliance-6.2.2.0-2754336_OVF10.ova"
$vmdkFormat = "Thick"
$dvPG = "London Management VMs"
$name = "vra.lab.mdb-lab.com"

# ------------------------------------ Do not modify below this line ------------------------------------

# Connect to vCenter
Connect-VIServer -Server $vc -Credential $credential

# Set variables
$cluster = Get-Cluster -Name "London_Lab"
$ds = Get-DatastoreCluster -Name "iSCSI"

# Create vSwitch for the vApp deployment
New-VirtualSwitch -VMHost $esxi -Name $vss
New-VirtualPortGroup -VirtualSwitch $vss -Name $pg

# Deploy the OVA
$vApp = Import-VApp -Source $ova -Location $cluster -VMHost $esxi -Datastore $ds -DiskStorageFormat $vmdkFormat -Confirm:$false

# Change appliance port group
Get-VM $vApp | Get-NetworkAdapter | where { $_.NetworkName -eq $pg } | Set-NetworkAdapter -PortGroup $dvPG -Confirm:$false

# Remove temporary vSwitch and port group
$vswitch = Get-VirtualSwitch -VMHost $esxi -Name $vss
Remove-VirtualSwitch -VirtualSwitch $vswitch -Confirm:$false

# Rename appliance
Get-VM $vApp | Set-VM -Name $name -Confirm:$false

# Disconnect from the vCenter
Disconnect-VIServer $vc -Confirm:$false
# Author:	@virtualhobbit
# Website:	http://virtualhobbit.com
# Ref:		http://virtualhobbit.com/2015/07/17/building-an-advanced-lab-using-vmware-vrealize-automation-part-6-deploy-and-configure-the-vcenter-server-appliance

# Variables

$vc = "vcsa.lab.mdb-lab.com"
$credential = Get-Credential
$vcsaRootPW = "VMware1!"
$admins = "MDB-LAB\VMware Administrators"
$datacenter = "London"
$cluster = "London_Lab"
$vcLicenseKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
$esxiLicenseKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
$esxi_array = @("esxi1.lab.mdb-lab.com", "esxi2.lab.mdb-lab.com")
$username = "root"
$rootPW = "VMware1!"
$dvSwitch = "vDS"
$uplinkPorts = "8"
$vdsVersion = "5.5.0"
$pg_array = @("Management","vMotion","FT","iSCSI_1","iSCSI_2","NFS","London Management VMs")
$vmknic_array = @("Management","vMotion","FT","London Management VMs")
$vmknicPortsList = 1..2 | ForEach {"dvUplink$_"}
$vmknicPortsUnused = 3..8 | ForEach {"dvUplink$_"}
$iscsi1 = "iSCSI_1"
$iscsi1PortsList = "dvUplink3"
$iscsi1PortsUnused = 1..2 + 4..8 | ForEach {"dvUplink$_"}
$iscsi2 = "iSCSI_2"
$iscsi2PortsList = "dvUplink4"
$iscsi2PortsUnused = 1..3 + 5..8 | ForEach {"dvUplink$_"}
$nfs = "NFS"
$nfs_uplink = "dvUplink5"
$nfsPortsUnused = 1..4 + 6..8 | ForEach {"dvUplink$_"}
$managementPG = "Management"
$esxi1 = "esxi1.lab.mdb-lab.com"
$dc = "dc-lon.lab.mdb-lab.com"
$vms_array = @($dc, $vc)
$vss = "vSwitch0"
$vmPG = "VM Network"
$dvVmPG = "London Management VMs"
$vMotion = "vMotion"
$sm = "255.255.255.240"
$ft = "FT"
$iscsi1IP = "192.168.86.6"
$iscsi2IP = "192.168.87.6"
$dsCluster = "iSCSI"
$dsCluster_array = @("iSCSI_LUN1","iSCSI_LUN2")
$tempDS = "TEMP-datastore"
$nfsPath = "/NFS"
$nas = "192.168.88.6"
$heartbeatDS_array = @("iSCSI_LUN1","NFS")
$isolationAddress = "192.168.146.203"
$dc = "dc-lon.lab.mdb-lab.com"

# ------------------------------------ Do not modify below this line ------------------------------------

# Connect to vCenter
Connect-VIServer -Server $vc -Credential $credential

# Set the vCSA root account password
# Set-VMHostAccount -UserAccount root -password $vcsaRootPW

# Grant admins in the production domain the Admin role on vCenter
New-VIPermission -Role Admin -Principal $admins -Entity Datacenters

# Create a new datacenter
$location = Get-Folder -NoRecursion
New-Datacenter -Location $location -Name $datacenter

# Create a new cluster
New-Cluster -Location $datacenter -Name $cluster -DRSEnabled -DRSMode FullyAutomated -HAEnabled

# Configure licensing for vCenter
$si = Get-View ServiceInstance
$LicManRef=$si.Content.LicenseManager
$LicManView=Get-View $LicManRef
$license = New-Object VMware.Vim.LicenseManagerLicenseInfo
$license.LicenseKey = $vcLicenseKey
$LicManView.AddLicense($license.LicenseKey,$null)
$vcLicName = "vCenter Server 5 Standard"
$servInst = Get-View ServiceInstance
$licMgr = Get-View $servInst.Content.licenseManager
$licAssignMgr = Get-View $licMgr.licenseAssignmentManager
$vcUuid = $servInst.Content.About.InstanceUuid
$vcDisplayName = $servInst.Content.About.Name
$vcLicKey = ($licMgr.Licenses | where {$_.Name -eq $vcLicName}).LicenseKey
$licInfo = $licAssignMgr.UpdateAssignedLicense($vcUuid, $vcLicKey,$vcDisplayName)

# Configure licensing for ESXi hosts
$licenseDataManager = Get-LicenseDataManager
$hostContainer = Get-Datacenter -Name $datacenter
$licenseData = New-Object VMware.VimAutomation.License.Types.LicenseData
$licenseKeyEntry = New-Object Vmware.VimAutomation.License.Types.LicenseKeyEntry
$licenseKeyEntry.TypeId = "vmware-vsphere"
$licenseKeyEntry.LicenseKey = $esxiLicenseKey
$licenseData.LicenseKeys += $licenseKeyEntry
$licenseDataManager.UpdateAssociatedLicenseData($hostContainer.Uid, $licenseData)
$licenseDataManager.QueryAssociatedLicenseData($hostContainer.Uid)

# Add hosts to cluster
ForEach ($esxi in $esxi_array){

Add-VMHost $esxi -location $cluster -user $username -password $rootPW -force:$true

}

# Create a new distributed virtual switch
New-VDSwitch -Name $dvSwitch -Location $datacenter -NumUplinkPorts $uplinkPorts -Version $vdsVersion

# Create vDS portgroups
ForEach ($pg in $pg_array){

New-VDPortgroup -Name $pg -Vds $dvSwitch

}

# Set teaming policy for Management, vMotion and FT
ForEach ($pg in $vmknic_array){

Get-VDSwitch $dvSwitch | Get-VDPortgroup $pg | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort $vmknicPortsList -UnusedUplinkPort $vmknicPortsUnused

}

# Set teaming policy for iSCSI_1
ForEach ($pg in $iscsi1){

Get-VDSwitch $dvSwitch | Get-VDPortgroup $pg | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort $iscsi1PortsList -UnusedUplinkPort $iscsi1PortsUnused

}

# Set teaming policy for iSCSI_2
ForEach ($pg in $iscsi2){

Get-VDSwitch $dvSwitch | Get-VDPortgroup $pg | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort $iscsi2PortsList -UnusedUplinkPort $iscsi2PortsUnused

}

# Set teaming policy for NFS
Get-VDSwitch $dvSwitch | Get-VDPortgroup $nfs | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort $nfs_uplink -UnusedUplinkPort $nfsPortsUnused

# Add hosts to vDS
ForEach ($VMHost in $esxi_array){

Get-VDSwitch -Name $dvSwitch | Add-VDSwitchVMHost -VMHost $VMHost

}

# Migrate vmnic1 to vDS
ForEach ($VMHost in $esxi_array){

$vmnic1 = Get-VMHostNetworkAdapter -VMHost $VMHost -Name "vmnic1"

Get-VDSwitch -Name $dvSwitch | Add-VDSwitchPhysicalNetworkAdapter $vmnic1 -Confirm:$false

}

# Migrate Management portgroups to vDS
$dvManagementPG = Get-VDPortGroup -Name $managementPG -VDSwitch $dvSwitch
ForEach ($VMHost in $esxi_array){

$vmk = Get-VMHostNetworkAdapter -VMHost $VMHost -Name vmk0

Set-VMhostNetworkAdapter -PortGroup $dvManagementPG -VirtualNic $vmk -Confirm:$false

}

# Migrate VMs to vDS
$vmsPortGroup = Get-VMHost $esxi1 | Get-VirtualSwitch -Name $vss | Get-VirtualPortGroup -Name $vmPG
ForEach ($vm in $vms_array) {

Get-VM -RelatedObject $vmsPortGroup  | Get-NetworkAdapter | where { $_.NetworkName -eq $vmsPortGroup.Name } | Set-NetworkAdapter -PortGroup $dvVmPG -Confirm:$false

}

# Remove old portgroups
ForEach ($VMHost in $esxi_array){

$vswitch = Get-VirtualSwitch -VMHost $VMHost -Name vSwitch0

$oldvmPG = Get-VirtualPortGroup -Name $vmPG -VirtualSwitch $vswitch

$oldmanagementPG = Get-VirtualPortGroup -Name "Management Network" -VirtualSwitch $vswitch
	
	ForEach ($pg in $oldvmPG,$oldmanagementPG){

		Remove-VirtualPortGroup -VirtualPortGroup $PG -Confirm:$false
	}

}

# Remove old vSwitch
ForEach ($VMHost in $esxi_array){

$vswitch = Get-VirtualSwitch -VMHost $VMHost -Name vSwitch0

Remove-VirtualSwitch -VirtualSwitch $vswitch -Confirm:$false

}

# Migrate vmnic0 to vDS
ForEach ($VMHost in $esxi_array){

$vmnic0 = Get-VMHostNetworkAdapter -VMHost $VMHost -Name "vmnic0"

Get-VDSwitch -Name $dvSwitch | Add-VDSwitchPhysicalNetworkAdapter $vmnic0 -Confirm:$false

}

# Migrate remaining vmnics to vDS
ForEach ($VMHost in $esxi_array){

$vmnics = 2..7 | ForEach {Get-VMHostNetworkAdapter -VMHost $VMHost -Name "vmnic$_"}

Get-VDSwitch -Name $dvSwitch | Add-VDSwitchPhysicalNetworkAdapter $vmnics -Confirm:$false

}

# Create vMotion on all hosts
$i = 0
ForEach ($VMHost in $esxi_array){

$i=$i+1

New-VMHostNetworkAdapter -VMHost $VMHost -PortGroup $vMotion -VirtualSwitch $dvSwitch -IP 192.168.84.$i -SubnetMask $sm -vMotionEnabled:$true -Confirm:$false

}


# Create Fault Tolerance on all hosts
$i = 0
ForEach ($VMHost in $esxi_array){

$i=$i+1

New-VMHostNetworkAdapter -VMHost $VMHost -PortGroup $ft -VirtualSwitch $dvSwitch -IP 192.168.85.$i -SubnetMask $sm -FaultToleranceLoggingEnabled:$true -Confirm:$false

}

# Configure iSCSI_1 on all hosts
$i = 0
ForEach ($VMHost in $esxi_array){

$i=$i+1

New-VMHostNetworkAdapter -VMHost $VMHost -PortGroup $iscsi1 -VirtualSwitch $dvSwitch -IP 192.168.86.$i -SubnetMask $sm -Confirm:$false

}

# Configure iSCSI_2 on all hosts
$i = 0
ForEach ($VMHost in $esxi_array){

$i=$i+1

New-VMHostNetworkAdapter -VMHost $VMHost -PortGroup $iscsi2 -VirtualSwitch $dvSwitch -IP 192.168.87.$i -SubnetMask $sm -Confirm:$false

}

# Configure NFS on all hosts
$i = 0
ForEach ($VMHost in $esxi_array){

$i=$i+1

New-VMHostNetworkAdapter -VMHost $VMHost -PortGroup $nfs -VirtualSwitch $dvSwitch -IP 192.168.88.$i -SubnetMask $sm -Confirm:$false

}

# Add iSCSI targets and set bindings
ForEach ($VMHost in $esxi_array){

$hba = Get-VMHost $VMHost | Get-VMHostHba -Type iScsi | Where {$_.Model -eq "iSCSI Software Adapter"}

# Add targets
New-IScsiHbaTarget -IScsiHba $hba -Address $iscsi1IP,$iscsi2IP

# Set up PowerCLI for esxcli commands
$esxcli = Get-EsxCli -VMHost $VMHost

# Set binding
3..4 | ForEach {$esxcli.iscsi.networkportal.add($hba, $true,"vmk$_")}

}

# Create iSCSI datastores
ForEach ($VMHost in $esxi_array){

$i = 0

Get-VMHostStorage $VMHost -RescanAllHba -Rescanvmfs

$datastores = Get-Datastore -VMHost $VMHost

if (-Not ($datastores -like "iSCSI*")){

	ForEach ($lun in $luns){

		$i=$i+1

		$luns = Get-VMHost $VMHost | Get-ScsiLun | Where { $_.Vendor -eq "MSFT"}
	
		New-Datastore -VMHost $VMHost -Name iSCSI_LUN$i –Path $lun.CanonicalName -Vmfs -Confirm:$false
	
		}
	}
}

# Create a new datastore cluster
New-DatastoreCluster -location $datacenter -Name $dsCluster -Confirm:$false

# Add the iSCSI datastores to it
Get-Datastore $dsCluster_array | Move-Datastore -Destination $dsCluster

# Configure the datastore cluster
Set-DatastoreCluster -DatastoreCluster $dsCluster -SdrsAutomationLevel FullyAutomated -Confirm:$false

# Storage vMotion existing VMs to datastore cluster
ForEach ($vm in $vms_array) {

Move-VM $vm -Datastore $dsCluster -DiskStorageFormat EagerZeroedThick -Confirm:$false

}

# Remove temp datastore
Remove-Datastore -Datastore $tempDS -VMHost $esxi1 -Confirm:$false

# Add NFS datastore
ForEach ($VMHost in $esxi_array){

New-Datastore -Nfs -VMHost $VMHost -Name $nfs -Path $nfsPath -NfsHost $nas

}

# Configure datastore heartbeating on HA cluster
$haCluster = Get-Cluster -Name $cluster
$dsMoRef = Get-Datastore -Name $heartbeatDS_array | %{$_.ExtensionData.MoRef}
$spec = New-Object VMware.Vim.ClusterConfigSpec
$spec.dasConfig = New-Object VMware.Vim.ClusterDasConfigInfo
$spec.dasConfig.hBDatastoreCandidatePolicy = "userSelectedDs"
$spec.dasConfig.heartbeatDatastore = $dsMoRef
$haCluster.ExtensionData.ReconfigureCluster($spec,$true)

# As our firewall ignores ICMP, we need to set the isolation address
New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.isolationaddress1' -Value $isolationAddress -Confirm:$false

# Disable default isolation address
New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.usedefaultisolationaddress' -Value:$false -Confirm:$false

# Enable FT on dc-lon.lab.mdb-lab.com
Get-VM $dc | Get-View | ForEach {

$_.CreateSecondaryVM_Task($Null)

}

Disconnect-VIServer $vc -confirm:$false
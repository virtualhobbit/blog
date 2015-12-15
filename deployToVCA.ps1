# Author:	@virtualhobbit
# Website:	http://virtualhobbit.com
# Ref:		http://virtualhobbit.com/2015/12/15/using-vcloud-air-to-stand-up-a-chef-compliance-proof-of-concept

# Variables

$credential = Get-Credential
$region = "de-ge" 
$regionstar = $region + "*"
$ovf = "C:\win2012r2.ovf"
$ovfName = "Windows Server 2012 R2"
$myOrgVdc = "virtualhobbitDC"
$myCatalog = "default-catalog"
$vApp = "chef-poc"
$myOrgNetwork = "default-routed-network"
$myTemplate = "CentOS64-64BIT"
$boxes = @("chef-compliance","chef-test")

# Connect to vCloud Air
Connect-PIServer -vCA -credential $credential -WarningAction 0 -ErrorAction 0

# Connect to compute instance
Get-PIComputeInstance -Region $regionstar | Connect-PIComputeInstance -WarningAction 0 -ErrorAction 0

# Import the Windows Server 2012 R2 OVF
Import-CIVAppTemplate -SourcePath $ovf -Name $ovfName -OrgVdc $myOrgVdc -Catalog $myCatalog

# Create the vApp
$NewvApp = New-CIVApp -Name $vApp -OrgvDC $myOrgVdc 

# Assign the network to the vApp
$myOrgNetworkConsistent = Get-OrgNetwork -Id (Search-Cloud -QueryType OrgVdcNetwork -Filter "VdcName==$myOrgVdc;Name==$myOrgNetwork").Id
$NewVAppNetwork = New-CIVAppNetwork -VApp $vApp -Direct -ParentOrgNetwork $myOrgNetworkConsistent

# Create CentOS virtual machines
ForEach ($Name in $boxes){	
	New-CIVM -Name $name -vApp $vApp -VMTemplate $myTemplate -Confirm:$false
}	

# Configure the IP pool
ForEach ($Name in $boxes){	
	Get-CIVM | Get-CINetworkAdapter | Set-CINetworkAdapter -IPAddressAllocationMode Pool -VAppNetwork $NewVAppNetwork -Connected:$true  
}

# Start the VMs
Start-CIVApp -VApp $NewvApp

# List all VMs
Get-CIVM | Format-Table 

# Disconnect from vCloud Air
Disconnect-PIServer -Confirm:$false
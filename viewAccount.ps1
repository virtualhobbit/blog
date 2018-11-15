# Variables

$credential = Get-Credential
$role = "VMware View"
$viewAccount = "NL\sa_view"

# Enter the vCenter name
$vc = Read-Host "Enter the vCenter Server name"

# Connect to vCenter
Connect-VIServer -Server $vc -Credential $credential

# Define privilege
$priv = Get-VIPrivilege -ID Folder.Create,Folder.Delete,VirtualMachine.Config.AddRemoveDevice,VirtualMachine.Config.AdvancedConfig,VirtualMachine.Config.EditDevice,VirtualMachine.Interact.PowerOff,VirtualMachine.Interact.PowerOn,VirtualMachine.Interact.Reset,VirtualMachine.Interact.Suspend,VirtualMachine.Inventory.Create,VirtualMachine.Inventory.Delete,VirtualMachine.Provisioning.Customize,VirtualMachine.Provisioning.DeployTemplate,VirtualMachine.Provisioning.ReadCustSpecs,Resource.AssignVMToPool,Global.VCServer

# Create role
New-VIRole -Name $role -Privilege $priv

# Define the root folder
$rootFolder = Get-Folder -NoRecursion

# Assign permission to domain account
$myPermission = New-VIPermission -Entity $rootFolder -Principal $viewAccount -Role $role -Propagate:$true

# Disconnect from vCenter
Disconnect-VIServer $vc -Confirm:$false
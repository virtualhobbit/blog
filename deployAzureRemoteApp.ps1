# Author:	@virtualhobbit
# Website:	http://virtualhobbit.com
# Ref:		http://virtualhobbit.com/2015/12/05/publishing-remoteapps-on-microsoft-azure

# Variables

$userName = "virtualhobbit.com@virtialhobbit.onmicrosoft.com"
$securePassword = ConvertTo-SecureString -String "NotMyRealPassword" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)
$tenant = "4be75c35-xxxx-4ef6-984e-9043c7a12467"
$collection = "myApps"
$img = "Office 365 ProPlus (Subscription required)"
$plan = "Basic"
$location = "North Europe"
$description = "Office 365 Collection."
$users = "C:\users.csv"

# Connect to Azure
Add-AzureAccount -Credential $credential -Tenant $tenant

# Create the collection
$result = New-AzureRemoteAppCollection -Collectionname $collection -ImageName $img -Plan $plan -Location $location -Description $description

# Check the provisioning progress
$tmp = Get-AzureRemoteAppOperationResult –TrackingId $result.TrackingID
while ($tmp.Status -ne "Success"){
	Start-Sleep -seconds 5
}

# Import the list of users
Import-Csv $users | ForEach {

	# Entitle the users
	Add-AzureRemoteAppUser -CollectionName $collection -Type microsoftAccount -UserUpn $_.user
	
}

# Publish Viso and Project
Publish-AzureRemoteAppProgram -CollectionName $collection -FileVirtualPath "%SYSTEMDRIVE%\Program Files\Microsoft Office 15\root\office15\VISIO.EXE" -DisplayName "Visio 2013"
Publish-AzureRemoteAppProgram -CollectionName $collection -FileVirtualPath "%SYSTEMDRIVE%\Program Files\Microsoft Office 15\root\office15\WINPROJ.EXE" -DisplayName "Project 2013"
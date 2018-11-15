# Author:	@virtualhobbit
# Website:	http://virtualhobbit.com
# Ref:		http://virtualhobbit.com/2015/11/25/wednesday-tidbit-who-turned-off-admission-control

# Variables

$credential = Get-Credential
$vc = "vc2.uk.mdb-lab.com"
$date = Get-Date
$goBackInMonths = 6

# Connect to vCenter
Connect-VIServer -Server $vc -Credential $credential

# Define the cluster
$cluster = "London_Cluster"

# Retrieve events
Get-VIEvent -Entity $cluster -Start ($date).AddMonths(-$goBackInMonths) | Where { $_.Gettype().Name -eq "DasAdmissionControlDisabledEvent"} | Select CreatedTime, UserName, FullFormattedMessage

# Disconnect from vCenter
Disconnect-ViServer $vc -Confirm:$false
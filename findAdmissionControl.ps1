# Variables
$infile = "C:\vcenters.csv"
$outfile = "C:\outfile.csv"

# Import file containing vCenter details
Import-Csv $infile | ForEach {

	# Connect to vCenter
	Connect-VIServer $_.vcenter -Username $_.user -Password $_.pass

	# Retrieve Admission Control details
	Get-VMHost | Get-Cluster | Select Name,HAAdmissionControlEnabled | Export-Csv $outfile

	# Disconnect from vCenter
	Disconnect-VIServer $vc -Confirm:$false
}
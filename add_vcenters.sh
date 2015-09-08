#!/bin/bash

# Variables

INPUT=vcenters.csv
OLDIFS=$IFS
IFS=,

# Read CSV file
while read vcname vcip vcuser vcpass
do

	# Test connectivity to the vCenter IP address
	curl -s -k --connect-timeout 5 https://$vcip >/dev/null 2>&1
	
	if [ $? -eq 0 ]   
	then   
		# Register the vCenter with vCOPs
		vcops-admin register --vc-name $vcname  --vc-server https://$vcip/sdk --user $vcuser --password $vcpass --force
	else
		# Write error message
		echo "No connectivity to vCenter" $vcname" at" $vcip". Please check firewall rules"
	fi
		
# Close CSV file
done < $INPUT

# Reset IFS
IFS=$OLDIFS
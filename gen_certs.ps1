# Author:	@virtualhobbit
# Website:	http://virtualhobbit.com
# Ref:		http://virtualhobbit.com/2015/07/20/building-an-advanced-lab-using-vmware-vrealize-automation-part-7-configure-vcenter-server-appliance-ssl-certificates

# Variables

$svc_array = @("vCenterSSO","InventoryService","LogBrowser","AutoDeploy")
$certdir = "C:\Certs"
$issuingCA = "issuingca.mdb-lab.com\mdb-lab.com Issuing CA"
$template = "CertificateTemplate:VMwareSSL"
$wc = New-Object System.Net.WebClient
$wc.UseDefaultCredentials = $true
$chain = "$certdir\certnew.p7b"

# Create folder for each service
ForEach ($svc in $svc_array){

New-Item $certdir\$svc -type directory

}

cd $certdir

# Create custom configuration file for each service
ForEach ($svc in $svc_array){
	
	$file = "$svc.cfg"
	
	$fullpath = Join-Path $certdir $svc
	
	$conf = Join-Path $fullpath $file

	copy $certdir\gen_conf.cfg $conf
	
	$content = (Get-Content $conf | %{$_ -replace "organizationalUnitName =","organizationalUnitName = $svc"})
	
	Set-Content -Path $conf -Value $content

}

# Create CSR
ForEach ($svc in $svc_array){
	
	$workingdir = Join-Path $certdir $svc
	
	C:\OpenSSL\bin\openssl req -new -nodes -out $workingdir\rui.csr -keyout $workingdir\rui.key -config $workingdir\$svc.cfg

}

# Submit the CSR to the Certificate Authority
ForEach ($svc in $svc_array){
	
	$reqfile = "rui.csr"
	
	$crtfile = "rui.crt"
	
	$workingdir = Join-Path $certdir $svc
	
	cd $workingdir
	
	certreq -submit -config $issuingCA -attrib $template $reqfile $crtfile
	
}

# Tidy up
Get-ChildItem C:\Certs -include *.csr,*.cfg -Recurse | Remove-Item

# Download certificate chain
$issuingCA = "issuingca.mdb-lab.com"
$url = "https"+"://$issuingCA/certsrv/certnew.p7b?ReqID=CACert&Renewal=0&Enc=b64"
$wc.DownloadFile($url,$chain)

# Convert certificate chaim to PEM format
$pemchain = "$certdir\certnew.pem"
C:\OpenSSL\bin\openssl pkcs7 -print_certs -in $chain -out $pemchain
Remove-Item $chain

# Remove extra lines from chain
$cachain = "$certdir\cachain.pem"
Get-Content $pemchain | Where { $_ -notmatch "subject" -and $_ -notmatch "issuer"} | Set-Content $cachain
(Get-Content $cachain) | ? {$_.trim() -ne "" } | Set-Content $cachain
Remove-Item $pemchain

# Add certificate to chain
ForEach ($svc in $svc_array){

$workingdir = Join-Path $certdir $svc

Get-Content $workingdir\rui.crt,$cachain | Set-Content $workingdir\chain.pem

}
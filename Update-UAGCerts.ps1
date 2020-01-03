<#
.SYNOPSIS
Uploads freshly minted certs to Horizon UAG

.DESCRIPTION
Generates an SSL certificate from Let's Encrypt, then connects to each UAG using the REST API and applies the certificate to the Internet interface. The Admin interface (port 9443) is unaffected.

.PARAMETER dnsName
The public DNS name of the UAG

.PARAMETER uags
Comma-seperated list of UAGs

.EXAMPLE
Update-UAGCerts.ps1 <DNS name> <UAGs>

.NOTES
Author: Mark Brookfield (@virtualhobbit)

#>

param(
    [Parameter(Position=0,Mandatory=$true)]
    [string]$dnsName,
	
	[Parameter(Position=1,Mandatory=$true)]
	[string[]]$uags
)

if (!$dnsName) {
    Write-Error "No DNS name supplied - aborting"
    exit
}

if (!$uags) {
    Write-Error "No UAGs supplied - aborting"
    exit
}

# Define Lets Encrypt parameters
$psMod = "Posh-ACME"
$dnsPlugin = "Route53"
$r53Params = @{R53AccessKey='YOURACCESSKEY'; R53SecretKey='YOURSECRETKEY'}
$email = "you@youremail.com"

# Define UAG credentials
$user = 'admin'
Write-Host "Please enter the UAG admin password. Please note this must be the same for all UAGs."
$pass = Read-Host -AsSecureString "Admin password"
$pass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
$creds = "$($user):$($pass)"

# Encode credentials
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($creds))

if (!(Get-InstalledModule -Name $psMod)) {
    # Install the Posh-ACME module 
    Install-Module -Name $psMod -Scope CurrentUser -Force
}

# Set Let's Encrypt server
Set-PAServer LE_PROD
 
# Order the certificate
New-PACertificate $dnsName -AcceptTOS -DnsPlugin $dnsPlugin -PluginArgs $r53Params -Contact $email -Verbose -Force
$newCert = Get-PACertificate

# Convert private key to one-liner
$privKey = [IO.File]::ReadAllText($newCert.KeyFile)
$privKeyReplace = $privKey.Replace("`n",'\n')

# Convert SSL certificate to one-liner 
$cert = [IO.File]::ReadAllText($newCert.FullChainFile)
$certReplace = $cert.Replace("`n",'\n')

# Create JSON body
$json = '{"privateKeyPem":"' + $privKeyReplace + '","certChainPem":"' + $certReplace + '"}'

# Define API parameters
$params = @{
    Headers     = @{ 'Authorization' = "Basic $encodedCreds" }
    Method      = 'PUT'
    Body        = $json
    ContentType = 'application/json'
}

ForEach ($uag in $uags){

    # Define the URI
    $Uri = "https://" + $uag + ':9443/rest/v1/config/certs/ssl'
    
    # Display UAG
    Write-Host "UAG is: " $uag

    # Connect to each UAG and replace SSL certificate and private key
    Invoke-RestMethod $uri @params 

}
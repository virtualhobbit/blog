#!/bin/sh

while IFS=, read name email
do
	
   sed -e "s/emailAddress =$/emailAddress = ${email}/" client.cnf > client_tmp.cnf

   sed -e “s/commonName =$/commonName = ${name}/“ client_tmp.cnf > $name.cnf	
	
   openssl req -new -out $name.csr -keyout $name.key -config ./$name.cnf

   openssl ca -batch -keyfile ca.key -cert ca.pem -in $name.csr -key `grep output_password ca.cnf | sed 's/.*=//;s/^ *//'` -out $name.crt -extensions xpclient_ext -extfile xpextensions -config ./$name.cnf

   openssl pkcs12 -export -out $name.p12 -inkey $name.key -in $name.crt -certfile ca.der -passin pass:`grep output_password ca.cnf | sed 's/.*=//;s/^ *//'` -passout pass:VMware1!
    
   rm -f client_tmp.cnf $name.cnf $name.csr $name.key $name.crt

done < users.csv
#!/bin/sh

if [ ! -f dh ]; then
  openssl dhparam -out dh 1024 || exit 1
  if [ -e /dev/urandom ] ; then
        dd if=/dev/urandom of=./random count=10 >/dev/null 2>&1;
  else
        date > ./random;
  fi
fi

if [ ! -f server.key ]; then
  openssl req -new  -out server.csr -keyout server.key -config ./server.cnf || exit 1
fi

if [ ! -f ca.key ]; then
  openssl req -new -x509 -keyout ca.key -out ca.pem -days `grep default_days ca.cnf | sed 's/.*=//;s/^ *//'` -config ./ca.cnf || exit 1
fi

if [ ! -f index.txt ]; then
  touch index.txt
fi

if [ ! -f serial ]; then
  echo '01' > serial
fi

if [ ! -f server.crt ]; then
  openssl ca -batch -keyfile ca.key -cert ca.pem -in server.csr  -key `grep output_password ca.cnf | sed 's/.*=//;s/^ *//'` -out server.crt -extensions xpserver_ext -extfile xpextensions -config ./server.cnf || exit 1
fi

if [ ! -f server.p12 ]; then
  openssl pkcs12 -export -in server.crt -inkey server.key -out server.p12  -passin pass:`grep output_password server.cnf | sed 's/.*=//;s/^ *//'` -passout pass:`grep output_password server.cnf | sed 's/.*=//;s/^ *//'` || exit 1
fi

if [ ! -f server.pem ]; then
  openssl pkcs12 -in server.p12 -out server.pem -passin pass:`grep output_password server.cnf | sed 's/.*=//;s/^ *//'` -passout pass:`grep output_password server.cnf | sed 's/.*=//;s/^ *//'` || exit 1
  openssl verify -CAfile ca.pem server.pem || exit 1
fi

if [ ! -f ca.der ]; then
  openssl x509 -inform PEM -outform DER -in ca.pem -out ca.der || exit 1
fi
#!/bin/bash

public_key_file="$1"
keyId="$2"

#
# Get the modulus out ('n' in jwks lingo) from the public key
#
modulus="$( openssl rsa -pubin -inform PEM -text -noout < "${public_key_file}" | \
      sed 's/Modulus=//' | \
      xxd -r -p | \
      base64 --wrap=0 )"

## If the public exponent is 65537, it is "AQAB" base64-encoded
# You can run the command below to see the exponent:
#
# openssl rsa -in "${private_key_file}" -text -noout | grep publicExponent | sed 's/publicExponent: //'
#
exponent="AQAB"

key_id="key1"

echo "{}"                         | \
  jq --arg x "RSA"             '.keys[0].kty=$x'     | \
  jq --arg x "${exponent}"     '.keys[0].e=$x'       | \
  jq --arg x "${modulus}"      '.keys[0].n=$x'       | \
  jq --arg x "${keyId}"        '.keys[0].kid=$x'       | \
  iconv --from-code=ascii --to-code=utf-8 

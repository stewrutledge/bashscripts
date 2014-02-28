#!/bin/bash
# A simple bash script for generating CSRs in which the only difference in info will be the Common Name
# Define the various variables to your fitting and just run the script, it will prompt you for the CN
# Author and Maintainer Stewart Rutledge <stewart.rutledge@kb.se>

if ! which openssl >/dev/null ; then
  echo "openssl binary could not be found. Make sure it installed and found in your \$PATH"
  exit 1
fi


while getopts ":l:c:s:o:u:d:iShn" opts; do
  case $opts in
    l)
      location=$OPTARG
      ;;
    c)
      country=$OPTARG
      ;;
    s)
      state=$OPTARG
      ;;
    o)
      org=$OPTARG
      ;;
    u)
      orgunit=$OPTARG
      ;;
    d)
      domain=$OPTARG
      ;;
    i)
      insecure=true
      ;;
    S)
      san=true
      ;;
    h)
      need_help=true
      ;;
    n)
      no_pw=true
      ;;
   esac
done

function usage {
  echo "$0 [-in] [-S] [-d] [-l -c -s -o -u]
  -l <Location> [Default: Stockholm]
  -c <Two Letter Country Code Country> [Default: SE]
  -s <State [Default: Stockholm]
  -o <Organization> [Default: Kungliga Biblioteket]
  -u <Organizational Unit> (optional)
  -d <Domain> (Required)
  -i (Generate insecure key)
  -S (Generate SAN)
  -n (Do not create a password protected key)
  -h Show more help
  "
}

function help_message {
  echo "Help:
  If creating a SAN certifate, domains must be provided in a comma seperated list, with the first domain name being used as the common name
  The only requirements with a SAN certifate are the domain names themselves, however if other information is provided it will override the defaults
  C=SE
  O=Kungliga Biblioteket
  ST=Stockholm
  L=Stockholm
  "
}
test $need_help && help_message && exit 0
function gen_key {
  echo -e "\033[38;5;148mGenerating key with $out_file\033[39m"
  openssl genrsa -des3 -out $out_file.key 2048;
}

function gen_passwordless_key {
  echo -e "\033[38;5;148mGenerating passwordless key with $out_file\033[39m"
  openssl genrsa -out $out_file.key 2048
}


function gen_san_config(){
echo "[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
prompt = no
[req_distinguished_name]
countryName = $country
stateOrProvinceName = $state
organizationName = $org
localityName = $location" > ./$out_file.cfg


if [[ ! -z $orgunit ]]; then
  echo "organizationalUnitName = $orgunit" >> ./$out_file.cfg
fi
echo "
commonName = $out_file
[ v3_req ]

# Extensions to add to a certificate request

basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]" >> ./$out_file.cfg

i=0

IFS=',' read -ra ADDR <<< "$domain"
for a in "${ADDR[@]}"; do
    let i=$i+1
    echo "DNS.$i = $a" >> $out_file.cfg
done
}

function nopasswd_key (){
  echo -e "\033[38;5;148mGenerating passwordless key, enter password used during key creation\033[39m"
  openssl rsa -in "$out_file.key" -out "$out_file.key.insecure";
  mv "$out_file.key" "$out_file.key.secure";
  mv "$out_file.key.insecure" "$out_file.key";
}

function gen_csr (){
   if [[ $san ]]; then
      echo -e "\033[38;5;148mGenerating SAN CSR\033[39m"
      openssl req -new -out $out_file.csr -key $out_file.key -config $out_file.cfg
  else
  if [[ $insecure ]]; then
    echo -e "\033[38;5;148mGenerating CSR\033[39m"
  else
    echo -e "\033[38;5;148mGenerating CSR, enter password used during key generation\033[39m"
  fi
  if  [[ -z "$orgunit" ]]; then
      openssl req -new -key "$out_file.key" -out ./"$out_file.csr" -batch -subj "/C=$country/ST=$state/L=$location/O=$org/CN=$domain/CN=$domain"
    else
      openssl req -new -key "$out_file.key" -out ./"$out_file.csr" -batch -subj "/C=$country/ST=$state/L=$location/O=$org/OU=$orgunit/CN=$domain"
  fi
  fi
}

if [[ -z "$domain" ]]; then
    echo "Domain is required!"
    usage
    exit 1
fi

test "$location" || location="Stockholm"
test "$country" || country="SE"
test "$state" || state="stockholm"
test "$org" || org="Kungliga Biblioteket"

if [[ $(echo $domain | egrep ",") ]] && [[ -z $san ]]; then
    echo "Looks like you're trying to make a SAN csr, but you didn't provide -S"
    exit 1
fi
if [[ $(echo $domain | egrep ",") ]]; then
   out_file=$(echo $domain | cut -d"," -f1)
   echo $out_file
elif [[ $(echo $domain | egrep "^[*.]") ]]; then
    out_file="wildcard.${domain:2}"
else
    out_file=$domain
fi

test $(echo $out_file | egrep "^[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*(?:\.[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*)*$") ||echo -e "\033[0;31mWarning! Not a valid domain! $out_file Continuing anyway...\033[39m"

if [[ "$country" ]] && [[ "$country" != [A-Za-z][A-Za-z] ]];then
  echo "Please use two letter country code"
  exit 1
fi


if [[ $insecure ]] && [[ -z $no_pw ]]; then
    gen_key
    nopasswd_key
elif [[ $no_pw ]]; then
    gen_passwordless_key
elif [[ -z $insecure ]] && [[ -z $no_pw ]]; then
    gen_key
fi
if [[ $(echo $domain | egrep ",") ]]; then
  gen_san_config
fi
gen_csr
echo -e "\033[38;5;148mDone!\033[39m"
exit 0



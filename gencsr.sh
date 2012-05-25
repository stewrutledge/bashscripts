#!/bin/bash
# A simple bash script for generating CSRs in which the only difference in info will be the Common Name
# Define the various variables to your fitting and just run the script, it will prompt you for the CN

which openssl
check_openssl=$(echo $?)
if [[ $check_openssl == 1 ]]; then
  echo "openssl binary could not be found. Make sure it installed and found in your \$PATH"
  exit 1
fi
 

while getopts ":l:c:s:o:u:d:i:" opts; do
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
      insecure=$OPTARG
      ;;
   esac
done

function usage {
  echo "$0 [-l -c -s -o -u -d -i [y]
  -l Location
  -c Two Letter Country Code Country
  -s State
  -o Organization
  -u Organizational Unit
  -d Domain
  -i Generate insecure key (-i y)
  "
} 



function gen_key {
  echo -e "\033[38;5;148mGenerating key with $domain\033[39m"
  openssl genrsa -des3 -out $domain.key 2048;
}



function nopasswd_key (){
  echo -e "\033[38;5;148mGenerating passwordless key, enter password used during key creation\033[39m"
  openssl rsa -in $domain.key -out $domain.key.insecure;
  mv $domain.key $domain.key.secure;
  mv $domain.key.insecure $domain.key;
}

function gen_csr (){
  if [[ $insecure == "y" ]]; then
    echo -e "\033[38;5;148mGenerating CSR\033[39m"
  else
    echo -e "\033[38;5;148mGenerating CSR, enter password used during key generation\033[39m"
  fi
  openssl req -new -key $domain.key -out ./$domain.csr -batch -subj "/C=$country/ST=$state/L=$location/O=$org/OU=$orgunit/CN=$domain/CN=$domain"
}

if [[ -z "$location" ]] || [[ -z "$country" ]] || [[ -z "$state" ]] || [[ -z "$org" ]] || [[ -z "$orgunit" ]] || [[ -z "$domain" ]]; then
  usage
  exit 1
fi

if [[ "$country" != [A-Za-z][A-Za-z] ]];then
  echo "Please use two letter country code"
  exit 1
fi

if [[ -z $insecure ]]; then
  gen_key
  gen_csr
  echo -e "\033[38;5;148mDone!\033[39m"
  exit 0
fi

if [[ $insecure == "y" ]]; then
  gen_key
  nopasswd_key
  gen_csr
  echo -e "\033[38;5;148mDone!\033[39m"
  exit 0
else
  echo "Please specify "y" and only "y" if you want a key with no password"
  exit 1
fi


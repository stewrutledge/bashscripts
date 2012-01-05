#!/bin/bash
# A simple bash script for generating CSRs in which the only difference in info will be the Common Name
# Define the various variables to your fitting and just run the script, it will prompt you for the CN

Location=YourLocation
Country=EnterCountryHere
State=EnterStateHere
Org=EnterOrgnaztionHere
OrgUnit=YourOU

 function gencsr {
                if [ -f $domain.key ];
                        then
                echo -e "\033[38;5;148m$domain.key found, generating a new csr\033[39m"
                openssl req -new -key $domain.key -out ./$domain.csr -batch -subj "/C=$Country/ST=$State/L=Stockholm/O=$Org/OU=$OrgUnit/CN=$domain"
                        else
                echo -e "\033[38;5;148mNo key found, generating one now\033[39m"
                openssl genrsa -des3 -out $domain.key 2048;
                echo -e "\033[38;5;148mGenerating passwordless key, enter password used during key creation\033[39m"
                openssl rsa -in $domain.key -out $domain.key.insecure;
                mv $domain.key $domain.key.secure;
                mv $domain.key.insecure $domain.key;
                openssl req -new -key $domain.key -out ./$domain.csr -batch -subj "/C=$Country/ST=$State/L=Stockholm/O=$Org/OU=$OrgUnit/CN=$domain/CN=$domain"
                fi      }


echo "Quick CSR creation with no spelling mistakes"
echo -n "Enter Domain Name: "
read domain

echo -e "\033[32mThis script will attempt to create a key and an associated CSR. If there is a key file with the name $domain.key then it will use that for the CSR.\033[39m"
echo -e "You have entered: \033[31m$domain\033[39m"
while true; do
    read -p "Is this correct and do you wish to continue? [Y/N] "  yn
    case $yn in
        [Yy]* ) gencsr; break;;
        [Nn]* ) exit;;
        * ) echo "This is a yes or no question, try again";;
    esac
done

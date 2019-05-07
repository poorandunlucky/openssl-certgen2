#!/bin/sh -

echo -n "\n"
echo "----------------------------------------"
echo "OpenSSL Certificate Generation Utility"
echo "----------------------------------------"
echo -n "\n"
echo "Current directory is `pwd`"
echo -n "\n"
echo "Please choose what you want to do:"
echo -n "\n"
echo "1. Create a private key"
echo "2. Create a self-signed Root CA Certificate"
echo "3. Create a certificate for an Issuing Authority"
echo "4. Create a certificate for a Service Authority"
echo "5. Create a certificate for a Server"
echo "6. Create a certificate for a User"
echo "7. Create a Certificate Revocation List (Not Yet Implemented)"
echo -n "\n"
echo "Other commands:"
echo -n "\n"
echo "lpk: Load private key."
echo "lpw: Load password."
echo -n "\n"
echo "init: Initialize the utility in this directory."
echo -n "\n"
echo -n "Selection: "

read menu_main

case $menu_main in

	"1" )

		echo "\nPlease give a name to your key; the output file will be ./<name>.key.pem."
		echo "Tip: Entering cas/<name>, servers/<name>, or users/<name> will put the key in the appropriate directory."
		echo -n "\nName for your key? (try "cas/root" for Root CA) "

		read name_key

		if [ $name_key = "\n" ]
		then
			$name_key = "private"
		fi

		echo -n "\nWould you like to password-protect your private key? (y/n) "

		read menu_passpk

		case $menu_passpk in

			"y" )

				dd if=/dev/random of=random.out count=2048
				sha1sum random.out | awk '{ print $1 }' > ${name_key}.password.out
				shred -f -u random.out

				echo "******************************"
				echo "Password: `cat ${name_key}.password.out`"
				echo "******************************"

				if [ $? -eq 0 ]
					then echo "Password generated, also output to: ${name_key}.password.out."
				fi

				openssl genrsa -out ${name_key}.key.pem -passout file:${name_key}.password.out -aes256 -F4 -rand /dev/random 4096

				if [ $? -eq 0 ]
					then echo "Private key generated, output to: ${name_key}.key.pem"
				fi;;

			"n" )

				openssl genrsa -out ${name_key}.key.pem -passout file:${name_key}.password.out -aes256 -F4 -rand /dev/random 4096

				if [ $? -eq 0 ]
					then echo "Private key generated, output to: ${name_key}.key.pem"
				fi;;

		esac;;

	"2" )

		echo -n "\nIs your private key password-protected? (y/n) "

		read menu_passkey

		case $menu_passkey in

			"y" )

				openssl req -new -config .openssl/openssl.conf -outform PEM -out cas/root.cert.request -sha256 -keyform PEM -key cas/root.key.pem -passin file:cas/root.password.out -days 1461 -set_serial 0 -utf8 -nameopt multiline -verbose

				if [ $? -eq 0 ]
					then echo "Certificate request created, output to: cas/root.cert.request"
				fi

				openssl ca -config .openssl/openssl.conf -in cas/root.cert.request -out cas/root.cert.pem -outdir .openssl/backup -keyfile cas/root.key.pem -keyform PEM -passin file:cas/root.password.out -selfsign -days 1461 -utf8 -extensions x509_ca_root -policy ca_policy_authorities

				if [ $? -eq 0 ]
					then echo "Root CA certificate created, output to: cas/root.cert.pem."
				fi;;

			"n" )

				openssl req -new -config .openssl/openssl.conf -outform PEM -out cas/root.cert.request -sha256 -keyform PEM -key cas/root.key.pem -passin file:cas/root.password.out -days 1461 -set_serial 0 -utf8 -nameopt multiline -verbose

				if [ $? -eq 0 ]
					then echo "Certificate request created, output to cas/root.cert.request"
				fi

				openssl ca -config .openssl/openssl.conf -in cas/root.cert.request -out cas/root.cert.pem -outdir .openssl/backup -keyfile cas/root.key.pem -keyform PEM -passin file:cas/root.password.out -selfsign -days 1461 -utf8 -extensions x509_ca_root -policy ca_policy_authorities

				if [ $? -eq 0 ]
					then echo "Root CA certificate created, output to: cas/root.cert.pem"
				fi;;

		esac;;

	"3" )

		echo "\nWhat is the name of your Issuing Authority?  Key should be under cas/<name>.key.pem."
		echo -n "\nName of your Issuing Authority? "

		read ia_name

		if [ ! -e "cas/${ia_name}.key.pem" ]
		then
			echo "Error: Private key not found."
			return 1
		fi

		echo -n "\nIs your private key password-protected? (y/n) "

		read menu_passkey

		case $menu_passkey in

			"y" )

				openssl req -new -config .openssl/openssl.conf -outform PEM -out cas/${ia_name}.cert.request -sha256 -keyform PEM -key cas/${ia_name}.key.pem -passin file:cas/${ia_name}.password.out -days 1461 -utf8 -nameopt multiline -verbose

				if [ $? -eq 0 ]
					then echo "Certificate request created, output to: cas/${ia_name}.cert.request"
				fi

				openssl ca -config .openssl/openssl.conf -in cas/${ia_name}.cert.request -out cas/${ia_name}.cert.pem -outdir .openssl/backup -days 1461 -utf8 -keyform PEM -keyfile cas/root.key.pem -passin file:cas/root.password.out -cert cas/root.cert.pem -extensions x509_ca_issuing -policy ca_policy_authorities

				if [ $? -eq 0 ]
					then echo "Issuing CA certificate created, output to: cas/${ia_name}.cert.pem."
				fi;;

			"n" )

				openssl req -new -config .openssl/openssl.conf -outform PEM -out cas/${ia_name}.cert.request -sha256 -keyform PEM -key cas/${ia_name}.key.pem -days 1461 -utf8 -nameopt multiline -verbose

				if [ $? -eq 0 ]
					then echo "Certificate request created, output to cas/${ia_name}.cert.request"
				fi

				openssl ca -config .openssl/openssl.conf -in cas/${ia_name}.cert.request -out cas/${ia_name}.cert.pem -outdir .openssl/backup -days 1461 -utf8 -keyform PEM -keyfile cas/root.key.pem -cert cas/root.cert.pem -extensions x509_ca_issuing -policy ca_policy_authorities

				if [ $? -eq 0 ]
					then echo "Issuing CA certificate created, output to: cas/${ia_name}.cert.pem"
				fi;;

		esac;;

	"4" )

		echo -n "\nPlease enter the name of your Service Authority: "

		read sa_name

		if [ ! -e "cas/${sa_name}.key.pem" ]
		then
			echo "Error: Private key not found."
			return 1
		fi

		echo -n "\nWhat is the name of the Parent of your Service Authority? "

		read pa_name

		if [ ! -e "cas/${pa_name}.key.pem" ]
		then
			echo "Error: Parent private key not found."
			return 1
		fi

		echo -n "\nIs your private key password-protected? (y/n) "

		read menu_passkey

		case $menu_passkey in

			"y" )

				openssl req -new -config .openssl/openssl.conf -outform PEM -out cas/${sa_name}.cert.request -sha256 -keyform PEM -key cas/${sa_name}.key.pem -passin file:cas/${sa_name}.password.out -days 1461 -utf8 -nameopt multiline -verbose

				if [ $? -eq 0 ]
					then echo "Certificate request created, output to: cas/${sa_name}.cert.request"
				fi

				openssl ca -config .openssl/openssl.conf -in cas/${sa_name}.cert.request -out cas/${sa_name}.cert.pem -outdir .openssl/backup -days 1461 -utf8 -keyform PEM -keyfile cas/${pa_name}.key.pem -passin file:cas/${pa_name}.password.out -cert cas/${pa_name}.cert.pem -extensions x509_ca_service -policy ca_policy_authorities

				if [ $? -eq 0 ]
					then echo "Service CA certificate created, output to: cas/${sa_name}.cert.pem."
				fi;;

			"n" )

				openssl req -new -config .openssl/openssl.conf -outform PEM -out cas/${sa_name}.cert.request -sha256 -keyform PEM -key cas/${sa_name}.key.pem -days 1461 -utf8 -nameopt multiline -verbose

				if [ $? -eq 0 ]
					then echo "Certificate request created, output to cas/${sa_name}.cert.request"
				fi

				openssl ca -config .openssl/openssl.conf -in cas/${sa_name}.cert.request -out cas/${sa_name}.cert.pem -outdir .openssl/backup -days 1461 -utf8 -keyform PEM -keyfile cas/${pa_name}.key.pem -cert cas/${pa_name}.cert.pem -extensions x509_ca_service -policy ca_policy_authorities

				if [ $? -eq 0 ]
					then echo "Service CA certificate created, output to: cas/${sa_name}.cert.pem"
				fi;;

		esac;;

	"5" )

		echo -n "\nPlease enter the name of your Server: "

		read sv_name

		if [ ! -e "servers/${sv_name}.key.pem" ]
		then
			echo "Error: Private key not found."
			return 1
		fi

		echo -n "\nWhat is the name of your Server's Parent? "

		read pa_name

		if [ ! -e "cas/${pa_name}.key.pem" ]
		then
			echo "Error: Parent private key not found."
			return 1
		fi

		echo -n "\nIs your private key password-protected? (y/n) "

		read menu_passkey

		case $menu_passkey in

			"y" )

				openssl req -new -config .openssl/openssl.conf -outform PEM -out servers/${sv_name}.cert.request -sha256 -keyform PEM -key servers/${sv_name}.key.pem -passin file:servers/${sv_name}.password.out -days 1461 -utf8 -nameopt multiline -verbose

				if [ $? -eq 0 ]
					then echo "Certificate request created, output to: servers/${sv_name}.cert.request"
				fi

				openssl ca -config .openssl/openssl.conf -in servers/${sv_name}.cert.request -out servers/${sv_name}.cert.pem -outdir .openssl/backup -days 1461 -utf8 -keyform PEM -keyfile cas/${pa_name}.key.pem -passin file:cas/${pa_name}.password.out -cert cas/${pa_name}.cert.pem -extensions x509_server_default -policy ca_policy_services

				if [ $? -eq 0 ]
					then echo "Server certificate created, output to: servers/${sv_name}.cert.pem."
				fi;;

			"n" )

				openssl req -new -config .openssl/openssl.conf -outform PEM -out servers/${sv_name}.cert.request -sha256 -keyform PEM -key servers/${sv_name}.key.pem -days 1461 -utf8 -nameopt multiline -verbose

				if [ $? -eq 0 ]
					then echo "Certificate request created, output to servers/${sv_name}.cert.request"
				fi

				openssl ca -config .openssl/openssl.conf -in servers/${sv_name}.cert.request -out servers/${sv_name}.cert.pem -outdir .openssl/backup -days 1461 -utf8 -keyform PEM -keyfile cas/${pa_name}.key.pem -cert cas/${pa_name}.cert.pem -extensions x509_server_default -policy ca_policy_services

				if [ $? -eq 0 ]
					then echo "Server CA certificate created, output to: servers/${sv_name}.cert.pem"
				fi;;

		esac;;

	"6" )


		echo -n "\nPlease enter the name of your User: "

		read u_name

		if [ ! -e "users/${u_name}.key.pem" ]
		then
			echo "Error: Private key not found."
			return 1
		fi

		echo -n "\nWhat is the name of your User's Parent? "

		read pa_name

		if [ ! -e "cas/${pa_name}.key.pem" ]
		then
			echo "Error: Parent private key not found."
			return 1
		fi

		echo -n "\nIs your private key password-protected? (y/n) "

		read menu_passkey

		case $menu_passkey in

			"y" )

				openssl req -new -config .openssl/openssl.conf -outform PEM -out users/${u_name}.cert.request -sha256 -keyform PEM -key users/${u_name}.key.pem -passin file:users/${u_name}.password.out -days 1461 -utf8 -nameopt multiline -verbose

				if [ $? -eq 0 ]
					then echo "Certificate request created, output to: users/${u_name}.cert.request"
				fi

				openssl ca -config .openssl/openssl.conf -in users/${u_name}.cert.request -out users/${u_name}.cert.pem -outdir .openssl/backup -days 1461 -utf8 -keyform PEM -keyfile cas/${pa_name}.key.pem -passin file:cas/${pa_name}.password.out -cert cas/${pa_name}.cert.pem -extensions x509_user_default -policy ca_policy_users

				if [ $? -eq 0 ]
					then echo "User certificate created, output to: users/${u_name}.cert.pem."
				fi;;

			"n" )

				openssl req -new -config .openssl/openssl.conf -outform PEM -out users/${u_name}.cert.request -sha256 -keyform PEM -key users/${u_name}.key.pem -days 1461 -utf8 -nameopt multiline -verbose

				if [ $? -eq 0 ]
					then echo "Certificate request created, output to users/${u_name}.cert.request"
				fi

				openssl ca -config .openssl/openssl.conf -in users/${u_name}.cert.request -out users/${u_name}.cert.pem -outdir .openssl/backup -days 1461 -utf8 -keyform PEM -keyfile cas/${pa_name}.key.pem -cert cas/${pa_name}.cert.pem -extensions x509_user_default -policy ca_policy_users

				if [ $? -eq 0 ]
					then echo "User certificate created, output to: users/${u_name}.cert.pem"
				fi;;

		esac;;

	"7" ) echo "Create a Certificate Revocation List (Not Yet Implemented)";;
	"lpk" ) echo "Load private key";;
	"lpw" ) echo "Load password";;
	"init" )

		echo "\nThis utility should be initialized in an empty directory."
		echo -n "Are you sure you want to continue? (\"yes\" or \"no\") "

		read init_response

		case $init_response in

		"yes" )

			echo "\nThis will erase ALL of this directory's content!"
			echo -n "Are you sure you wish to proceed? (\"yes\" or \"no\") "

			read init_confirm

			case $init_confirm in

			"yes" )

				tmpdir="openssl-`date +"%y%m%d%H%M%S"`"
				mkdir -m 0700 /tmp/${tmpdir}
				cp -p ${0} /tmp/${tmpdir}
				rm -R ./*
				rm -R ./.*
				cp -p /tmp/${tmpdir}/`echo $0 | awk 'BEGIN {FS = "/"} ; {print $2}'` .
				rm -R /tmp/${tmpdir}
				mkdir -m 0700 .openssl
				mkdir -m 0700 cas
				mkdir -m 0700 servers
				mkdir -m 0700 users
				touch .openssl/ca.db.index
				touch .openssl/ca.db.serial
				touch .openssl/ca.db.crl
				touch .openssl/tsa.db.serial
				chmod 0600 .openssl/*
				mkdir -m 0700 .openssl/backup
				echo '00' > .openssl/ca.db.serial
				echo '00' > .openssl/tsa.db.serial
				init_cnf="true";;

			"no" )

				echo "\nNothing was done.  Exiting.";;

			esac;;

		"no" )

			echo "\nPlease move this script to an appropriate location, and try to initialize again.";;

		esac;;

esac

echo -n "\n"
echo "Don't forget to move your files into their storage directory!"


#
# Configuration File Creation Function

createConfigFile () {
	echo '################################################################################
# OpenSSL Configuration File
# ==============================================================================
# Configures the OpenSSL certificate management tooklit.
# ------------------------------------------------------------------------------
# Information, usage, notes, etc.
# ==============================================================================

#
# Module Configuration

[ req ]

default_bits = 4096
defailt_md = sha256
RANDFILE = /dev/randomhy
string_mask = utf8only
distinguished_name = req_info_template
attributes = req_info_attributes
req_extensions = x509_open

# default_keyfile = privkey.pem
# input_password = secret
# output_password = secret

[ req_info_template ]

countryName = Country Code
countryName_default = CA
countryName_min = 2
countryName_max = 2
stateOrProvinceName = State or Province Name
stateOrProvinceName_default = QC
localityName = Locality Name
localityName_default = Montréal

0.organizationName = Organization Name
0.organizationName_default = Patrick Dorion
#1.organizationName = Second Organization Name (eg, company)
#1.organizationName_default = World Wide Web Pty Ltd
organizationalUnitName = Department
organizationalUnitName_default = SSL/TLS Certificate Management
commonName = FQDN or User Name
commonName_max = 64
commonName_default = OpenSSL Certificate
emailAddress = Contact E-mail
emailAddress_max = 64
emailAddress_default = dorionpatrick@outlook.com

[ req_info_attributes ]

challengePassword = Challenge password for request access
challengePassword_min = 4
challengePassword_max = 32

unstructuredName = Optional name, note, or comment
unstructuredName_default = OpenSSL Certificate Request

[ ca ]

default_ca = ca_config_default
RANDFILE = /dev/random

[ ca_config_default ]

dir = ./
certs = $dir/
crl_dir = $dir/
new_certs_dir = $dir/
database = $dir/.openssl/ca.db.index
serial = $dir/.openssl/ca.db.serial
crlnumber = $dir/.openssl/ca.db.crl

default_days = 1461
default_crl_days = 1
default_md = sha256
unique_subject = no
preserve = yes

# certificate = $dir/cacert.pem
# crl = $dir/crl.pem
# private_key = $dir/cakey.pem

policy = ca_policy_open
x509_extensions = x509_open

[ ca_policy_authorities ]

countryName = match
stateOrProvinceName = match
localityName = match
organizationName = match
organizationalUnitName = optional
commonName = supplied
emailAddress = optional

[ ca_policy_services ]

countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = match
organizationalUnitName = optional
commonName = supplied
emailAddress = optional

[ ca_policy_users ]

countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = match
organizationalUnitName = match
commonName = supplied
emailAddress = optional

[ ca_policy_open ]

countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional

[ tsa ]

default_tsa = tsa_config_default

[ tsa_config_default ]

dir = .
serial = $dir/.openssl/tsa.db.serial
crypto_device = builtin
signer_digest = sha256
digests = sha1, sha256, sha384, sha512
accuracy = secs:1, millisecs:500, microsecs:100
clock_precision_digits = 0
ordering = yes
tsa_name = yes
ess_cert_id_chain = no

#signer_cert = $dir/tsacert.pem
#certs = $dir/cacert.pem
#signer_key = $dir/tsakey.pem

default_policy = tsa_policy_default
#other_policies = tsa_policy_01, tsa_policy_02

tsa_policy_default = 1.2.3.4.1
tsa_policy_02 = 1.2.3.4.5.6
tsa_policy_03 = 1.2.3.4.5.7

#
# x509 Profiles

[ x509_ca_root ]

basicConstraints = critical, CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always, issuer:always
keyUsage = critical, cRLSign, digitalSignature, keyCertSign
# crlDistributionPoints = crl_default
#subjectAltName = @x509_ca_root

[ x509_ca_issuing ]

basicConstraints = critical, CA:TRUE, pathlen:1
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always, issuer:always
keyUsage = critical, cRLSign, digitalSignature, keyCertSign
# crlDistributionPoints = crl_default
#subjectAltName = @x509_ca_issuing

[ x509_ca_service ]

basicConstraints = critical, CA:TRUE, pathlen:0
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always, issuer:always
keyUsage = critical, cRLSign, digitalSignature, keyCertSign
# crlDistributionPoints = crl_default
#subjectAltName = @x509_ca_service

[ x509_server_default ]

basicConstraints = critical, CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always, issuer:always
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment, keyAgreement
extendedKeyUsage = critical, serverAuth
# crlDistributionPoints = crl_default
#subjectAltName = @x509_server_default

[ x509_proxy_default ]

basicConstraints = critical, CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always, issuer:always
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment, keyAgreement
extendedKeyUsage = critical, serverAuth
proxyCertInfo = critical, language:id-ppl-anyLanguage, pathlen:3, policy:default			# Line not configured
# crlDistributionPoints = crl_default
#subjectAltName = @x509_proxy_default

[ x509_user_default ]

basicConstraints = critical, CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always, issuer:always
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = critical, clientAuth, emailProtection
# crlDistributionPoints = crl_default
#subjectAltName = @x509_user_default
#subjectAltName = email:copy

[ x509_codesign_default ]

basicConstraints = critical, CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always, issuer:always
keyUsage = critical, nonRepudiation, digitalSignature
extendedKeyUsage = critical, codeSigning, msCodeInd, msCodeCom, mcCTLSign, timeStamping
# crlDistributionPoints = crl_default
#subjectAltName = @x509_codesign_default

[ x509_open ]

basicConstraints = critical, CA:FALSE
subjectKeyIdentifier = hash

#
# CRL Stuff (Not Fully Implemented)

[ x509_crl_default ]

issuerAltName = issuer:copy
authorityKeyIdentifier = keyid:always, issuer:always

[ crl_default ]

fullname = URI:http://www.hostname.tld/crl.pem
CRLissuer = dirName:crl_issuer_default
reasons = superceded, affiliationChanged, privilegeWithdrawn, certificateHold, removeFromCRL, cessationOfOperations, keyCompromise, cACompromise, aACompromise, unspecified

[ crl_issuer_default ]

O = Patrick Dorion
OU = SSL/TLS Certificate Management
CN = OpenSSL CRL

#
# OIDs (Not Implemented)

# oid_file = $ENV::HOME/.oid
oid_section = oids_default

[ oids_default ]

# testoid = 1.2.3.4

# ==============================================================================
# Patrick Dorion <dorionpatrick@outlook.com>                            May 2019
################################################################################' > .openssl/openssl.conf
	chmod 0400 .openssl/openssl.conf
}

if [ $init_cnf = "true" ]
then
	createConfigFile
fi

# ==============================================================================
# Patrick Dorion <dorionpatrick@outlook.com>                            May 2019
################################################################################

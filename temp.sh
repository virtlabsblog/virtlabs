accountStatus
aRecord
associatedDomain
audio
authorityRevocationList
automountInformation
automountKey
automountMapName
bootFile
bootParameter
buildingName
businessCategory
c
cACertificate
carLicense
certificateRevocationList
cNAMERecord
co
commonName
countryname
countryName
crossCertificatePair
dc
deliveryMode
deliveryProgramPath
deltaRevocationList
departmentNumber
description
descriptionpresentationAddress
destinationIndicator
displayName
dmdName
dnQualifier
documentIdentifier
documentLocation
documentPublisher
documentTitle
documentVersion
domainComponent
drink
dSAQuality
email
emailAddress
employeeNumber
employeeType
enhancedSearchGuide
facsimiletelephonenumber
facsimileTelephoneNumber
favouriteDrink
fax
friendlyCountryName
gecos
generationQualifier
gidNumber
givenname
givenName
gn
homeDirectory
homephone
homePhone
homePostalAddress
homeTelephoneNumber
host
houseIdentifier
info
initials
internationaliSDNNumber
internationalISDNNumber
ipHostNumber
ipNetmaskNumber
ipNetworkNumber
ipProtocolNumber
ipServicePort
ipServiceProtocol
janetMailbox
jpegPhoto
knowledgeInformation
l
labeledURI
localityName
loginShell
macAddress
mail
mailAlternateAddress
mailForwardingAddress
mailHost
mailMessageStore
mailPreferenceOption
mailQuota
managerUid
mDRecord
member
memberNisNetgroup
memberUid
mobile
mobileTelephoneNumber
mXRecord
nisDomain
nisMapEntry
nisMapName
nisNetgroupTriple
nisPublicKey
nisSecretKey
nSRecord
o
oncRpcNumber
organizationalStatus
organizationalUnitName
organizationName
otherMailbox
ou
owner
pager
pagerTelephoneNumber
personalSignature
personalTitle
photo
phpgwAddressLabel
phpgwAdrOneType
phpgwAdrTwoCountryName
phpgwAdrTwoLocality
phpgwAdrTwoPostalCode
phpgwAdrTwoRegion
phpgwAdrTwoStreet
phpgwAdrTwoType
phpgwAudio
phpgwBbsTelephoneNumber
phpgwBirthday
phpgwCellTelephoneNumber
phpgwContactAccess
phpgwContactCatId
phpgwContactOwner
phpgwContactTypeId
phpgwGeo
phpgwIsdnphoneNumber
phpgwMailHome
phpgwMailHomeType
phpgwMailType
phpgwMiddlename
phpgwMobileTelephoneNumber
phpgwModemTelephoneNumber
phpgwMsgTelephoneNumber
phpgwPagerTelephoneNumber
phpgwPreferPhone
phpgwPrefix
phpgwPublicKey
phpgwSuffix
phpgwTz
phpgwUrl
phpgwVideophoneNumber
phpgwVoiceTelephoneNumber
physicalDeliveryOfficeName
pkcs9email
postalAddress
postalcode
postalCode
postOfficeBox
preferredDeliveryMethod
preferredLanguage
presentationAddress
protocolInformation
pseudonym
qmailAccountPurge
qmailDotMode
qmailGID
qmailUID
registeredAddress
rfc822Mailbox
roleOccupant
roomNumber
searchGuide
seeAlso
serialNumber
singleLevelQuality
sn
sOARecord
st
stateOrProvinceName
street
streetaddress
streetAddress
subtreeMaximumQuality
subtreeMinimumQuality
supportedAlgorithms
supportedApplicationContext
surname
telephonenumber
telephoneNumber
teletexTerminalIdentifier
telexNumber
textEncodedORAddress
title
uid
uidnumber
uidNumber
uniqueIdentifier
uniqueMember
userCertificate
userClass
userid
userPKCS12
userSMIMECertificate
vacationActive
vacationEnd
vacationForward
vacationInfo
vacationStart
x121Address
x500uniqueIdentifier
x500UniqueIdentifier

admin
associatedName
auditor
dITRedirect
documentAuthor
manager
secretary



#!/usr/bin/env bash 

# Conexão LDAP
LDAP_URI="ldap://172.17.6.2/"
LDAP_BINDDN="CN=Manager,DC=ITAIPU"
LDAP_BINDDN_PASSWORD_FILE="/root/passwordldap.txt"
LDAP_SEARCH_BASE="OU=Users,DC=ITAIPU"

# Conexão Active Directory através do SAMBA4 local
AD_URI="ldap://127.0.0.1/"
AD_BINDDN="CN=Administrator,CN=Users,DC=ITAIPU,DC=LAB"
AD_BINDDN_PASSWORD_FILE="/root/passwordad.txt"
AD_SEARCH_BASE="CN=Users,DC=ITAIPU,DC=LAB"

# Arquivos
ATTR_FILE="/root/attr.txt"
ATTR_DN_FILE="/root/attr_dn.txt"
LDAP_USER_FILES="/tmp/ldap_user.txt"

# Comandos
LDAPSEARCH="/usr/bin/ldapsearch"
LDBMODIFY="/usr/bin/ldbmodify"
RM="/usr/bin/rm"

# Diversos
LDB_MODULES_PATH=/usr/lib64/samba/ldb/
export LDB_MODULES_PATH

# Valida permissão de execução nos comandos necessários
if [ ! -x "${LDAPSEARCH}" ]; then
  echo "comando ${LDAPSEARCH} não possui permissão de execução, impossível continuar"
  exit 1
fi

if [ ! -x "${LDBMODIFY}" ]; then
  echo "comando ${LDBMODIFY} não possui permissão de execução, impossível continuar"
  exit 1
fi

if [ ! -x "${RM}" ]; then
  echo "comando ${RM} não possui permissão de execução, impossível continuar"
  exit 1
fi

# Gera lista de usuários existentes no LDAP
"${LDAPSEARCH}" -o ldif-wrap=no \
                -H "${LDAP_URI}" \
                -D "${LDAP_BINDDN}" \
                -y "${LDAP_BINDDN_PASSWORD_FILE}" \
                -b "${LDAP_SEARCH_BASE}" \
                -LLL "(&(sambaSID=*))" uid | \
                grep "^uid: " | \
                awk -F ": " '{ print $2 }' | \
                sort -n > ${LDAP_USER_FILES}

# Sincroniza atributo mail
#while read USER; do
#  VALUE=$(${LDAPSEARCH} -o ldif-wrap=no \
#                        -H "${LDAP_URI}" \
#                        -D "${LDAP_BINDDN}" \
#                        -y "${LDAP_BINDDN_PASSWORD_FILE}" \
#                        -b "${LDAP_SEARCH_BASE}" \
#                        -LLL "(&(sambaSID=*)(uid=${USER}))" mail | \
#                       grep "^mail: " | awk -F ": " '{ print $2 }')
#
#  if [ "x${VALUE}" != "x" ]; then
#    ADDN=$(${LDAPSEARCH} -o ldif-wrap=no \
#                         -H "${AD_URI}" \
#                         -D "${AD_BINDDN}" \
#                         -y "${AD_BINDDN_PASSWORD_FILE}" \
#                         -b "${AD_SEARCH_BASE}" \
#                         -LLL "(&(objectClass=User)(sAMAccountName=${USER}))" dn | \
#                        grep "^dn: " | awk -F ": " '{ print $2 }')
#
#
#    echo ${ADDN} mail ${VALUE}
#    ${LDBMODIFY} -H /var/lib/samba/private/sam.ldb << EOD
#dn: ${ADDN}
#changetype: modify
#add: mail
#mail: ${VALUE}
#EOD
#  fi
#
#  unset ADDN
#  unset VALUE
#
#done < "${LDAP_USER_FILES}"

# Sincroniza atributo uid
#while read USER; do
#  VALUE=$(${LDAPSEARCH} -o ldif-wrap=no \
#                        -H "${LDAP_URI}" \
#                        -D "${LDAP_BINDDN}" \
#                        -y "${LDAP_BINDDN_PASSWORD_FILE}" \
#                        -b "${LDAP_SEARCH_BASE}" \
#                        -LLL "(&(sambaSID=*)(uid=${USER}))" uid | \
#                       grep "^uid: " | awk -F ": " '{ print $2 }')
#
#  if [ "x${VALUE}" != "x" ]; then
#    ADDN=$(${LDAPSEARCH} -o ldif-wrap=no \
#                         -H "${AD_URI}" \
#                         -D "${AD_BINDDN}" \
#                         -y "${AD_BINDDN_PASSWORD_FILE}" \
#                         -b "${AD_SEARCH_BASE}" \
#                         -LLL "(&(objectClass=User)(sAMAccountName=${USER}))" dn | \
#                        grep "^dn: " | awk -F ": " '{ print $2 }')
#
#    echo ${ADDN} uid ${VALUE}
#    ${LDBMODIFY} -H /var/lib/samba/private/sam.ldb << EOD
#dn: ${ADDN}
#changetype: modify
#add: uid
#uid: ${VALUE}
#EOD
#  fi
#
#  unset ADDN
#  unset VALUE
#
#done < "${LDAP_USER_FILES}"

# Sincroniza objectClass
while read USER; do
  declare -A LDAPOC
  declare -A ADOC
  
  OC_FILE=/tmp/oc_"${USER}".txt
  
  ${LDAPSEARCH} -o ldif-wrap=no \
                -H "${LDAP_URI}" \
                -D "${LDAP_BINDDN}" \
                -y "${LDAP_BINDDN_PASSWORD_FILE}" \
                -b "${LDAP_SEARCH_BASE}" \
                -LLL "(&(uid=${USER}))" objectClass| \
                grep -v -e "^dn: " -e "sambaSamAccount" -e "^$" | \
                awk -F ": " '{ print $2 }' > "${OC_FILE}"
                         
  while read ATTR; do
    LDAPOC["$(echo ${ATTR} | awk -F ": " '{ print $2 }')"]=TRUE
  done < <(${LDAPSEARCH} -o ldif-wrap=no \
                         -H "${LDAP_URI}" \
                         -D "${LDAP_BINDDN}" \
                         -y "${LDAP_BINDDN_PASSWORD_FILE}" \
                         -b "${LDAP_SEARCH_BASE}" \
                         -LLL "(&(uid=${USER}))" objectClass | \
                         grep -v "^$" )
  
  while read ATTR; do
    if [ "$(echo ${ATTR} | awk -F : '{ print $1 }')" == "dn" ]; then
      ADOC[dn]=$(echo ${ATTR} | awk -F ": " '{ print $2 }')
    else
      ADOC["$(echo ${ATTR} | awk -F ": " '{ print $2 }')"]=TRUE
    fi
  done < <(${LDAPSEARCH} -o ldif-wrap=no \
                         -H "${AD_URI}" \
                         -D "${AD_BINDDN}" \
                         -y "${AD_BINDDN_PASSWORD_FILE}" \
                         -b "${AD_SEARCH_BASE}" \
                         -LLL "(&(sAMAccountName=${USER}))" objectClass| \
                         grep -v "^$")
  for OC in $(cat "${OC_FILE}"); do
    if [ "x${LDAPOC[${OC}]}" != "x${ADOC[${OC}]}" ]; then
      echo ${ADOC[dn]} objecClass ${OC}
      ${LDBMODIFY} -H /var/lib/samba/private/sam.ldb << EOD
dn: ${ADOC[dn]}
changetype: modify
add: objectClass
objectClass: ${OC}
EOD
echo $?
    fi
  done

  unset LDAPOC
  unset ADOC

  "${RM}" "${OC_FILE}"

done < "${LDAP_USER_FILES}"

# Sincroniza atributos
while read USER; do
  declare -A LDAPOBJECT
  declare -A ADOBJECT
  while read ATTR; do 
    INDEX=$(echo ${ATTR} | awk -F ": " '{ print $1 }')
    VALUE=$(echo ${ATTR} | awk -F ": " '{ print $2 }')
    LDAPOBJECT["${INDEX}"]="${VALUE}"
  done < <(${LDAPSEARCH} -o ldif-wrap=no \
                         -H "${LDAP_URI}" \
                         -D "${LDAP_BINDDN}" \
                         -y "${LDAP_BINDDN_PASSWORD_FILE}" \
                         -b "${LDAP_SEARCH_BASE}" \
                         -LLL "(&(sambaSID=*)(uid=${USER}))" \
                         $(sort "${ATTR_FILE}"  | awk 'BEGIN {RS=""}{gsub(/\n/," ",$0); print $0}') | \
                         grep -v "^$")
  while read ATTR; do 
    INDEX=$(echo ${ATTR} | awk -F ": " '{ print $1 }') 
    VALUE=$(echo ${ATTR} | awk -F ": " '{ print $2 }') 
    ADOBJECT["${INDEX}"]="${VALUE}"
  done < <(${LDAPSEARCH} -o ldif-wrap=no \
                         -H "${AD_URI}" \
                         -D "${AD_BINDDN}" \
                         -y "${AD_BINDDN_PASSWORD_FILE}" \
                         -b "${AD_SEARCH_BASE}" \
                         -LLL "(&(objectClass=User)(sAMAccountName=${USER}))" \
                         $(sort "${ATTR_FILE}"  | awk 'BEGIN {RS=""}{gsub(/\n/," ",$0); print $0}') | \
                         grep -v "^$")
  for ATTR in $(cat "${ATTR_FILE}"); do
    if [ "${ATTR}" == "jpegPhoto" ]; then
      ATTR2="jpegPhoto:"
    else
      ATTR2="${ATTR}"
    fi
    if [ "x${LDAPOBJECT[${ATTR2}]}" != "x${ADOBJECT[${ATTR2}]}" ]; then
      echo ${ADOBJECT[dn]} ${ATTR} ${LDAPOBJECT[${ATTR2}]:0:100}
      ${LDBMODIFY} -H /var/lib/samba/private/sam.ldb << EOD
dn: ${ADOBJECT[dn]}
changetype: modify
add: ${ATTR}
${ATTR2}: ${LDAPOBJECT[${ATTR2}]}
EOD
echo $?
    fi
  done
  
  unset LDAPOBJECT
  unset ADOBJECT
  unset INDEX
  unset VALUE
done < "${LDAP_USER_FILES}"

# Sincroniza atributos com syntax do tipo DN
while read USER; do
  declare -A LDAPOBJECT
  declare -A ADOBJECT
  while read ATTR; do
    INDEX=$(echo ${ATTR} | awk -F ": " '{ print $1 }')
    VALUE=$(echo ${ATTR} | awk -F ": " '{ print $2 }')
    LDAPOBJECT["${INDEX}"]="${VALUE}"
  done < <(${LDAPSEARCH} -o ldif-wrap=no \
                         -H "${LDAP_URI}" \
                         -D "${LDAP_BINDDN}" \
                         -y "${LDAP_BINDDN_PASSWORD_FILE}" \
                         -b "${LDAP_SEARCH_BASE}" \
                         -LLL "(&(sambaSID=*)(uid=${USER}))" \
                         $(sort "${ATTR_DN_FILE}"  | awk 'BEGIN {RS=""}{gsub(/\n/," ",$0); print $0}') | \
                         grep -v "^$")
  while read ATTR; do
    INDEX=$(echo ${ATTR} | awk -F ": " '{ print $1 }')
    VALUE=$(echo ${ATTR} | awk -F ": " '{ print $2 }')
    ADOBJECT["${INDEX}"]="${VALUE}"
  done < <(${LDAPSEARCH} -o ldif-wrap=no \
                         -H "${AD_URI}" \
                         -D "${AD_BINDDN}" \
                         -y "${AD_BINDDN_PASSWORD_FILE}" \
                         -b "${AD_SEARCH_BASE}" \
                         -LLL "(&(objectClass=User)(sAMAccountName=${USER}))" \
                         $(sort "${ATTR_DN_FILE}"  | awk 'BEGIN {RS=""}{gsub(/\n/," ",$0); print $0}') | \
                         grep -v "^$")
  for ATTR in $(cat "${ATTR_DN_FILE}"); do
    AD_ATTR_SAMACCOUNT=$(echo ${LDAPOBJECT[${ATTR}]} | sed "s/uid=//I;s/,${LDAP_SEARCH_BASE}//I")
    AD_ATTR=$(${LDAPSEARCH} -o ldif-wrap=no \
                         -H "${AD_URI}" \
                         -D "${AD_BINDDN}" \
                         -y "${AD_BINDDN_PASSWORD_FILE}" \
                         -b "${AD_SEARCH_BASE}" \
                         -LLL "(&(objectClass=User)(sAMAccountName=${AD_ATTR_SAMACCOUNT}))" dn | \
                         awk -F ": " '{ print $2 }')
    if [ "x${AD_ATTR}" != "x${ADOBJECT[${ATTR}]}" ]; then
      echo ${ADOBJECT[dn]} ${ATTR} ${AD_ATTR}
      ${LDBMODIFY} -H /var/lib/samba/private/sam.ldb << EOD
dn: ${ADOBJECT[dn]}
changetype: modify
add: ${ATTR}
${ATTR}: ${AD_ATTR}
EOD
echo $?
    fi
  done

  unset LDAPOBJECT
  unset ADOBJECT
  unset INDEX
  unset VALUE
done < "${LDAP_USER_FILES}"

rm "${LDAP_USER_FILES}"

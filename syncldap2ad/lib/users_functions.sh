. /opt/syncldap2ad/conf/variables

. /opt/syncldap2ad/lib/general_functions.sh

ldap_generate_new_users_list () 
{ 
  ${LDAPSEARCH} -o ldif-wrap=no \
                -H "${LDAP_URI}" \
                -D "${LDAP_BINDDN}" \
                -y "${LDAP_BINDDN_PASSWORD_FILE}" \
                -b "${LDAP_USERS_OU},${LDAP_BASE}" \
                -LLL -v "(&(createTimestamp>=${TIMESTAMP_LAST_USERS_CREATE}Z))" uid | \
                grep "^uid: " | \
                grep -v -e root -e Guest | \
                awk -F ": " '{ print $2 }' | \
                sort -n > ${LDAP_NEW_USERS_FILE}

  if [ ${?} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

ad_generate_new_users_list ()
{
  ${LDAPSEARCH} -o ldif-wrap=no \
                -E pr=999999/noprompt \
                -H "${AD_URI}" \
                -D "${AD_BINDDN}" \
                -y "${AD_BINDDN_PASSWORD_FILE}" \
                -b "${AD_USERS_OU},${AD_BASE}" \
                -LLL "(&(objectClass=user)(whenCreated>=${TIMESTAMP_LAST_USERS_CREATE}.0Z))" sAMAccountName | \
                grep "^sAMAccountName: " | \
                awk -F ": " '{ print $2 }' | \
                sort -n > ${AD_NEW_USERS_FILE} 

  if [ ${?} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

ldap_generate_modified_users_list () 
{ 
  ${LDAPSEARCH} -o ldif-wrap=no \
                -H "${LDAP_URI}" \
                -D "${LDAP_BINDDN}" \
                -y "${LDAP_BINDDN_PASSWORD_FILE}" \
                -b "${LDAP_USERS_OU},${LDAP_BASE}" \
                -LLL "(&(sambaSID=*)(modifyTimestamp>=${TIMESTAMP_LAST_USERS_SYNC}Z))" uid | \
                grep "^uid: " | \
                grep -v -e root -e Guest | \
                awk -F ": " '{ print $2 }' | \
                sort -n > ${LDAP_LAST_MODIFIED_USERS_FILE}

  if [ ${?} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

ad_generate_modified_users_list ()
{
  ${LDAPSEARCH} -o ldif-wrap=no \
                -E pr=999999/noprompt \
                -H "${AD_URI}" \
                -D "${AD_BINDDN}" \
                -y "${AD_BINDDN_PASSWORD_FILE}" \
                -b "${AD_USERS_OU},${AD_BASE}" \
                -LLL "(&(objectClass=User)(whenChanged>=${TIMESTAMP_LAST_USERS_SYNC}.0Z))" sAMAccountName | \
                grep "^sAMAccountName: " | \
                awk -F ": " '{ print $2 }' | \
                sort -n > ${AD_LAST_MODIFIED_USERS_FILE} 

  if [ ${?} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

ldap_generate_users_list () 
{ 
  ${LDAPSEARCH} -o ldif-wrap=no \
                -H "${LDAP_URI}" \
                -D "${LDAP_BINDDN}" \
                -y "${LDAP_BINDDN_PASSWORD_FILE}" \
                -b "${LDAP_USERS_OU},${LDAP_BASE}" \
                -LLL "(&(sambaSID=*))" uid | \
                grep "^uid: " | \
                grep -v -e root -e Guest | \
                awk -F ": " '{ print $2 }' | \
                sort -n > ${LDAP_USERS_FILE}

  if [ ${?} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

ad_generate_users_list ()
{
  ${LDAPSEARCH} -o ldif-wrap=no \
                -E pr=999999/noprompt \
                -H "${AD_URI}" \
                -D "${AD_BINDDN}" \
                -y "${AD_BINDDN_PASSWORD_FILE}" \
                -b "${AD_USERS_OU},${AD_BASE}" \
                -LLL "(&(objectClass=User))" sAMAccountName | \
                grep "^sAMAccountName: " | \
                grep -v -e root -e Guest | \
                awk -F ": " '{ print $2 }' | \
                sort -n > ${AD_USERS_FILE} 

  if [ ${?} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

ldap_search_user ()
{
  declare USER_ACCOUNT

  USER_ACCOUNT="${1}"

  "${LDAPSEARCH}" -o ldif-wrap=no \
                  -H "${LDAP_URI}" \
                  -D "${LDAP_BINDDN}" \
                  -y "${LDAP_BINDDN_PASSWORD_FILE}" \
                  -b "${LDAP_USERS_OU},${LDAP_BASE}" \
                  -LLL "(&(uid=${USER_ACCOUNT}))" ${ATTRIBUTES} ${ATTRIBUTES_DN} objectClass modifyTimestamp createTimestamp | \
                  grep -v "^$" > ${TEMP_DIR}/ldap_${USER_ACCOUNT}

  unset USER_ACCOUNT

  if [ ${?} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

ad_search_user ()
{
  declare USER_ACCOUNT

  USER_ACCOUNT="${1}"

  ${LDAPSEARCH} -o ldif-wrap=no \
                -E pr=999999/noprompt \
                -H "${AD_URI}" \
                -D "${AD_BINDDN}" \
                -y "${AD_BINDDN_PASSWORD_FILE}" \
                -b "${AD_USERS_OU},${AD_BASE}" \
                -LLL "(&(sAMAccountName=${USER_ACCOUNT}))" ${ATTRIBUTES} ${ATTRIBUTES_DN} objectClass whenChanged whenCreated objectSid sAMAccountName | \
                grep -v -e "^$" -e "pagedresults:" > ${TEMP_DIR}/ad_${USER_ACCOUNT}

  unset USER_ACCOUNT

  if [ ${?} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

ldap_search_user_attr ()
{
  declare USER_ACCOUNT

  USER_ACCOUNT="${1}"
  USER_ATTR="${2}"

  "${LDAPSEARCH}" -o ldif-wrap=no \
                  -H "${LDAP_URI}" \
                  -D "${LDAP_BINDDN}" \
                  -y "${LDAP_BINDDN_PASSWORD_FILE}" \
                  -b "${LDAP_USERS_OU},${LDAP_BASE}" \
                  -LLL "(&(uid=${USER_ACCOUNT}))" ${USER_ATTR} | \
                  grep -v "^$" 

  unset USER_ACCOUNT USER_ATTR

  if [ ${?} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

ad_search_user_attr_by_samaccount ()
{
  declare USER_ACCOUNT

  USER_ACCOUNT="${1}"
  USER_ATTR="${2}"

  ${LDAPSEARCH} -o ldif-wrap=no \
                -E pr=999999/noprompt \
                -H "${AD_URI}" \
                -D "${AD_BINDDN}" \
                -y "${AD_BINDDN_PASSWORD_FILE}" \
                -b "${AD_USERS_OU},${AD_BASE}" \
                -LLL "(&(sAMAccountName=${USER_ACCOUNT}))" ${USER_ATTR} | \
                grep -v -e "^$" -e "pagedresults:"

  unset USER_ACCOUNT USER_ATTR

  if [ ${?} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

ad_search_user_attr_by_cn ()
{
  declare USER_ACCOUNT

  USER_ACCOUNT="${1}"
  USER_ATTR="${2}"

  ${LDAPSEARCH} -o ldif-wrap=no \
                -E pr=999999/noprompt \
                -H "${AD_URI}" \
                -D "${AD_BINDDN}" \
                -y "${AD_BINDDN_PASSWORD_FILE}" \
                -b "${AD_USERS_OU},${AD_BASE}" \
                -LLL "(&(cn=${USER_ACCOUNT}))" ${USER_ATTR} | \
                grep -v -e "^$" -e "pagedresults:"

  unset USER_ACCOUNT USER_ATTR

  if [ ${?} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

create_user_ldap2ad ()
{
  declare USER_ACCOUNT

  declare -A LDAP_OBJECT
  
  USER_ACCOUNT="${1}"

  LDIF_FILE="${TEMP_DIR}/create_ldap2ad_${USER_ACCOUNT}.ldif"

  LDAP_OBJECTCLASS_FILE="${TEMP_DIR}/ldap_${USER_ACCOUNT}_objectclass"

  grep objectClass ${TEMP_DIR}/ldap_${USER_ACCOUNT} | awk -F ": " '{ print $2 }' | sort -n > ${LDAP_OBJECTCLASS_FILE}

  while read ATTR; do
    ATTR_NAME=$(echo ${ATTR} | awk -F ": " '{ print $1 }')
    ATTR_VALUE=$(echo ${ATTR} | awk -F ": " '{ print $2 }')
    LDAP_OBJECT["${ATTR_NAME}"]="${ATTR_VALUE}"
  done < <(grep -v -e objectClass -e modifyTimestamp -e createTimestamp ${TEMP_DIR}/ldap_${USER_ACCOUNT})

  while read LDAP_OBJECTCLASS; do
    if [ ! -f ${LDIF_FILE} ]; then
      echo "dn: ${LDAP_OBJECT[dn]}" > ${LDIF_FILE}
      echo "changetype: add" >> ${LDIF_FILE}
      echo "objectClass: ${LDAP_OBJECTCLASS}" >> ${LDIF_FILE}
    else
      echo "objectClass: ${LDAP_OBJECTCLASS}" >> ${LDIF_FILE}
    fi
  done < <(grep -v sambaSamAccount ${LDAP_OBJECTCLASS_FILE})

  while read ATTR; do
    if [ "${ATTR}" != "cn" ]; then     
      if [ \( "${ATTR}" == "jpegPhoto" \) -o \( "${ATTR}" == "audio" \) ]; then
        ATTRTEMP="${ATTR}:"
      else
        ATTRTEMP="${ATTR}"
      fi
      if [ ! -z "${LDAP_OBJECT[${ATTRTEMP}]}" ]; then
        if [ ! -f ${LDIF_FILE} ]; then
          echo "dn: ${LDAP_OBJECT[dn]}" > ${LDIF_FILE}
          echo "changetype: add" >> ${LDIF_FILE}
          echo "${ATTRTEMP}: ${LDAP_OBJECT[${ATTRTEMP}]}" >> ${LDIF_FILE}
        else
          echo "${ATTRTEMP}: ${LDAP_OBJECT[${ATTRTEMP}]}" >> ${LDIF_FILE}
        fi
      fi
    fi
    
  done < ${ATTR_FILE}
  
  while read ATTR_DN; do
    if [ ! -z "${LDAP_OBJECT[${ATTR_DN}]}" ]; then
      DN_LDAP_ACCOUNT=$(echo ${LDAP_OBJECT[${ATTR_DN}]} | sed s/uid=//I | sed s/,ou=Users,dc=ITAIPU//I)
      DN_AD_ACCOUNT=$(ad_search_user_attr_by_samaccount "${DN_LDAP_ACCOUNT}" dn | sed "s/dn: //")
      if [ ! -f ${LDIF_FILE} ]; then
        echo "dn: ${LDAP_OBJECT[dn]}" > ${LDIF_FILE}
        echo "changetype: add" >> ${LDIF_FILE}
        echo "${ATTR_DN}: ${DN_AD_ACCOUNT}" >> ${LDIF_FILE}
      else
        echo "${ATTR_DN}: ${DN_AD_ACCOUNT}" >> ${LDIF_FILE}
      fi
    fi
  done < ${ATTR_DN_FILE}
  
  echo "sAMAccountName: ${USER_ACCOUNT}" >> ${LDIF_FILE}
  
  if [ ! -z "${LDAP_OBJECT[cn]}" ]; then
    sed -i "/^dn: /s/dn: uid=${USER_ACCOUNT}/dn: cn=${LDAP_OBJECT[cn]}/I;/^dn: /s/ou=users,dc=itaipu/OU=Users LDAP,DC=ITAIPU,DC=LAB/I" ${LDIF_FILE}
  else
    sed -i "/^dn: /s/dn: uid=/dn: cn=/I;/^dn: /s/ou=users,dc=itaipu/OU=Users LDAP,DC=ITAIPU,DC=LAB/I" ${LDIF_FILE}
  fi
  
  ${LDAPMODIFY} -H "${AD_URI}" -D "${AD_BINDDN}" -y "${AD_BINDDN_PASSWORD_FILE}" -f ${LDIF_FILE}
  
  OBJECT_SID=$(ad_search_user_attr_by_samaccount "${LDAP_OBJECT[uid]}" objectSid | grep objectSid | awk -F ": " '{ print $2}')
  USER_SID=$(decode_sid ${OBJECT_SID})
  
  if ! grep sambaSamAccount ${LDAP_OBJECTCLASS_FILE}; then
    echo "dn: ${LDAP_OBJECT[dn]}" > ${LDIF_FILE}
    echo "changetype: modify" >> ${LDIF_FILE}
    echo "add: objectClass" >> ${LDIF_FILE}
    echo "objectClass: sambaSamAccount" >>${LDIF_FILE}
    echo "-" >> ${LDIF_FILE}
  else
    echo "dn: ${LDAP_OBJECT[dn]}" > ${LDIF_FILE}
    echo "changetype: modify" >> ${LDIF_FILE}
  fi
  echo "replace: sambaSID" >> ${LDIF_FILE}
  echo "sambaSID: ${USER_SID}" >> ${LDIF_FILE}
  
  ${LDAPMODIFY} -H "${LDAP_URI}" -D "${LDAP_BINDDN}" -y "${LDAP_BINDDN_PASSWORD_FILE}" -f ${LDIF_FILE}

  rm -rf ${LDIF_FILE} ${LDAP_OBJECTCLASS_FILE}
}

create_user_ad2ldap ()
{
  declare USER_ACCOUNT

  declare -A AD_OBJECT
  
  USER_ACCOUNT="${1}"

  LDIF_FILE="${TEMP_DIR}/create_ad2ldap_${USER_ACCOUNT}.ldif"

  AD_OBJECTCLASS_FILE="${TEMP_DIR}/ad_${USER_ACCOUNT}_objectclass"

  grep objectClass ${TEMP_DIR}/ad_${USER_ACCOUNT} |  awk -F ": " '{ print $2 }' | sort -n > ${AD_OBJECTCLASS_FILE}

  while read ATTR; do
    ATTR_NAME=$(echo ${ATTR} | awk -F ": " '{ print $1 }')
    ATTR_VALUE=$(echo ${ATTR} | awk -F ": " '{ print $2 }')
    AD_OBJECT["${ATTR_NAME}"]="${ATTR_VALUE}"
  done < <(grep -v -e objectClass -e whenChanged -e whenCreated ${TEMP_DIR}/ad_${USER_ACCOUNT})

  while read AD_OBJECTCLASS; do
    if [ ! -f ${LDIF_FILE} ]; then
      echo "dn: ${AD_OBJECT[sAMAccountName]}" > ${LDIF_FILE}
      echo "changetype: add" >> ${LDIF_FILE}
      echo "objectClass: ${AD_OBJECTCLASS}" >> ${LDIF_FILE}
    else
      echo "objectClass: ${AD_OBJECTCLASS}" >> ${LDIF_FILE}
    fi
  done < <(grep -v -e user -e person -e organizationalPerson ${AD_OBJECTCLASS_FILE})

  while read ATTR; do
  
    if [ \( "${ATTR}" == "jpegPhoto" \) -o \( "${ATTR}" == "audio" \) ]; then
      ATTRTEMP="${ATTR}:"
    else
      ATTRTEMP="${ATTR}"
    fi
    if [ ! -z "${AD_OBJECT[${ATTRTEMP}]}" ]; then
      if [ ! -f ${LDIF_FILE} ]; then
        echo "dn: ${AD_OBJECT[sAMAccountName]}" > ${LDIF_FILE}
        echo "changetype: add" >> ${LDIF_FILE}
        echo "${ATTRTEMP}: ${AD_OBJECT[${ATTRTEMP}]}" >> ${LDIF_FILE}
      else
        echo "${ATTRTEMP}: ${AD_OBJECT[${ATTRTEMP}]}" >> ${LDIF_FILE}
      fi
    fi
    
  done < ${ATTR_FILE}
  
  while read ATTR_DN; do
    if [ ! -z "${AD_OBJECT[${ATTR_DN}]}" ]; then
      CN_DN_AD_ACCOUNT=$(echo ${AD_OBJECT[${ATTR_DN}]} | sed s/cn=//I | sed s/,ou=Users LDAP,dc=ITAIPU,dc=LAB//I)
      SAM_DN_AD_ACCOUNT=$(ad_search_user_attr_by_cn "${CN_DN_AD_ACCOUNT}" sAMAccountName | sed "s/sAMAccountName: //")
      if [ ! -f ${LDIF_FILE} ]; then
        echo "dn: ${AD_OBJECT[sAMAccountName]}" > ${LDIF_FILE}
        echo "changetype: add" >> ${LDIF_FILE}
        echo "${ATTR_DN}: ${SAM_DN_AD_ACCOUNT}" >> ${LDIF_FILE}
      else
        echo "${ATTR_DN}: ${SAM_DN_AD_ACCOUNT}" >> ${LDIF_FILE}
      fi
    fi
  done < ${ATTR_DN_FILE}
  
  if [ -z "${AD_OBJECT[uid]}" ]; then
    echo "uid: ${AD_OBJECT[sAMAccountName]}" >> ${LDIF_FILE}
  fi

  sed -i "/^dn: /s/dn: /dn: uid=/I;/^dn: /s/$/,ou=users,dc=itaipu/I" ${LDIF_FILE}
  
  USER_SID=$(decode_sid ${AD_OBJECT[objectSid:]})
  
  if ! grep inetOrgPerson ${AD_OBJECTCLASS_FILE} > /dev/null 2>&1 ; then
    echo "objectClass: inetOrgPerson" >>${LDIF_FILE}
  fi

  echo "objectClass: sambaSamAccount" >>${LDIF_FILE}
  echo "sambaSID: ${USER_SID}" >> ${LDIF_FILE}
  
  ${LDAPMODIFY} -H "${LDAP_URI}" -D "${LDAP_BINDDN}" -y "${LDAP_BINDDN_PASSWORD_FILE}" -f ${LDIF_FILE}

  rm -rf ${LDIF_FILE} ${AD_OBJECTCLASS_FILE}
}

sync_user_ldap2ad ()
{
  declare USER_ACCOUNT

  declare -A LDAP_OBJECT
  declare -A AD_OBJECT

  USER_ACCOUNT="${1}"

  LDIF_FILE="${TEMP_DIR}/sync_ldap2ad_${USER_ACCOUNT}.ldif"
  LDIF_FILE_OBJECTCLASS="${TEMP_DIR}/sync_ldap2ad_objectclass_${USER_ACCOUNT}.ldif"

  LDAP_OBJECTCLASS_FILE="${TEMP_DIR}/ldap_${USER_ACCOUNT}_objectclass"
  AD_OBJECTCLASS_FILE="${TEMP_DIR}/ad_${USER_ACCOUNT}_objectclass"

  while read ATTR; do
    ATTR_NAME=$(echo ${ATTR} | awk -F ": " '{ print $1 }')
    ATTR_VALUE=$(echo ${ATTR} | awk -F ": " '{ print $2 }')
    LDAP_OBJECT["${ATTR_NAME}"]="${ATTR_VALUE}"
  done < <(grep -v -e objectClass -e modifyTimestamp -e createTimestamp ${TEMP_DIR}/ldap_${USER_ACCOUNT})

  while read ATTR; do
    ATTR_NAME=$(echo ${ATTR} | awk -F ": " '{ print $1 }')
    ATTR_VALUE=$(echo ${ATTR} | awk -F ": " '{ print $2 }')
    AD_OBJECT["${ATTR_NAME}"]="${ATTR_VALUE}"
  done < <(grep -v -e objectClass -e whenChanged -e WhenCreated ${TEMP_DIR}/ad_${USER_ACCOUNT})

  grep objectClass ${TEMP_DIR}/ldap_${USER_ACCOUNT} | grep -v sambaSamAccount | awk -F ": " '{ print $2 }' | sort -n > ${LDAP_OBJECTCLASS_FILE}
  grep objectClass ${TEMP_DIR}/ad_${USER_ACCOUNT} | grep -v -e user -e person -e organizationalPerson | awk -F ": " '{ print $2 }' | sort -n > ${AD_OBJECTCLASS_FILE}
  
  while read LDAP_OBJECTCLASS; do
    if [ ! -f ${LDIF_FILE} ]; then
      echo "dn: ${AD_OBJECT[dn]}" > ${LDIF_FILE_OBJECTCLASS}
      echo "changetype: modify" >> ${LDIF_FILE_OBJECTCLASS}
      echo "add: objectClass" >> ${LDIF_FILE_OBJECTCLASS}
      echo "objectClass: ${LDAP_OBJECTCLASS}" >> ${LDIF_FILE_OBJECTCLASS}
      echo "-" >> ${LDIF_FILE_OBJECTCLASS}
    else
      echo "add: objectClass" >> ${LDIF_FILE_OBJECTCLASS}
      echo "objectClass: ${LDAP_OBJECTCLASS}" >> ${LDIF_FILE_OBJECTCLASS}
      echo "-" >> ${LDIF_FILE_OBJECTCLASS}
    fi
  done < <(diff ${LDAP_OBJECTCLASS_FILE} ${AD_OBJECTCLASS_FILE} | grep "^<" | awk '{ print $2 }')
  
  while read LDAP_OBJECTCLASS; do
    if [ ! -f ${LDIF_FILE} ]; then
      echo "dn: ${AD_OBJECT[dn]}" > ${LDIF_FILE_OBJECTCLASS}
      echo "changetype: modify" >> ${LDIF_FILE_OBJECTCLASS}
      echo "delete: objectClass" >> ${LDIF_FILE_OBJECTCLASS}
      echo "objectClass: ${LDAP_OBJECTCLASS}" >> ${LDIF_FILE_OBJECTCLASS}
      echo "-" >> ${LDIF_FILE_OBJECTCLASS}
    else
      echo "delete: objectClass" >> ${LDIF_FILE_OBJECTCLASS}
      echo "objectClass: ${LDAP_OBJECTCLASS}" >> ${LDIF_FILE_OBJECTCLASS}
      echo "-" >> ${LDIF_FILE_OBJECTCLASS}
    fi
  done < <(diff ${LDAP_OBJECTCLASS_FILE} ${AD_OBJECTCLASS_FILE} | grep "^>" | awk '{ print $2 }')
  
  while read ATTR; do
    if [ "${ATTR}" != "cn" ]; then
      if [ \( "${ATTR}" == "jpegPhoto" \) -o \( "${ATTR}" == "audio" \) ]; then
        ATTRTEMP="${ATTR}:"
      else
        ATTRTEMP="${ATTR}"
      fi

      if [ "x${LDAP_OBJECT[${ATTRTEMP}]}" != "x${AD_OBJECT[${ATTRTEMP}]}" ]; then
        if [ -z "${LDAP_OBJECT[${ATTRTEMP}]}" ]; then
          MODIFY_TYPE=delete
        elif [ -z "${AD_OBJECT[${ATTRTEMP}]}" ]; then
          MODIFY_TYPE=add
        else
          MODIFY_TYPE=replace
        fi
  
        if [ ! -f ${LDIF_FILE} ]; then 
          echo "dn: ${AD_OBJECT[dn]}" > ${LDIF_FILE}
          echo "changetype: modify" >> ${LDIF_FILE}
          echo "${MODIFY_TYPE}: ${ATTR}" >> ${LDIF_FILE}
          if [ "${MODIFY_TYPE}" != "delete" ]; then
            echo "${ATTRTEMP}: ${LDAP_OBJECT[${ATTRTEMP}]}" >> ${LDIF_FILE}
          fi
          echo "-" >> ${LDIF_FILE}
        else
          echo "${MODIFY_TYPE}: ${ATTR}" >> ${LDIF_FILE}
          if [ "${MODIFY_TYPE}" != "delete" ]; then
            echo "${ATTRTEMP}: ${LDAP_OBJECT[${ATTRTEMP}]}" >> ${LDIF_FILE}
          fi
          echo "-" >> ${LDIF_FILE}
        fi
      fi
    fi
  done < ${ATTR_FILE}
 
#  while read ATTR_DN; do
#    if [ ! -z "${LDAP_OBJECT[${ATTR_DN}]}" ]; then
#      DN_LDAP_ACCOUNT=$(echo ${LDAP_OBJECT[${ATTR_DN}]} | sed s/uid=//I | sed s/,ou=Users,dc=ITAIPU//I)
#      DN_AD_ACCOUNT=$(ad_search_user_attr_by_samaccount "${DN_LDAP_ACCOUNT}" dn | sed "s/dn: //")
#      if [ ! -f ${LDIF_FILE} ]; then
#        echo "dn: ${AD_OBJECT[dn]}" > ${LDIF_FILE}
#        echo "changetype: modify" >> ${LDIF_FILE}
#        echo "add: ${ATTR_DN}" >> ${LDIF_FILE}
#        echo "${ATTR_DN}: ${DN_AD_ACCOUNT}" >> ${LDIF_FILE}
#        echo "-"
#      else
#        echo "changetype: modify" >> ${LDIF_FILE}
#        echo "add: ${ATTR_DN}" >> ${LDIF_FILE}
#        echo "${ATTR_DN}: ${DN_AD_ACCOUNT}" >> ${LDIF_FILE}
#        echo "-"
#      fi
#    fi
#  done < ${ATTR_DN_FILE}
  
  if [ -f ${LDIF_FILE_OBJECTCLASS} ]; then
    ${LDAPMODIFY} -H "${AD_URI}" -D "${AD_BINDDN}" -y "${AD_BINDDN_PASSWORD_FILE}" -f ${LDIF_FILE_OBJECTCLASS} -v
    rm -rf ${LDIF_FILE_OBJECTCLASS}
  fi
  if [ -f ${LDIF_FILE} ]; then
    ${LDAPMODIFY} -H "${AD_URI}" -D "${AD_BINDDN}" -y "${AD_BINDDN_PASSWORD_FILE}" -f ${LDIF_FILE} -v
    rm -rf ${LDIF_FILE}
  fi

  rm -rf ${LDAP_OBJECTCLASS_FILE} ${AD_OBJECTCLASS_FILE}

  unset USER_ACCOUNT AD_OBJECT LDAP_OBJECT LDIF_FILE LDIF_FILE_OBJECTCLASS LDAP_OBJECTCLASS_FILE AD_OBJECTCLASS_FILE
  
}

sync_user_ad2ldap ()
{ 
  declare USER_ACCOUNT

  declare -A AD_OBJECT
  declare -A LDAP_OBJECT

  USER_ACCOUNT="${1}"

  LDIF_FILE="${TEMP_DIR}/sync_ldap2ad_${USER_ACCOUNT}.ldif"
  LDIF_FILE_OBJECTCLASS="${TEMP_DIR}/sync_ldap2ad_objectclass_${USER_ACCOUNT}.ldif"

  LDAP_OBJECTCLASS_FILE="${TEMP_DIR}/ldap_${USER_ACCOUNT}_objectclass"
  AD_OBJECTCLASS_FILE="${TEMP_DIR}/ad_${USER_ACCOUNT}_objectclass"

  while read ATTR; do
    ATTR_NAME=$(echo ${ATTR} | awk -F ": " '{ print $1 }')
    ATTR_VALUE=$(echo ${ATTR} | awk -F ": " '{ print $2 }')
    AD_OBJECT["${ATTR_NAME}"]="${ATTR_VALUE}"
  done < <(grep -v -e objectClass -e whenChanged -e WhenCreated ${TEMP_DIR}/ad_${USER_ACCOUNT})

  while read ATTR; do
    ATTR_NAME=$(echo ${ATTR} | awk -F ": " '{ print $1 }')
    ATTR_VALUE=$(echo ${ATTR} | awk -F ": " '{ print $2 }')
    LDAP_OBJECT["${ATTR_NAME}"]="${ATTR_VALUE}"
  done < <(grep -v -e objectClass -e modifyTimestamp -e createTimestamp ${TEMP_DIR}/ldap_${USER_ACCOUNT})

  grep objectClass ${TEMP_DIR}/ldap_${USER_ACCOUNT} | grep -v sambaSamAccount | awk -F ": " '{ print $2 }' | sort -n > ${LDAP_OBJECTCLASS_FILE}
  grep objectClass ${TEMP_DIR}/ad_${USER_ACCOUNT} | grep -v -e user -e person -e organizationalPerson | awk -F ": " '{ print $2 }' | sort -n > ${AD_OBJECTCLASS_FILE}
  
  while read AD_OBJECTCLASS; do
    if [ ! -f ${LDIF_FILE} ]; then
      echo "dn: ${LDAP_OBJECT[dn]}" > ${LDIF_FILE_OBJECTCLASS}
      echo "changetype: modify" >> ${LDIF_FILE_OBJECTCLASS}
      echo "add: objectClass" >> ${LDIF_FILE_OBJECTCLASS}
      echo "objectClass: ${AD_OBJECTCLASS}" >> ${LDIF_FILE_OBJECTCLASS}
      echo "-" >> ${LDIF_FILE_OBJECTCLASS}
    else
      echo "add: objectClass" >> ${LDIF_FILE_OBJECTCLASS}
      echo "objectClass: ${AD_OBJECTCLASS}" >> ${LDIF_FILE_OBJECTCLASS}
      echo "-" >> ${LDIF_FILE_OBJECTCLASS}
    fi
  done < <(diff ${AD_OBJECTCLASS_FILE} ${LDAP_OBJECTCLASS_FILE} | grep "^<" | awk '{ print $2 }')
  
  while read AD_OBJECTCLASS; do
    if [ ! -f ${LDIF_FILE} ]; then
      echo "dn: ${LDAP_OBJECT[dn]}" > ${LDIF_FILE_OBJECTCLASS}
      echo "changetype: modify" >> ${LDIF_FILE_OBJECTCLASS}
      echo "delete: objectClass" >> ${LDIF_FILE_OBJECTCLASS}
      echo "objectClass: ${AD_OBJECTCLASS}" >> ${LDIF_FILE_OBJECTCLASS}
      echo "-" >> ${LDIF_FILE_OBJECTCLASS}
    else
      echo "delete: objectClass" >> ${LDIF_FILE_OBJECTCLASS}
      echo "objectClass: ${AD_OBJECTCLASS}" >> ${LDIF_FILE_OBJECTCLASS}
      echo "-" >> ${LDIF_FILE_OBJECTCLASS}
    fi
  done < <(diff ${AD_OBJECTCLASS_FILE} ${LDAP_OBJECTCLASS_FILE} | grep "^>" | awk '{ print $2 }')
  
  while read ATTR; do
    if [ \( "${ATTR}" == "jpegPhoto" \) -o \( "${ATTR}" == "audio" \) ]; then
      ATTRTEMP="${ATTR}:"
    else
      ATTRTEMP="${ATTR}"
    fi

    if [ "x${AD_OBJECT[${ATTRTEMP}]}" != "x${LDAP_OBJECT[${ATTRTEMP}]}" ]; then
      if [ -z "${AD_OBJECT[${ATTRTEMP}]}" ]; then
        MODIFY_TYPE=delete
      elif [ -z "${LDAP_OBJECT[${ATTRTEMP}]}" ]; then
        MODIFY_TYPE=add
      else
        MODIFY_TYPE=replace
      fi

      if [ ! -f ${LDIF_FILE} ]; then 
        echo "dn: ${LDAP_OBJECT[dn]}" > ${LDIF_FILE}
        echo "changetype: modify" >> ${LDIF_FILE}
        echo "${MODIFY_TYPE}: ${ATTR}" >> ${LDIF_FILE}
        if [ "${MODIFY_TYPE}" != "delete" ]; then
          echo "${ATTRTEMP}: ${AD_OBJECT[${ATTRTEMP}]}" >> ${LDIF_FILE}
        fi
        echo "-" >> ${LDIF_FILE}
      else
        echo "${MODIFY_TYPE}: ${ATTR}" >> ${LDIF_FILE}
        if [ "${MODIFY_TYPE}" != "delete" ]; then
          echo "${ATTRTEMP}: ${AD_OBJECT[${ATTRTEMP}]}" >> ${LDIF_FILE}
        fi
        echo "-" >> ${LDIF_FILE}
      fi
    fi

  done < ${ATTR_FILE}

#  while read ATTR_DN; do
#    if [ ! -z "${AD_OBJECT[${ATTR_DN}]}" ]; then
#      CN_DN_AD_ACCOUNT=$(echo ${AD_OBJECT[${ATTR_DN}]} | sed s/cn=//I | sed s/,ou=Users LDAP,dc=ITAIPU,dc=LAB//I)
#      SAM_DN_AD_ACCOUNT=$(ad_search_user_attr_by_cn "${CN_DN_AD_ACCOUNT}" sAMAccountName | sed "s/sAMAccountName: //")
#      if [ ! -f ${LDIF_FILE} ]; then
#        echo "dn: ${AD_OBJECT[sAMAccountName]}" > ${LDIF_FILE}
#        echo "changetype: add" >> ${LDIF_FILE}
#        echo "${ATTR_DN}: ${SAM_DN_AD_ACCOUNT}" >> ${LDIF_FILE}
#      else
#        echo "${ATTR_DN}: ${SAM_DN_AD_ACCOUNT}" >> ${LDIF_FILE}
#      fi
#    fi
#  done < ${ATTR_DN_FILE}
  
  if [ -f ${LDIF_FILE_OBJECTCLASS} ]; then
    ${LDAPMODIFY} -H "${LDAP_URI}" -D "${LDAP_BINDDN}" -y "${LDAP_BINDDN_PASSWORD_FILE}" -f ${LDIF_FILE_OBJECTCLASS} 
    rm -rf ${LDIF_FILE_OBJECTCLASS}
  fi
  if [ -f ${LDIF_FILE} ]; then
    ${LDAPMODIFY} -H "${LDAP_URI}" -D "${LDAP_BINDDN}" -y "${LDAP_BINDDN_PASSWORD_FILE}" -f ${LDIF_FILE} 
    rm -rf ${LDIF_FILE}
  fi
  
  rm -rf ${LDAP_OBJECTCLASS_FILE} ${AD_OBJECTCLASS_FILE}

  unset USER_ACCOUNT AD_OBJECT LDAP_OBJECT LDIF_FILE LDIF_FILE_OBJECTCLASS LDAP_OBJECTCLASS_FILE AD_OBJECTCLASS_FILE
  
}

delete_users ()
{ 
  while read USER_ACCOUNT; do

    LDIF_FILE="${TEMP_DIR}/delete_user_ldap_${USER_ACCOUNT}.ldif"
    USER_DN="$(ldap_search_user_attr ${USER_ACCOUNT} dn)"
    echo "${USER_DN}" > "${LDIF_FILE}"
    echo "changetype: delete" >> "${LDIF_FILE}"
    
    ${LDAPMODIFY} -H "${LDAP_URI}" -D "${LDAP_BINDDN}" -y "${LDAP_BINDDN_PASSWORD_FILE}" -f ${LDIF_FILE}

    rm ${LDIF_FILE}
  done < <(diff ${LDAP_USERS_FILE} ${AD_USERS_FILE} | grep "^<" | awk '{ print $2 }')
 
  while read USER_ACCOUNT; do

    LDIF_FILE="${TEMP_DIR}/delete_user_ad_${USER_ACCOUNT}.ldif"
    USER_DN="$(ad_search_user_attr_by_samaccount ${USER_ACCOUNT} dn)"
    echo "${USER_DN}" > "${LDIF_FILE}"
    echo "changetype: delete" >> "${LDIF_FILE}"
    
    ${LDAPMODIFY} -H "${AD_URI}" -D "${AD_BINDDN}" -y "${AD_BINDDN_PASSWORD_FILE}" -f ${LDIF_FILE}

    rm ${LDIF_FILE}
  done < <(diff ${AD_USERS_FILE} ${LDAP_USERS_FILE} | grep "^<" | awk '{ print $2 }')
}
[root@samba4 lib]# 

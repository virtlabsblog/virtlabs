#!/usr/bin/env bash

#set -x

. /opt/syncldap2ad/lib/users_functions.sh

ldap_generate_new_users_list
ad_generate_new_users_list

while read USER_ACCOUNT; do
  
  if ! $(ldap_search_user "${USER_ACCOUNT}"); then
    echo "$(date +%Y%m%d%H%M): Não foi possível encontrar usuário ${USER_ACCOUNT} na base LDAP"
    continue
  fi
  
  create_user_ldap2ad "${USER_ACCOUNT}"
 
  rm "${TEMP_DIR}/ldap_${USER_ACCOUNT}"
done < <(cat "${LDAP_NEW_USERS_FILE}" | sort -n)

while read USER_ACCOUNT; do
  
  if ! $(ad_search_user "${USER_ACCOUNT}"); then
    echo "$(date +%Y%m%d%H%M): Não foi possível encontrar usuário ${USER_ACCOUNT} no Active Directory"
    continue
  fi

  create_user_ad2ldap "${USER_ACCOUNT}"
  
  rm "${TEMP_DIR}/ad_${USER_ACCOUNT}"
done < <(cat "${AD_NEW_USERS_FILE}" | sort -n )

rm -rf "${LDAP_NEW_USERS_FILE}" "${AD_NEW_USERS_FILE}"

date --utc +%Y%m%d%H%M%S > "${TIMESTAMP_LAST_USERS_CREATE}"

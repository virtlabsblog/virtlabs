#!/usr/bin/env bash

#set -x

. /opt/syncldap2ad/lib/users_functions.sh

ldap_generate_modified_users_list
ad_generate_modified_users_list

while read USER_ACCOUNT; do
  
  if ! $(ldap_search_user "${USER_ACCOUNT}"); then
    echo "$(date +%Y%m%d%H%M): Não foi possível encontrar usuário ${USER_ACCOUNT} na base LDAP"
    continue
  fi
  
  if ! $(ad_search_user "${USER_ACCOUNT}"); then
    echo "$(date +%Y%m%d%H%M): Não foi possível encontrar usuário ${USER_ACCOUNT} no Active Directory"
    continue
  fi

  MODIFY_TIMESTAMP_LDAP=$(grep modifyTimestamp ${TEMP_DIR}/ldap_${USER_ACCOUNT} | awk -F ": " '{ print $2 }' | cut -c1-14)
  MODIFY_TIMESTAMP_AD=$(grep whenChanged ${TEMP_DIR}/ad_${USER_ACCOUNT} | awk -F ": " '{ print $2 }' | cut -c1-14)

  if [ -z "${MODIFY_TIMESTAMP_LDAP}" ]; then
    echo "$(date +%Y%m%d%H%M): Não foi possível determinar o TIMESTAMP da modificação do usuário ${USER_ACCOUNT} na base LDAP, impossível validar alterações"
    continue
  fi

  if [ -z "${MODIFY_TIMESTAMP_AD}" ]; then  
    echo "$(date +%Y%m%d%H%M): Não foi possível determinar o TIMESTAMP da modificação do usuário ${USER_ACCOUNT} no Active Directory, impossível validar alterações"
    continue
  fi

  if [ "${MODIFY_TIMESTAMP_LDAP}" -gt "${MODIFY_TIMESTAMP_AD}" ]; then
    sync_user_ldap2ad ${USER_ACCOUNT}
  elif [ "${MODIFY_TIMESTAMP_AD}" -gt "${MODIFY_TIMESTAMP_LDAP}" ]; then
    sync_user_ad2ldap ${USER_ACCOUNT}
  else
    echo "$(date +%Y%m%d%H%M): TIMESTAMP de modifição do usuário ${USER} é igual no LDAP e no Active Directory, impossível efetuar alterações"
  fi

  rm "${TEMP_DIR}/ldap_${USER_ACCOUNT}" "${TEMP_DIR}/ad_${USER_ACCOUNT}"
done < <(cat "${LDAP_LAST_MODIFIED_USERS_FILE}" "${AD_LAST_MODIFIED_USERS_FILE}" | sort -n | uniq)

rm -rf "${LDAP_LAST_MODIFIED_USERS_FILE}" "${AD_LAST_MODIFIED_USERS_FILE}"

date --utc +%Y%m%d%H%M%S > "${TIMESTAMP_LAST_USERS_SYNC}"

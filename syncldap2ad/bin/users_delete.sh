#!/usr/bin/env bash

#set -x

. /opt/syncldap2ad/lib/users_functions.sh

ldap_generate_users_list
ad_generate_users_list

delete_users

rm -rf "${LDAP_USERS_FILE}" "${AD_USERS_FILE}"

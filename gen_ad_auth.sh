#!/bin/bash

echo "Please enter the windows DNS domain name: "
read DOMAIN
echo "Please enter the Active Directory domain controller DNS name: "
read DC1
echo "Please enter the name of an AD controller in another site: "
read DC2
echo "Please enter the LDAP base DN.  For example, for Brother it would be dc=brotherdc,dc=eu."
echo "Base DN: "
read BASEDN
echo "Please enter the DN of the LDAP bind account: "
read BINDACCTDN
echo "And now the password for that account: "
read BINDACCTPW
echo "Finally, enter the full DN to the AD group which allows sudo access: "
read ADMINGROUP

KBREALM=`echo $DOMAIN | tr [:lower:] [:upper:]`

echo "[*] Installing required authentication packages"
for package in sssd pam_krb5 krb5-libs krb5-workstation openldap-clients
do
  rpm -q ${package} >/dev/null 2>&1
  if [[ $? -ne 0 ]]
  then
    echo "... installing ${package}"
    yum -y install ${package} >/dev/null 2>&1
    if [[ $? -ne 0 ]]
    then
      echo "${package} installation failed"
      exit 1
    fi
  fi
done

echo "[*] Configuring Kerberos, LDAP and SSSD"
authconfig \
--enablekrb5 \
--krb5realm ${KBREALM} \
--krb5kdc ${DC1},${DC2} \
--krb5adminserver ${DC1},${DC2} \
--enablekrb5kdcdns \
--enablekrb5realmdns \
--enablemkhomedir \
--enablesssd \
--enablesssdauth \
--update &> /dev/null

echo "[*] Creating /etc/sssd/sssd.conf"
cat <<EOF> /etc/sssd/sssd.conf
[sssd]
config_file_version = 2
reconnection_retries = 3
sbus_timeout = 30
services = nss, pam
domains = ${KBREALM}

[nss]
filter_groups = root,psupport
filter_users = root,psupport
reconnection_retries = 3
enum_cache_timeout = 300
entry_cache_nowait_percentage = 75

[pam]
reconnection_retries = 3
offline_credentials_expiration = 2
offline_failed_login_attempts = 3
offline_failed_login_delay = 5
pam_verbosity = 2
pam_pwd_expiration_warning = 14

[domain/${KBREALM}]
description = LDAP naming with kerberos auth to $DOMAIN
enumerate = false
# timeout = 30
access_provider = ldap
ldap_access_filter = memberOf=${ADMINGROUP}
# ldap_access_filter = &(objectClass=user)(cn=${ADMINACCTFILTER})
id_provider = ldap
auth_provider = krb5
chpass_provider = krb5
ldap_uri = ldap://${DC1}/, ldap://${DC2}/
ldap_search_base = ${BASEDN}
ldap_default_bind_dn = ${BINDACCTDN}
ldap_default_authtok_type = password
ldap_default_authtok = ${BINDACCTPW}
ldap_id_use_start_tls = False
ldap_tls_cacertdir = /etc/openldap/cacerts
ldap_schema = rfc2307bis
ldap_user_principal = userPrincipalName
ldap_user_fullname = displayName
ldap_user_name = sAMAccountName
ldap_user_object_class = user
ldap_group_object_class = group
ldap_user_home_directory = unixHomeDirectory
ldap_user_shell = loginShell
ldap_force_upper_case_realm = true
ldap_group_uuid = objectGUID
ldap_user_uuid = objectGUID
ldap_user_gid_number = gidNumber
ldap_user_uid_number = uidNumber
krb5_server = ${DC1}, ${DC2}
krb5_realm = ${KBREALM}
krb5_changepw_principle = kadmin/changepw
krb5_ccachedir = /tmp
krb5_ccname_template = FILE:%d/krb5cc_%U_XXXXXX
krb5_auth_timeout = 15
cache_credentials = True
krb5_renewable_lifetime = 36000
krb5_lifetime = 36000

EOF

# echo "[*] Modifying pam_mkhomedir arguments"
# perl -pi -e 's|(.*pam_mkhomedir\.so).*|$1 skel=/etc/skel umask=077|' /etc/pam.d/system-auth*

echo "[*] Restarting services"
service sssd restart
service oddjobd restart
chkconfig sssd on
chkconfig oddjobd on
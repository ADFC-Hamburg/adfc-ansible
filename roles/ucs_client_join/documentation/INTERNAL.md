Entwickelt anhand der Vorlage: https://github.com/univention/univention-domain-join

Domain-Join Output:

```
Created a backup of all configuration files, that will be modified at '/var/univention-backup/20250726054748_domain-join'.
Getting the DN of the Administrator
Updating old LDAP entry for this machine on the UCS DC
Writing /etc/ldap/ldap.conf
Writing /etc/machine.secret
Writing /etc/sssd/sssd.conf
Configuring auth config profile for sssd
Restarting sssd
Writing /usr/share/pam-configs/ucs_mkhomedir
Adding  groups to /usr/share/pam-configs/local_groups
Updating PAM
Writing /etc/krb5.conf
Synchronizing time with the DC
The domain join was successful.
Please reboot the system.
```

Quelle: /usr/lib/python3/dist-packages/univention_domain_join/distributions/ubuntu.py

```
                        if self.force_ucs_dns:
                                userinfo_logger.info('changing network/dns configuration as requested.')
                                DnsConfigurator(self.nameservers, self.domain).configure_dns()
                        # check if we can resolve the ldap_server_name and ldap_master
                        if not name_is_resolvable(self.ldap_master):
                                raise DcResolveException('The UCS master name %s can not be resolved, please check your DNS settings' % self.ldap_master)
                        if not name_is_resolvable(self.ldap_server_name):
                                raise DcResolveException('The UCS DC name %s can not be resolved, please check your DNS settings' % self.ldap_server_name)
                        ldap.authenticate_admin(self.dc_ip, self.admin_username, self.admin_pw)
                        admin_dn = LdapConfigurator().get_admin_dn(self.dc_ip, self.admin_username, self.admin_pw, self.ldap_base)
                        is_samba_dc = ldap.is_samba_dc(self.admin_username, self.admin_pw, self.dc_ip, admin_dn)
                        LdapConfigurator().configure_ldap(self.dc_ip, self.ldap_server_name, self.admin_username, self.admin_pw, self.ldap_base, admin_dn)
                        SssdConfigurator().setup_sssd(self.dc_ip, self.ldap_master, self.ldap_server_name, self.admin_username, self.admin_pw, self.ldap_base, self.kerberos_realm, admin_dn, is_samba_dc)
                        PamConfigurator().setup_pam()
                        if not self.skip_login_manager:
                                LoginManagerConfigurator().enable_login_with_foreign_usernames()
                        KerberosConfigurator().configure_kerberos(self.kerberos_realm, self.ldap_master, self.ldap_server_name, is_samba_dc, self.dc_ip)
                        # TODO: Stop avahi service to prevent problems with sssd?
                        userinfo_logger.info('The domain join was successful.')
                        userinfo_logger.info('Please reboot the system.')
                finally:
                        ldap.cleanup_authentication(self.dc_ip, self.admin_username, self.admin_pw)
```

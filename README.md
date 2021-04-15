# deploy-openldap-on-ocp
Deply Openldap 

## 1. Overview

This procedure deploys a OpenLdap and OpenLdapAdmin too application into OCP.

The YAML files used are:

| File | Meaning | Provide by |
| -------- | ----------- |----------|
|./yaml/local-pv-ldap-template.yaml | create local persitant volumes | niewolik@de.ibm.com |
|./yaml/local-sc-ldap-template.yaml | create local stoarage class | niewolik@de.ibm.com |
|./yaml/openldap-localsc-template.yaml  | create Openldap app and use local storage | niewolik@de.ibm.com |
|./yaml/openldap-template.yaml  | create Openldap app and use storage class provided or default storage | matthias.jung@de.ibm.com |
|./yaml/openldapadmin-template.yaml  | create OpenldapAdmin app | matthias.jung@de.ibm.com |


## 2. Installation

1. If you did not done it already [download](https://github.ibm.com/NIEWOLIK/deploy-openldap-on-ocp/releases/) the latest source code release of this tool.
1. The downloaded archive contains the following files:

        #   ls -l
        total 20
        -rwxrwx---    1 RichardN UsersGrp     15819 Apr 15 13:31 deploy_openldap.sh
        drwxr-x---    1 RichardN UsersGrp         0 Mar 15 14:00 ldif
        drwxr-x---    1 RichardN UsersGrp         0 mar 17 13:22 yaml

                                          
     The `ldif` folder contains a sample LDIF file. This file is modified during install (based on variables set in section 2.) and can imported to the new LDAP server after deployment.
     
     The `yaml` folder contains install yaml templates which will be modfied based on variables. Thus after deploy script ended, you will find new yaml files (without "template" string). Those are the files which actually where used for deployment.
     
1. Transfer archive to your OCP node
1. Untar/unzip the transfered file into a temp directory
1. Execute  [**deploy-openldap.sh**](https://github.ibm.com/NIEWOLIK/deploy-openldap-on-ocp/wiki/deploy-openldap.sh)


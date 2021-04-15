# deploy-openldap-on-ocp
Deply Openldap 

## 1. Overview

This procedure deploys an OpenLdap and OpenLdapAdmin application into OCP.

## 2. Installation

1. If you did not done it already [download](https://github.ibm.com/NIEWOLIK/deploy-openldap-on-ocp/releases/) the latest source code release of this tool.
1. Transfer archive to your OCP node
1. Untar/unzip the transfered file into a temp directory
1. Execute  [**deploy_openldap.sh**](https://github.ibm.com/NIEWOLIK/deploy-openldap-on-ocp/blob/master/openldap/deploy_openldap.sh)

## 3. Content

The downloaded archive contains the following files:

```
# ls -lR
    deploy_openldap_V2.sh
    ldif
    yaml
    
  ./ldif:
    openldap_sample_template.ldif
         
   ./yaml:
     local-pv-ldap-template.yaml
     local-sc-ldap-template.yaml
     openldap-localsc-template.yaml
     openldap-template.yaml
     openldapadmin-template.yaml
```
                                          
1.  [deploy_openldap.sh](https://github.ibm.com/NIEWOLIK/deploy-openldap-on-ocp/blob/master/openldap/deploy_openldap.sh) is the Openldap deploy procedure
1. The `ldif` folder contains a [sample LDIF file](https://github.ibm.com/niewolik/deploy-openldap-on-ocp/wiki/sample-ldif). This file is modified during install (based on variables set, see section 2. in [deploy-openldap.sh](https://github.ibm.com/NIEWOLIK/deploy-openldap-on-ocp/wiki/deploy-openldap.sh) ) and can imported to the new LDAP server after deployment.
     
 1. The `yaml` folder contains install yaml templates which will be modfied based on variables. Thus, after deploy script ended, you will find new yaml files (without "template" string). Those are the files which actually where used for deployment.

    | File | Meaning | Provide by |
    | -------- | ----------- |----------|
    |./yaml/local-pv-ldap-template.yaml | create local persitant volumes | niewolik@de.ibm.com |
    |./yaml/local-sc-ldap-template.yaml | create local stoarage class | niewolik@de.ibm.com |
    |./yaml/openldap-localsc-template.yaml  | create Openldap app and use local storage | niewolik@de.ibm.com |
    |./yaml/openldap-template.yaml  | create Openldap app and use storage class provided or default storage | matthias.jung@de.ibm.com |
    |./yaml/openldapadmin-template.yaml  | create OpenldapAdmin app | matthias.jung@de.ibm.com |

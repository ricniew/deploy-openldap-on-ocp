# deploy-openldap-on-ocp


## 1. Overview

This procedure deploys an OpenLdap and OpenLdapadmin tool (phpLDAPadmin) application into OCP.
Doc: 
- [OpenLDAP Software 2.4 Administrator's Guide](https://www.openldap.org/doc/admin24/guide.html)
- [Main Page phpLDAPadmin](http://phpldapadmin.sourceforge.net/wiki/index.php/Main_Page)


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
1. The `ldif` folder contains a [sample LDIF file](https://github.ibm.com/niewolik/deploy-openldap-on-ocp/wiki/sample-ldif) (openldap_sample_template.ldif). This file is modified during install (based on variables set, see section 2. in [deploy-openldap.sh](https://github.ibm.com/NIEWOLIK/deploy-openldap-on-ocp/wiki/deploy-openldap.sh) ) and new file name is created **openldap_sample.ldif** . The new file can then be imported to the new LDAP server after deployment.
 1. The `yaml` folder contains install yaml templates which will be modfied based on variables in [deploy-openldap.sh]( https://github.ibm.com/NIEWOLIK/deploy-openldap-on-ocp/wiki/deploy-openldap.sh). 
 
    | File | Meaning | Provide by |
    | -------- | ----------- |----------|
    |local-pv-ldap-template.yaml | create local persitant volumes | niewolik@de.ibm.com |
    |local-sc-ldap-template.yaml | create local stoarage class | niewolik@de.ibm.com |
    |openldap-localsc-template.yaml  | create Openldap app and use local storage | niewolik@de.ibm.com |
    |openldap-template.yaml  | create Openldap app and use storage class <BR> provided or default storage | matthias.jung@de.ibm.com |
    |openldapadmin-template.yaml  | create OpenldapAdmin app | matthias.jung@de.ibm.com |
 
     Thus, after deploy script ended, you will find new yaml files (without "template" string). Those are the files which actually were used for deployment. There will be also one new yaml file, which is used to modify the automatically generated nodeport (via _oc expose ... --nodeport ..._).
 
    | Before | After |
    | ------ | ----- |
    | local-pv-ldap-template.yaml | local-pv-ldap-0.yaml |
    | local-sc-ldap-template.yaml | local-sc-ldap.yaml  | 
    | openldap-localsc-template.yaml | openldap.yaml (used for local storage class) |
    | openldap-template.yaml | openldap.yaml (used for specific and default storage class) |
    | openldapadmin-template.yaml | openldapadmin.yaml |
    | n/a | openldap-svc-nodeport.yaml |
    

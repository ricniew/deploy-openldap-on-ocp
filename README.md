# deploy-openldap-on-ocp
Deply Openldap 

## 1. Overview

This procedure deploys a OpenLdap application into OCP.

The YAML files used are:

| File | Meaning | Provide by |
| -------- | ----------- |----------|
|./yaml/local-pv-ldap-template.yaml | create local persitant volumes | niewolik@de.ibm.com |
|./yaml/local-sc-ldap-template.yaml | create local stoarage class | niewolik@de.ibm.com |
|./yaml/openldap-localsc-template.yaml  | create Openldap app and use local storage | niewolik@de.ibm.com |
|./yaml/openldap-template.yaml  | create Openldap app and use storage class provided | matthias.jung@de.ibm.com |
|./yaml/openldapadmin-template.yaml  | create OpenldapAdmin app | matthias.jung@de.ibm.com |


## 2. Variables used

| File | Default | Meaning |
| ------ | --------- | -------- | 
| ADMIN_PASSWORD | passw0rd | Ldap admin password  | 
| OPENLDAP_NS | openldap | OCP namespace where LDAP will be installed | 
| BASE_DN | "dc=example,dc=com" | LDAP Base DN | 
| DOMAIN | example.com | LDAp domain  | 
| ORGANISATION | EXAMPLE.COM | LDAP organization name | 
| OPENLDAP_VER |  1.3.0 | Openldap version | 
| LOCAL_SC_NAME| local-openldap |  local storage class name if used  |  
| OPENLDAP_ADMIN | yes| If "yes" OpendldapAdmin tool will be installed  |  


## 3. Installation

1. If you did not done it already [download](https://github.ibm.com/NIEWOLIK/deploy-openldap-on-ocp/releases/) the latest source code release of this tool.
1. The downloaded archive contains the following files:

        #   ls -l
        total 20
        -rwxrwx---    1 RichardN UsersGrp     14239 Mar 15 14:02 deploy_openldap.sh
        -rwxrwx---    1 RichardN UsersGrp     15819 Mar 23 12:29 deploy_openldap_V2.sh
        drwxr-x---    1 RichardN UsersGrp         0 Mar 15 14:00 ldif
        drwxr-x---    1 RichardN UsersGrp         0 Mar 17 13:22 yaml

                                          
     The `ldif` afolder contains a sample ldif fill which can imported to teh new LDAP server after installation
     
     The `yaml` a folder contains install yaml templates which will be modfied based on variables. Thus after deploy script ended, you will find new yaml files (without "template" string). Those are the files which actully where used for deplyoment.
     
1. Transfer archive to your OCP node
1. Untar/unzip the transfered file into a temp directory

## 4. Execution

Change to the `openldap` folder and run the script

        # cd openldap
        # ./deploy_openldap.sh


## 5. Sample Run
```
[root@norway-inf openldap]# ./deploy_openldap_V2.sh
INFO: Procedure started
#---------------
Provide storage class you want use "localsc" or your existing none local storage class name (e.g. rook-cephfs)
If "localsc" is used, a local storage class "local-openldap", persistant volumes and folders in one worker node (worker0) will be created
> localsc
#---------------
Provide pull secretname you want to use to download Openldap image from docker.io
> pull-secret
INFO: (get_param) Pull secret "pull-secret" exists. OK
openshift-config                                   pull-secret                                                kubernetes.io/dockerconfigjson        1      4d4h
INFO: Create project: openldap.
WARNING: OPENLDAP appears to be installed. Namespace "openldap" exists already.
# oc create serviceaccount openldap
serviceaccount/openldap created
INFO: (wait_for_cmd_to_return_true) Executing:
# oc get serviceaccount openldap .
NAME       SECRETS   AGE
openldap   2         3s
INFO: (wait_for_cmd_to_return_true) Command returned true. Elapsed time: 0 min 0 sec (2 seconds).
# oc adm policy add-scc-to-user anyuid -z openldap
clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "openldap"
INFO: (deploy_openldap) Deploy Openldap.
INFO: (create_local_sc) Create local storage class for Openldap.
INFO: (apply_yaml) Apply command:
# oc apply -f ./yaml/local-sc-ldap.yaml -n openldap
storageclass.storage.k8s.io/local-openldap unchanged
INFO: (apply_yaml) Apply Successfully executed
INFO: (wait_for_cmd_to_return_true) Executing:
# oc get sc -n local-openldap .
NAME             PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-openldap   kubernetes.io/no-provisioner   Delete          WaitForFirstConsumer   false                  23h
INFO: (wait_for_cmd_to_return_true) Command returned true. Elapsed time: 0 min 0 sec (2 seconds).
INFO: (create_local_pv) Create local persistant vulumes for Openldap.
INFO: (create_local_pv) Get worker nodes
INFO: (create_local_pv) WORKER0=worker0.norway.cp.fyre.ibm.com
INFO: (create_local_pv) WORKER1=worker1.norway.cp.fyre.ibm.com
INFO: (create_local_pv) WORKER2=worker2.norway.cp.fyre.ibm.com
# ssh core@worker0.norway.cp.fyre.ibm.com mkdir -p "/var/home/core/local-storage/local-openldap-0"
INFO: (apply_yaml) Apply command:
# oc apply -f ./yaml/local-pv-ldap-0.yaml -n openldap
persistentvolume/openldap-data created
persistentvolume/openldap-config created
persistentvolume/openldap-certs created
INFO: (apply_yaml) Apply Successfully executed
INFO: (wait_for_cmd_to_return_true) Executing:
# oc get pv openldap-certs -n openldap .
NAME             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS     REASON   AGE
openldap-certs   100Gi      RWO            Retain           Available           local-openldap            6s
INFO: (wait_for_cmd_to_return_true) Command returned true. Elapsed time: 0 min 0 sec (2 seconds).
INFO: (wait_for_cmd_to_return_true) Executing:
# oc get pv openldap-config  -n openldap .
NAME              CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS     REASON   AGE
openldap-config   100Gi      RWO            Retain           Available           local-openldap            9s
INFO: (wait_for_cmd_to_return_true) Command returned true. Elapsed time: 0 min 0 sec (2 seconds).
INFO: (wait_for_cmd_to_return_true) Executing:
# oc get pv openldap-data -n openldap .
NAME            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS     REASON   AGE
openldap-data   20Gi       RWO            Retain           Available           local-openldap            12s
INFO: (wait_for_cmd_to_return_true) Command returned true. Elapsed time: 0 min 0 sec (2 seconds).
INFO: (apply_yaml) Apply command:
# oc apply -f ./yaml/openldap.yaml -n openldap
configmap/openldap created
persistentvolumeclaim/openldap-data created
persistentvolumeclaim/openldap-config created
persistentvolumeclaim/openldap-certs created
deployment.apps/openldap created
service/openldap created
INFO: (apply_yaml) Apply Successfully executed
INFO: (wait_for_cmd_to_return_true) Executing:
# oc get configmap openldap -n openldap .
NAME       DATA   AGE
openldap   4      6s
INFO: (wait_for_cmd_to_return_true) Command returned true. Elapsed time: 0 min 0 sec (2 seconds).
INFO: (check_wait_for_specific_pods_running) Waiting until pod(s) are started (=Running).
# oc get pods -n openldap | grep -E "openldap-"| grep Running
.
INFO: (check_wait_for_specific_pods_running) Pod(s) is(are) running. Elapsed time: 0 min 1 sec (1 seconds)
INFO: (deploy_openldap) Openldap application deployed successfully
INFO: (expose_openldap_ingress) Exposing Openldap deployment via NodePort
# oc expose deployment/openldap --type=NodePort --name=openldap-ingress
WARNING: (expose_openldap_ingress) Service "openldap-ingress\2 exists already.
INFO: (deploy_openldap_admin) Deploy Openldap admin tool.
INFO: (apply_yaml) Apply command:
# oc apply -f ./yaml/openldapadmin.yaml -n openldap
deployment.apps/openldapadmin created
service/openldapadmin created
route.route.openshift.io/openldapadmin created
INFO: (apply_yaml) Apply Successfully executed
INFO: (wait_for_cmd_to_return_true) Executing:
# oc get route openldapadmin -n openldap .
NAME            HOST/PORT                                            PATH   SERVICES        PORT    TERMINATION   WILDCARD
openldapadmin   openldapadmin-openldap.apps.norway.cp.fyre.ibm.com          openldapadmin   https   passthrough   None
INFO: (wait_for_cmd_to_return_true) Command returned true. Elapsed time: 0 min 0 sec (2 seconds).
INFO: (check_wait_for_specific_pods_running) Waiting until pod(s) are started (=Running).
# oc get pods -n openldap | grep -E "openldapadmin"| grep Running
...
INFO: (check_wait_for_specific_pods_running) Pod(s) is(are) running. Elapsed time: 0 min 5 sec (5 seconds)
INFO: Openldap Admin application deployed successfully
INFO: (modify_sample_ldiff) Sample LDIF file is: ./ldif/openldap_sample.ldif
# -------------------------------------------------------------------#
# USEFULL INFORMATIONS (saved in "comments-openldap")
# -------------------------------------------------------------------#
OPENLDAP_ADMIN_Console is: https://openldapadmin-openldap.apps.norway.cp.fyre.ibm.com
# --- Openldap login credentials:
OPENLDAP login DN: cn=admin,dc=example,dc=com
OPENLDAP login password: passw0rd
# -------------------------------------------------------------------#
# --- Import sammple groups and users:
oc -n openldap cp ./ldif/openldap_sample.ldif openldap-6cc78f6fb-tlkc7:/tmp/sample.ldif
oc -n openldap rsh openldap-6cc78f6fb-tlkc7 ldapadd -D "cn=admin,dc=example,dc=com" -w passw0rd -f /tmp/sample.ldif
-- Examples ldap commands:
- list group
oc -n openldap rsh openldap-6cc78f6fb-tlkc7 ldapsearch -LLL -x -H ldap:// -D "cn=admin,dc=example,dc=com" -w passw0rd -b "dc=example,dc=com" "(memberOf=cn=support,ou=groups,dc=example,dc=com)" dn | grep dn
- list objects and limit output to 10 rows
oc -n openldap rsh openldap-6cc78f6fb-tlkc7 ldapsearch -LLL -x -H ldap://worker0.norway.cp.fyre.ibm.com:30389 -D "cn=admin,dc=example,dc=com" -w passw0rd -b "dc=example,dc=com" "objectclass=*" 1.1 -z 10
- Change users password
oc -n openldap rsh openldap-6cc78f6fb-tlkc7 ldappasswd -D "cn=admin,dc=example,dc=com" -w passw0rd -s welcome123  -x "uid=richard,ou=users,dc=example,dc=com"
# -------------------------------------------------------------------#
# --- To delete the deployed Openldap please do following:
oc delete -f ./yaml/openldap.yaml -n openldap # del openldap resources defined by yaml
oc get pv|grep openldap # delete all pv based on output
ssh core@worker0.norway.cp.fyre.ibm.com sudo 'rm -fr /var/home/core/local-storage/local-openldap-0' # del pv folder
oc delete sa openldap -n openldap # delete service account
oc delete -f ./yaml/openldapadmin.yaml -n openldap # To delete OPENLDAP ADMIN isssue (if installed)
oc delete project openldap # To delete the entire project
# -------------------------------------------------------------------#
INFO: Procedure end
[root@norway-inf openldap]#
```

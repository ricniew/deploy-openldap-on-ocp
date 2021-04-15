#!/bin/bash

# This procedure deploys a OpenLdap application into OCP 
#
# Author: Richard Niewolik IBM AVP Team EMEA (niewolik@de.ibm.com)
#  YAML content have been provided by Mathias Jung (matthias.jung@de.ibm.com)
# ---------------------------------------------------------------------
OPENLDAP_NS=openldap
ADMIN_PASSWORD=passw0rd # ldap admin pw
BASE_DN="dc=example,dc=com"
DOMAIN=example.com
ORGANISATION=EXAMPLE.COM
OPENLDAP_VER=1.5.0
OPENLDAP_ADMIN=yes
# STORAGE_CLASS 
# = automatic : will check for a default sc, if not exisisting local storage will be used. 
# = localsc  : will create local sc wiht the name set in LOCAL_SC_NAME  (default is local-openldap)
# If you will use a specifc existing none default sc, set the name here. For example STORAGE_CLASS=rook-cephs
STORAGE_CLASS=automatic
LOCAL_SC_NAME=local-openldap   # created and used when no default storage class exists
# PULL_SECRET
# prompt: will ask you for the secret name. 
# if you do not want to be prompted, set the name here. For example PULL_SECRET=pull-secret
PULL_SECRET=pull-secret # normally OCP default and found in "default" namespace
#
mydatetime=$(date +"%Y-%m-%d_%H%M%S")
LOGFILE=${mydatetime}.deploy-openldap.log
# ------------------
# --- Functions ---
# ------------------
check_param()
{

if [ "$STORAGE_CLASS" == "automatic" ] ; then 
    oc get sc | grep "\(default\)" &>/dev/null
    if [ $? -eq 0 ] ; then # use default sc 
        STORAGE_CLASS=`oc get sc | grep default| awk '{print $1}'`
    else # use local sc
        STORAGE_CLASS=localsc
    fi
elif [ "$STORAGE_CLASS" == "localsc" ] ; then # local storage will be created and used
    STORAGE_CLASS=$STORAGE_CLASS
else # specific sc was set
    oc get sc | grep $STORAGE_CLASS &>/dev/null
    if [ $? -ne 0 ] ; then
        echo "ERROR: (${FUNCNAME[0]}) STORAGE_CLASS=${STORAGE_CLASS} does not exists. Check value!"
        exit 1
    fi
fi
echo "INFO: (${FUNCNAME[0]}) STORAGE_CLASS=${STORAGE_CLASS}"
    
oc get secret  --all-namespaces | grep " ${PULL_SECRET} " &>/dev/null
if [ $? -eq 1 ] ; then
    echo  "ERROR: (${FUNCNAME[0]}) Pull secret \"${PULL_SECRET}\" does NOT exists. Provide an existing secret name."
    exit 1
else
    oc get secret --all-namespaces | grep " ${PULL_SECRET} "
    echo  "INFO: (${FUNCNAME[0]}) PULL_SECRET=${PULL_SECRET} "
fi

return 0
}

function log()
{
if [ "$1" == "-n" ] ; then
    echo -n "$2"
    echo -n "$2" >> $LOGFILE
elif [ "$1" == "only" ] ; then
    echo "$2" >> $LOGFILE
else 
    echo "$@"
    echo "$@" >> $LOGFILE
fi
return 0
}
 
function apply_yaml()
{
yaml=$1
ns=$2
log "INFO: (${FUNCNAME[0]}) Apply command:"
if [ ! $ns ] ; then
    log "# oc apply -f $yaml"
    oc apply -f $yaml
else
    log "# oc apply -f $yaml -n $ns"
    oc apply -f $yaml -n $ns
fi
if [ $? -eq 0 ] ; then
    log "INFO: (${FUNCNAME[0]}) Apply Successfully executed"
    sleep 3s
else
    if [ ! $ns ] ; then 
        log "ERROR: (${FUNCNAME[0]}) Applying \"oc apply -f $yaml\" failed."
    else
        log "ERROR: (${FUNCNAME[0]}) Applying \"oc apply -f $yaml -n $ns\" failed."
    fi
    log "ERROR: (${FUNCNAME[0]}) Check and restart install procedure"
    exit 1
fi
return 0
}

function wait_for_cmd_to_return_true()
{
log "INFO: (${FUNCNAME[0]}) Executing: "
log -n "# $1 "
command=$1
sec=0
tsec=0
minutes=0
timeout=3600 # in sec
ok=1
while [ $ok -eq 1 ]
do
    log -n .
    sleep 2s
    sec=$((sec+2))
    eval $command  &>/dev/null
    if [ $? -eq 0 ]; then # resource available
        log " " 
        eval $command
        ok=0
    else
        sleep 2s
        sec=$((sec+2))
	      tsec=$((tsec+2))
        if (( tsec > 60 )); then
            minutes=$((minutes+1))
            log -n "$minutes m" 
            tsec=0
        fi
        if (( sec > timeout )); then
            log " "
            log "WARNING: (${FUNCNAME[0]}) $timeout seconds have passed and \"$command\" did not return true (0)"
            log "WARNING: (${FUNCNAME[0]}) Canceling waiting loop"
            break
        fi       
    fi
done
if [ $ok -eq 0  ]
then
    log "INFO: (${FUNCNAME[0]}) Command returned true. Elapsed time: $minutes min $tsec sec ($sec seconds)."
else
    exit 1
fi

return 0
}

function check_wait_for_specific_pods_running()
{
pods=$1 # pod name(s)
ns=$2 # namespace
oc get projects|grep "^$ns " &>/dev/null
if [ $? -eq 1 ] ; then
   log "WARNING: (${FUNCNAME[0]}) Namespace $ns does not exists. No check performed"
   return 0
fi
log "INFO: (${FUNCNAME[0]}) Waiting until pod(s) are started (=Running)."
log "# oc get pods -n $ns | grep -E \"$pods\"| grep Running "
timeout=3600 # (seconds)
sec=1
tsec=1
minutes=0
ok=1
tmp=`echo $1| sed 's/|/ /g'`
read -a array <<< $tmp
ac=${#array[@]}
while [ $sec -le $timeout ]
do
    sleep 2s 
    log -n .
    c=`oc get pods -n $ns 2>/dev/null | grep -E "$pods"| grep Running | wc -l`
    if (( c == ac )) ; then
        ok=0
        break
    elif (( tsec > 60 )) ; then
        minutes=$(( minutes + 1))
        log -n "$minutes m" 
        tsec=0
    fi
    sec=$(( $sec + 2 ))
    tsec=$(( $tsec + 2 ))
done
log " "
if [ $ok -eq 1 ] ; then
    log "ERROR: (${FUNCNAME[0]}) Configured wait timeout of $timeout seconds ($minutes min) occured."
    log "ERROR: (${FUNCNAME[0]}) Pod(s) \"$1\""
    log "ERROR: (${FUNCNAME[0]}) in namespace \"$ns\" did not start yet (status not equal \"Running\")."
    log "ERROR: (${FUNCNAME[0]}) $ac pod(s) should run but $c started yet!"
    log "ERROR: (${FUNCNAME[0]}) Please check (e.g. oc -n $ns get events --field-selector type=Warning --sort-by='{.lastTimestamp}') and restart the install.sh procedure"
    oc get pods -n $ns| grep -E "$pods"
else
    log "INFO: (${FUNCNAME[0]}) Pod(s) is(are) running. Elapsed time: $minutes min $tsec sec ($sec seconds)"
fi 
}

function create_local_pv()
{
log "INFO: (${FUNCNAME[0]}) Create local persistant vulumes for Openldap."
log "INFO: (${FUNCNAME[0]}) Get worker nodes"
for w in `oc get nodes|grep " worker "| awk '{print $1}'`; do 
    wtmp=`echo $w|cut -d'.' -f1` 
    wtmp=${wtmp^^} 
    log  "INFO: (${FUNCNAME[0]}) $wtmp=$w"
    export ${wtmp}=$w 
done
nodes=("${WORKER0}") # only one one worker pv and folder is created by default. Not high available. Set nodes=("${WORKER0}", "${WORKER1}, ...", ) for HA 
username=core # Standard username on openshift environments
base_dir='/var/home/core/local-storage' # Location where persistent volume data will be stored
max_size='20Gi' # Maximum size for any persistent volume (only affects which persistent volume claims are bound, not actual disk usage).
counter=0
pv_yaml_template=./yaml/local-pv-ldap-template.yaml
for node in "${nodes[@]}"; do
    log "# ssh ${username}@${node} mkdir -p \"${base_dir}/${LOCAL_SC_NAME}-${counter}\""
    ssh ${username}@${node} mkdir -p "${base_dir}/${LOCAL_SC_NAME}-${counter}/config"
    ssh ${username}@${node} mkdir -p "${base_dir}/${LOCAL_SC_NAME}-${counter}/certs"
    ssh ${username}@${node} mkdir -p "${base_dir}/${LOCAL_SC_NAME}-${counter}/data"
    pv_yaml=./yaml/local-pv-ldap-${counter}.yaml
    cat  $pv_yaml_template |\
    sed "s/<MAX_SIZE>/${max_size}/" |\
    sed "s|<PATH>|${base_dir}/${LOCAL_SC_NAME}-${counter}|" |\
    sed "s/<WORKER_NODE>/$node/" |\
    sed "s/<SC_NAME>/${LOCAL_SC_NAME}/" \
    > $pv_yaml
    apply_yaml  $pv_yaml ${OPENLDAP_NS}
    counter=$((counter+1))
done

wait_for_cmd_to_return_true "oc get pv openldap-certs -n ${OPENLDAP_NS}"
wait_for_cmd_to_return_true "oc get pv openldap-config  -n ${OPENLDAP_NS}"
wait_for_cmd_to_return_true "oc get pv openldap-data -n ${OPENLDAP_NS}"
    
return 0 
}

function create_local_sc()
{
log "INFO: (${FUNCNAME[0]}) Create local storage class for Openldap."
sc_yaml=./yaml/local-sc-ldap.yaml
sc_yaml_template=./yaml/local-sc-ldap-template.yaml

cat  $sc_yaml_template |\
sed "s/<LOCAL_SC>/${LOCAL_SC_NAME}/" \
> $sc_yaml
apply_yaml $sc_yaml ${OPENLDAP_NS}
wait_for_cmd_to_return_true "oc get sc -n ${LOCAL_SC_NAME}"
    
return 0 
}

function deploy_openldap()
{
log "INFO: (${FUNCNAME[0]}) Deploy Openldap."
ldap_yaml=./yaml/openldap.yaml

if [ "$STORAGE_CLASS" == "localsc" ] ; then
    create_local_sc
    create_local_pv
    ldap_yaml_template=./yaml/openldap-localsc-template.yaml
    sc_name=$LOCAL_SC_NAME
else
    ldap_yaml_template=./yaml/openldap-template.yaml
    sc_name=$STORAGE_CLASS
fi
cat  $ldap_yaml_template |\
sed "s/<ADMIN_PASSWORD>/${ADMIN_PASSWORD}/" |\
sed "s/<BASE_DN>/${BASE_DN}/" |\
sed "s/<DOMAIN>/${DOMAIN}/" |\
sed "s/<ORGANISATION>/${ORGANISATION}/" |\
sed "s/<SC_NAME>/${sc_name}/" |\
sed "s/<PULL_SECRET>/${PULL_SECRET}/" |\
sed "s/<OPENLDAP_VER>/${OPENLDAP_VER}/" \
> $ldap_yaml
apply_yaml $ldap_yaml "${OPENLDAP_NS}" 
# check resouces and pod
wait_for_cmd_to_return_true "oc get configmap openldap -n ${OPENLDAP_NS}"
POD="openldap-"
check_wait_for_specific_pods_running $POD "${OPENLDAP_NS}" 
log "INFO: (${FUNCNAME[0]}) Openldap application deployed successfully"

return 0 
}

function expose_openldap_nodeport()
{
log "INFO: (${FUNCNAME[0]}) Exposing Openldap deployment via NodePort"
echo "# oc expose deployment/openldap --type=NodePort --name=openldap-nodeport"
oc get service openldap-nodeport -n ${OPENLDAP_NS} &>/dev/null
if [ $? -eq 0 ] ; then
    log "WARNING: (${FUNCNAME[0]}) Service \"openldap-nodeport\2 exists already."
    return 0
fi

oc expose deployment/openldap --type=NodePort --name=openldap-nodeport
if [ $? -ne 0 ] ; then
   RC=1
   log "WARNING: (${FUNCNAME[0]}) Exposing Openldap deployment via NodePort failed"
   log "WARNING: (${FUNCNAME[0]}) You will not be able to access the Openldap server outside of the pod"
   return 1
else
   log "INFO: (${FUNCNAME[0]}) Successfully exposed Openldap deployment via NodePort"
fi

log "INFO: (${FUNCNAME[0]}) Changing exposed NodePorts to 30389 and 30636"
svc_yaml_temp=.openldap-nodeport-temp.yaml
svc_yaml=openldap-svc-nodeport.yaml
oc get svc openldap-nodeport -o yaml > $svc_yaml_temp
sed -r 's/(^.*nodePort:)(.*$)/\1 xxxxxx/'  $svc_yaml_temp > $svc_yaml
sed -r '0,/nodePort: xxxxxx/s//nodePort: 30389/' $svc_yaml > $svc_yaml_temp
sed -r '0,/nodePort: xxxxxx/s//nodePort: 30636/' $svc_yaml_temp > $svc_yaml
mv $svc_yaml ./yaml/$svc_yaml
oc replace -f ./yaml/$svc_yaml "${OPENLDAP_NS}" 
if [ $? -ne 0 ] ; then
   RC=1
   log "WARNING: (${FUNCNAME[0]}) Changing exposed NodePorts to 30389 and 30636 failed"
   log "WARNING: (${FUNCNAME[0]}) Verify using \"oc edit svc openldap-nodeport\" "
else
   log "INFO: (${FUNCNAME[0]}) Successfully changed Node ports"
   host=`oc get nodes| grep ${WORKER0}| awk '{print $1}'`
   log "INFO: (${FUNCNAME[0]}) To access outsite of the pod use e.g: ldap://$host:30389"
fi
   
return 0
}

function deploy_openldap_admin()
{
log "INFO: (${FUNCNAME[0]}) Deploy Openldap admin tool."
openldapadmin_yaml=./yaml/openldapadmin.yaml
openldapadmin_template_yaml=./yaml/openldapadmin-template.yaml

cat  $openldapadmin_template_yaml |\
sed "s/<PULL_SECRET>/${PULL_SECRET}/" \
> $openldapadmin_yaml
apply_yaml $openldapadmin_yaml  "${OPENLDAP_NS}" 

wait_for_cmd_to_return_true "oc get route openldapadmin -n ${OPENLDAP_NS}"
POD="openldapadmin"
check_wait_for_specific_pods_running $POD "${OPENLDAP_NS}" 

return 0
}

function modify_sample_ldiff()
{
LDIFFSAMPLE="./ldif/openldap_sample.ldif"
ldiffsampletemplate=./ldif/openldap_sample_template.ldif
cat $ldiffsampletemplate | sed "s/\[BASE-DN\]/${BASE_DN}/" > $LDIFFSAMPLE
log "INFO: (${FUNCNAME[0]}) Sample LDIF file is: $LDIFFSAMPLE"
}


function post_process()
{
COMMENTS_FILE=comments-openldap
log "# -------------------------------------------------------------------#" 
log "# USEFULL INFORMATIONS (saved in \"$COMMENTS_FILE\")"   

if [ "${OPENLDAP_ADMIN}" == "yes" ] ; then
ldapadm_console=`oc get routes openldapadmin -n ${OPENLDAP_NS} -o jsonpath={.spec.host}`
{
    echo "# -------------------------------------------------------------------#" 
    echo "OPENLDAP_ADMIN_Console is: https://$ldapadm_console"
    echo "OPENLDAP LDAP URL: ldap://openldap.openldap:389       # Should be used inside an OCP cluster"
    echo "OPENLDAP LDAP NodePort URL: ldap://${WORKER0}:30389   # e.g. only if ldapsearch command is used outside of a cluster pods"       
    echo "# --- Openldap login credentials:"
    echo "OPENLDAP Base DN: ${BASE_DN}"
    echo "OPENLDAP login DN: cn=admin,${BASE_DN}"
    echo "OPENLDAP login password: ${ADMIN_PASSWORD}"
} > $COMMENTS_FILE
fi
{
pod=`oc get pod -l app=openldap -o jsonpath="{.items[0].metadata.name}" -n ${OPENLDAP_NS}`
echo "# -------------------------------------------------------------------#" 
echo "#--- Import sammple groups and users:"
echo "oc -n ${OPENLDAP_NS} cp ${LDIFFSAMPLE} $pod:/tmp/sample.ldif"
echo "oc -n ${OPENLDAP_NS} rsh $pod ldapadd -D \"cn=admin,${BASE_DN}\" -w passw0rd -f /tmp/sample.ldif"
echo "#-- Examples ldap commands:"
echo "#- list group"
echo "oc -n ${OPENLDAP_NS} rsh $pod ldapsearch -LLL -x -H ldap:// -D \"cn=admin,${BASE_DN}\" -w passw0rd -b \"${BASE_DN}\" \"(memberOf=cn=support,ou=groups,${BASE_DN})\" dn | grep dn"
echo "#- list objects and limit output to 10 rows"
echo "oc -n ${OPENLDAP_NS} rsh $pod ldapsearch -LLL -x -H ldap://${WORKER0}:30389 -D \"cn=admin,dc=example,dc=com\" -w passw0rd -b \"dc=example,dc=com\" \"objectclass=*\" 1.1 -z 10"
echo "#- Change users password"
echo "oc -n ${OPENLDAP_NS} rsh $pod ldappasswd -D \"cn=admin,${BASE_DN}\" -w passw0rd -s welcome123  -x \"uid=richard,ou=users,${BASE_DN}\""
echo "# -------------------------------------------------------------------#" 
echo "# --- To delete the deployed Openldap please do following:"
echo "oc delete -f ${ldap_yaml} -n ${OPENLDAP_NS} # del openldap resources defined by yaml"
echo "oc get pv|grep openldap # delete all listed Openldap persistent volumes"
echo "oc delete sa openldap -n ${OPENLDAP_NS} # delete service account"
echo "oc delete -f ${openldapadmin_yaml} -n ${OPENLDAP_NS} # To delete OPENLDAP ADMIN isssue (if installed)"
if [  "$STORAGE_CLASS" == "localsc" ] ; then
    echo "ssh core@${WORKER0} sudo 'rm -fr /var/home/core/local-storage/local-openldap-0' # del pv folder if local storage was used"
fi
echo "oc delete project ${OPENLDAP_NS} # To delete the entire project "
echo "# -------------------------------------------------------------------#" 
} >> $COMMENTS_FILE

cat $COMMENTS_FILE

}
# --- End Functions -----

#====================
#        MAIN
#====================
log "INFO: Procedure started"
log "INFO: Version 1.0"
RC=0
check_param

log "INFO: Create project: $OPENLDAP_NS."
oc project ${OPENLDAP_NS} &>/dev/null
if [ $? -eq 0 ] ; then
    log "WARNING: OPENLDAP appears to be installed. Namespace \"${OPENLDAP_NS}\" exists already."
    sleep 5
else
    log "# oc new-project ${OPENLDAP_NS}"
    oc new-project ${OPENLDAP_NS}
    if [ $? -eq 1 ] ; then
        log "ERROR: Project/Namespace \"${OPENLDAP_NS}\" cannot be created (oc new-project ...)."
        exit 1
    fi
fi

# Create Service Account and assing ANYUID to it
oc get serviceaccount openldap &>/dev/null
if [ $? -eq 0 ] ; then
    log "WARNING: serviceaccount \"${OPENLDAP_NS}\" exists already."
else
     log "# oc create serviceaccount openldap"
     oc create serviceaccount openldap
     if [ $? -eq 1 ] ; then
         log "ERROR: Command oc create serviceaccount \"${OPENLDAP_NS}\" failed."
         exit 1
     else
         wait_for_cmd_to_return_true "oc get serviceaccount openldap"
     fi
fi
log "# oc adm policy add-scc-to-user anyuid -z ${OPENLDAP_NS}"
oc adm policy add-scc-to-user anyuid -z ${OPENLDAP_NS}
if [ $? -eq 1 ] ; then
    log "ERROR: Command \"oc adm policy add-scc-to-user anyuid -z ${OPENLDAP_NS}\" failed."
fi

deploy_openldap # Deploy Openldap into namespace ${OPENLDAP_NS}
expose_openldap_nodeport # Expose Openldap deployment so you can access it outside of the pod

if [ "${OPENLDAP_ADMIN}" == "yes" ] ; then
    deploy_openldap_admin # Install Openldap admin appliaction into namespace ${OPENLDAP_NS}
    log "INFO: Openldap Admin application deployed successfully"
fi
modify_sample_ldiff # modify sample ldif to match the paramters used
post_process

if [ $RC -ne 0 ] ; then 
    log "ERROR: You have encountered Warnings which may cause some missing functionality. Please check warnings check."
fi
log "INFO: Procedure end"
oc project default &>/dev/null
exit 0

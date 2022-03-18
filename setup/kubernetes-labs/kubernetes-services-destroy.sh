#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings


COMPARTMENT_NAME=CTDOKE

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings"
    source $SETTINGS
  else 
    echo "No existing settings, cannot continue"
    exit 10
fi

if [ -z "$AUTO_CONFIRM" ]
then
  AUTO_CONFIRM=n
fi

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

OKE_SERVICES_CONFIGURED_SETTING_NAME=OKE_SERVICES_CONFIGURED_$CLUSTER_CONTEXT_NAME

if [ -z "${!OKE_SERVICES_CONFIGURED_SETTING_NAME}" ]
then
  echo "No record of installing in cluster $CLUSTER_CONTEXT_NAME, cannot continue"
  exit 1
else
  echo "This script has already configured your Kubernetes cluster $CLUSTER_CONTEXT_NAME it will attempt to remove those services."
fi

#check for trying to re-use the context name
CONTEXT_NAME_EXISTS=`kubectl config get-contexts -o name | grep -w $CLUSTER_CONTEXT_NAME`

if [ -z $CONTEXT_NAME_EXISTS ]
then
  echo "Kubernetes context name of $CLUSTER_CONTEXT_NAME does not exist, cannot continue."
  echo "have you run the kubernetes-setup.sh script ?"
  exit 40
else
  echo "A kubernetes context called $CLUSTER_CONTEXT_NAME exists, continuing"
fi


OKE_REUSED_NAME=OKE_REUSED_$CLUSTER_CONTEXT_NAME
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
OKE_REUSED="${!OKE_REUSED_NAME}"
if [ -z $OKE_REUSED ]
then
  echo "No reuse information for OKE context $CLUSTER_CONTEXT_NAME cannot continue. Has this cluster"
  echo "been setup using the kubernrtes-setup.sh script ?"
  exit 3
else
  echo "Located details of Kubernetes cluster $CLUSTER_CONTEXT_NAME, continuing"
fi

# run the pre-existing script
bash ./resetEntireCluster.sh $CLUSTER_CONTEXT_NAME skip
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure destroying the cluster services, cannot continue"
  exit $RESP
fi

bash ../common/delete-from-saved-settings.sh $OKE_SERVICES_CONFIGURED_SETTING_NAME
#!/bin/bash -f

CLUSTER_CONTEXT=one
if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT=$1
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

if [ -z $USER_INITIALS ]
then
  echo "Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
  exit 3
fi


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Have you setup the basic core elements (database, container images, database) and installed the example setup in the tenancy defaulting to $REPLY"
else
  read -p "Have you setup the basic core elements (database, container images, database) and installed the example setup in the tenancy (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, this script will exit, please setup the environment, the lab-specific/optional-kubernetes-lab-setup.sh script can do this for you"
  exit -1
fi
if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Have you setup the security SSH keys, created the vault, dynamic groups and policies for devops defaulting to $REPLY"
else
  read -p "Have you setup the security SSH keys, created the vault, dynamic groups and policies for devops (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, this script will exit, please setup SSH keys, created the vault, dynamic groups and policies for devops, the vault-setup.sh and security-setup.sh scripts can do this for you"
  exit -2
fi
if [ -z "$DEVOPS_DYNAMIC_GROUPS_CONFIGURED" ]
then
  echo "Dynamic groups not yet configured"
  exit 4
else
  echo "Dynamic groups have been configured"
fi


if [ -z "$DEVOPS_POLICIES_CONFIGURED" ]
then
  echo "DevOps policies not configured"
  exit 5
else
  echo "DevOps policies have been configured"
fi

if [ -z "$DEVOPS_SSH_API_KEY_CONFIGURED" ]
then
  echo "SSH API Key for devops not previously configured"
  exit 6
else
  echo "These scripts have previously setup the SSH API Key for devops"
fi


if [ -z "$VAULT_OCID" ]
then
  echo "No vault OCID set, have you run the vault-setup.sh script ?"
  exit 7
else
  echo "Found vault"
fi
ITEM_NAMES_FILE=names.sh
if [ -f "$ITEM_NAMES_FILE" ]
then
  echo "Located the names file $ITEM_NAMES_FILE, loading it"
  source $ITEM_NAMES_FILE
else
  echo "Unable to locate the names file $ITEM_NAMES_FILE this means the script will now have any of the names to process, cannot continue"
  exit 7
fi

echo "Passed checks starting to create environment"

SAVED_DIR=`pwd`
COMMON_DIR=`pwd`/../../common
DEVOPS_LAB_DIR=$SAVED_DIR/..

echo "This script attempts to follow the order of the dev-ops lab"
echo "Create notifications topic"
cd $COMMON_DIR/notifications
bash ./topic-setup.sh "$TOPIC_NAME" 'Communication between DevOps service elements'
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Topic setup module returned an error, unable to continue"
  exit $RESP
fi
echo "Create project"
cd $SAVED_DIR
cd $COMMON_DIR/devops
bash ./project-setup.sh $PROJECT_NAME $TOPIC_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "DevOps project setup module returned an error, unable to continue"
  exit $RESP
fi
echo "Enabling project logging"
PROJECT_OCID=`bash ./get-project-ocid.sh $PROJECT_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "DevOps project get ocid returned an error, unable to continue"
  exit $RESP
fi
cd $SAVED_DIR
cd $COMMON_DIR/logging
echo "Creating log group"
bash ./log-group-setup.sh "$LOG_GROUP_NAME" "$LOG_GROUP_DESCRIPTION"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating log group, unable to continue"
  exit $RESP
fi
echo "Creating log "
bash ./log-oci-service-setup.sh $LOG_NAME $LOG_GROUP_NAME devops $PROJECT_OCID
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating log , unable to continue"
  exit $RESP
fi

cd $SAVED_DIR
cd $COMMON_DIR/devops
echo "Creating code repo"
bash ./repo-setup.sh $CODE_REPO_NAME $PROJECT_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating code repo , unable to continue"
  exit $RESP
fi
cd $SAVED_DIR
cd $DEVOPS_LAB_DIR
echo "Uploading the git repo"
bash ./upload-git-repo.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem uploading git repo initial code, unable to continue"
  exit $RESP
fi


cd $SAVED_DIR
cd $DEVOPS_LAB_DIR
echo "Setting up vault secrets"
bash ./vault-secrets-setup.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating vault secrets, unable to continue"
  exit $RESP
fi

echo "Retrieving vault secrets OCID's"
cd $COMMON_DIR/vault

HOST_SECRET_OCID=`bash ./get-vault-secret-ocid.sh $HOST_SECRET_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for vault secret $HOST_SECRET_NAME, unable to continue"
  exit $RESP
fi
NAMESPACE_SECRET_OCID=`bash ./get-vault-secret-ocid.sh $NAMESPACE_SECRET_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for vault secret $NAMESPACE_SECRET_NAME, unable to continue"
  exit $RESP
fi

echo "Creating new branch for modifications"
cd $CODE_BASE
git checkout -b my-lab-branch

echo "Updating build spec"
cp $SOURCE_BUILD_SPEC $CODE_BASE

bash $COMMON_DIR/update-file.sh $WORKING_BUILD_SPEC 'Needs your host secrets OCID' $HOST_SECRET_OCID

bash $COMMON_DIR/update-file.sh $WORKING_BUILD_SPEC 'Needs your storage namespace OCID' $NAMESPACE_SECRET_OCID

echo "Updating version number"
bash $COMMON_DIR/update-file.sh  $STATUS_RESOURCE '1.0.0' '1.0.1'

echo "Updating local repo and uploading to remote repo"
git add .
git commit -a -m 'Set secret OCIDs and updated version'
git push devops my-lab-branch

echo "Creating build pipeline"
cd $COMMON_DIR/devops
bash ./build-pipeline-setup.sh $BUILD_PIPELINE_NAME $PROJECT_NAME 'Builds the storefront service'
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating build pipeline $BUILD_PIPELINE_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi
BUILD_PIPELINE_OCID=`bash ./get-build-pipeline-ocid.sh $BUILD_PIPELINE_NAME $PROJECT_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for build pipeline $BUILD_PIPELINE_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi
echo "Creating OCIR repo"
cd $COMMON_DIR/ocir
# create it as public and not immutable
bash  ./ocir-setup.sh $OCIR_REPO_NAME true false
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating OCIR repo $OCIR_REPO_NAME, unable to continue"
  exit $RESP
fi
OCIR_REPO_OCID=`bash ./get-ocir-ocid.sh $OCIR_REPO_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for OCIR repo $OCIR_REPO_NAME, unable to continue"
  exit $RESP
fi

echo "Creating artifact repo"
cd $COMMON_DIR/artifactrepo
bash ./artifact-repo-generic-setup.sh $ARTIFACT_REPO_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for artifact repo $ARTIFACT_REPO_NAME, unable to continue"
  exit $RESP
fi

ARTIFACT_REPO_OCID=`bash ./get-artifact-repo-ocid.sh $ARTIFACT_REPO_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for artifact repo $ARTIFACT_REPO_NAME, unable to continue"
  exit $RESP
fi

echo "Creating deploy pipeline"

cd $COMMON_DIR/devops
bash ./deploy-pipeline-setup.sh $DEPLOY_PIPELINE_NAME $PROJECT_NAME 'Deploys the storefront service'
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating deploy pipeline $DEPLOY_PIPELINE_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi
DEPLOY_PIPELINE_OCID=`bash ./get-deploy-pipeline-ocid.sh $DEPLOY_PIPELINE_NAME $PROJECT_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for deploy pipeline $DEPLOY_PIPELINE_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi
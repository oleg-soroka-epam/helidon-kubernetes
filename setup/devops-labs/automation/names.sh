TOPIC_NAME="$USER_INITIALS""DevOpsTopic"
PROJECT_NAME="$USER_INITIALS""DevOpsProject"
LOG_GROUP_NAME="Default_Group"
LOG_GROUP_DESCRIPTION="Auto created log group for all users in the compartment"
LOG_NAME="$PROJECT_NAME""_all"
CODE_REPO_NAME="cloudnative-helidon-storefront"
HOST_SECRET_NAME="OCIR_HOST"
NAMESPACE_SECRET_NAME="OCIR_STORAGE_NAMESPACE"
CODE_BASE="$HOME/cloudnative-helidon-storefront"
SOURCE_BUILD_SPEC="$CODE_BASE/helidon-storefront-full/yaml/build/build_spec.yaml"
WORKING_BUILD_SPEC="$CODE_BASE/build_spec.yaml"
STATUS_RESOURCE="$CODE_BASE/helidon-storefront-full/src/main/java/com/oracle/labs/helidon/storefront/resources/StatusResource.java"
BUILD_PIPELINE_NAME="BuildStorefront"
OCIR_REPO_NAME="$USER_INITIALS""devops/storefront"
ARTIFACT_REPO_NAME="$USER_INITIALS""DevOps"
DEPLOY_PIPELINE_NAME="DeployStorefront"

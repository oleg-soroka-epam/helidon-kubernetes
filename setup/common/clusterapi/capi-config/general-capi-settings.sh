# the following are the requird settings, ones that are commented out will be set by the 
# main CAPI setup script, but can be overridden here or in the cluster-specific-capi-settings-???.sh file
# can;t see whyt anytione woudl override this, given these are beneraited dynamicallywhen the compartment is created, but they can if they need to 
#OCI_COMPARTMENT_ID=<compartment-id>
# the id of the image to use
# this shoudl probabaly be set here
# but until we find out how to leave it for now
#OCI_IMAGE_ID=<ubuntu-custom-image-id>
# the ssh key - will be created automatically and set by the scripts
# but I guess someone might want to use a single key for it all
#OCI_SSH_KEY=<ssh-key>
# how many conrteol planes vm's do you want ?
# CONTROL_PLANE_MACHINE_COUNT=1
# the version of kubernrtes to install in the cluster, probabaly this will need updating
# over time
KUBERNETES_VERSION=v1.23.4
# this is the namespace in the OKE management cluster and the resources will be created in, it will be created if needs be
#NAMESPACE=default
# number of workers maybe - this is a little unclear
#NODE_MACHINE_COUNT=1
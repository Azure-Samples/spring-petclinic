#!/bin/bash
#
# configure-workshop-environment.sh
#
#   Configures the subscription with providers - SaaS, Platform and Insights.
#   Configures az CLI
# 

####################################################################
# FUNCTIONS
####################################################################
usage() {
  echo ""
  echo "Usage: "
  echo "  "
  echo "  $0 -n UNIQUE_NAME -s SUBSCRIPTION"
  echo "  "
  echo "  UNIQUE_NAME should be lowercase letters, numbers and dashes less than 40 characters long."
  echo "  "
  echo "  e.g. $0 -n spring-native-workshop01 -s aaaabbbb-cccc-dddd-eeee-ffffgggghhhh"
  echo "  "
  echo ""
}

exit_abnormal() {
  usage
  exit 1
}

# Validate Subscription and Unique Name
validate-subscription-and-unique-name() {
  
  echo "----------------------------------------"
  echo "Validating Subscription ... "
  SUBSCRIPTION_STATE=$(az account show --subscription "${SUBSCRIPTION}" --query state -o tsv)
  if [[ $? -ne 0 ]]
  then
    echo "  Subscription [${SUBSCRIPTION}] doesn't exist."
    exit 3
  fi
  echo "  Subscription: ${SUBSCRIPTION}"
  echo "  State:        ${SUBSCRIPTION_STATE}"
  
  if [[ $SUBSCRIPTION_STATE == "Enabled" ]]; then
    echo "  Subscription [${SUBSCRIPTION}] exists and it is Enabled."
  elif [[ $SUBSCRIPTION_STATE == "Disabled" ]]; then
     echo "  Subscription [${SUBSCRIPTION}] exists but it is Disabled."
     exit 2 
  fi
  echo ""
  echo ""

  echo "Validating UNIQUE_NAME ..."
  if [[ "${UNIQUE_NAME}" =~ ^[a-zA-Z0-9][-a-zA-Z0-9]{0,38}[a-zA-Z0-9]$ ]]
  then
    echo "  UNIQUE_NAME ${UNIQUE_NAME} is valid."
  else
    echo "  UNIQUE_NAME Name ${UNIQUE_NAME} is not valid."
    exit_abnormal
  fi
  echo ""
  echo ""

}

# Configure AZ CLI
configure-az-cli() {
  az extension update --name spring
  az extension update --name serviceconnector-passwordless
  az extension update --name account
}

# Configuring ASAE provider and accepting the terms and conditions of the metered plan
configure-asae-provider-and-plan() {
  az provider register --namespace Microsoft.SaaS --subscription "${SUBSCRIPTION}" --wait
  az provider register --namespace Microsoft.AppPlatform --subscription "${SUBSCRIPTION}" --wait
  az provider register --namespace Microsoft.Insights --subscription "${SUBSCRIPTION}" --wait
  az provider register --namespace Microsoft.OperationalInsights --subscription "${SUBSCRIPTION}" --wait
  az provider register --namespace Microsoft.DBforMySQL --subscription "${SUBSCRIPTION}" --wait
  az provider register --namespace Microsoft.DBforPostgreSQL --subscription "${SUBSCRIPTION}" --wait
  az term accept --subscription "${SUBSCRIPTION}" \
    --publisher vmware-inc \
    --product azure-spring-cloud-vmware-tanzu-2 \
    --plan asa-ent-hr-mtr
}

####################################################################
# MAIN
####################################################################
# set -euxo pipefail
set -o pipefail

while getopts ":n:s:" flag
do
  case "$flag" in
    n)
      UNIQUE_NAME=${OPTARG}
      echo "UNIQUE_NAME:  $UNIQUE_NAME"
      ;;
    s)
      SUBSCRIPTION=${OPTARG}
      echo "SUBSCRIPTION: $SUBSCRIPTION"
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit_abnormal
      ;;
    *)
      echo "Error: invalid arguments."
      exit_abnormal
      ;;
  esac
done

# set -x 

validate-subscription-and-unique-name
configure-az-cli
configure-asae-provider-and-plan

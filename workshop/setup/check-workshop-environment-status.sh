#!/bin/bash
#
# check-workshop-environment-status.sh
#
#   Checks the stauts of ASAE instance
#   Checks the status of PostgreSQL flexible server instance
#   Checks the status of MySQL flexible server instance
# 

####################################################################
# FUNCTIONS
####################################################################
usage() {
  echo ""
  echo "Usage: "
  echo "  "
  echo "  $0 -n UNIQUE_NAME -s SUBSCRIPTION -r REGION"
  echo "  "
  echo "  UNIQUE_NAME should be lowercase letters, numbers and dashes less than 40 characters long."
  echo "  "
  echo "  e.g. $0 -n springone-native-workshop01 -s aaaabbbb-cccc-dddd-eeee-ffffgggghhhh -r eastus"
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

# Setup all environment variables
set_environment_variables() {
  export RESOURCE_GROUP="${UNIQUE_NAME}-rg"
  export SPRING_APPS_SERVICE="${UNIQUE_NAME}-asa"
  export MYSQL_SERVER_NAME="${UNIQUE_NAME}-mysql"
  export POSTGRESQL_SERVER_NAME="${UNIQUE_NAME}-postgres"
}

# Check status of an instance of Azure Spring Apps Enterprise
check-status-azure-spring-apps-enterprise-instance() {
  ASA_STATUS=$(az spring show \
    --subscription "${SUBSCRIPTION}" \
    --name "${SPRING_APPS_SERVICE}" \
    --resource-group "${RESOURCE_GROUP}" \
    --output tsv \
    --query "properties.powerState")
}

# Check status of an instance of Azure Spring Apps Enterprise
check-status-postgresql-instance() {
  export POSTGRESQL_STATUS=$(az postgres flexible-server show \
    --subscription "${SUBSCRIPTION}" \
    --name "${POSTGRESQL_SERVER_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --output tsv \
    --query "state")
}

# Check status of an instance of Azure Spring Apps Enterprise
check-status-mysql-instance() {
  export MYSQL_STATUS=$(az mysql flexible-server show \
    --subscription "${SUBSCRIPTION}" \
    --name "${MYSQL_SERVER_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --output tsv \
    --query "state")
}

output-status() {
  echo "------------------------------------------------------------"
  echo "Checking status of ${UNIQUE_NAME} ..."
  echo "  ${SPRING_APPS_SERVICE}:        $ASA_STATUS"
  echo "  ${MYSQL_SERVER_NAME}:      $MYSQL_STATUS"
  echo "  ${POSTGRESQL_SERVER_NAME}: $POSTGRESQL_STATUS"
  echo ""
}

####################################################################
# MAIN
####################################################################
# set -euxo pipefail
set -o pipefail

while getopts ":n:r:s:" flag
do
  case "$flag" in
    n)
      UNIQUE_NAME=${OPTARG}
      echo "UNIQUE_NAME:  $UNIQUE_NAME"
      ;;
    r)
      REGION=${OPTARG}
      echo "REGION:       $REGION"
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
set_environment_variables
check-status-azure-spring-apps-enterprise-instance
check-status-postgresql-instance
check-status-mysql-instance
output-status

#!/bin/bash
#
# start-workshop-environment.sh
#
#   Starts ASAE instance
#   Starts PostgreSQL instance
#   Starts MySQL instance
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
  echo "  e.g. $0 -n spring-native-01 -s aaaabbbb-cccc-dddd-eeee-ffffgggghhhh -r eastus"
  echo "  "
  echo ""
}

exit_abnormal() {
  usage
  exit 1
}

# Setup all environment variables
set_environment_variables() {
  export RESOURCE_GROUP=${UNIQUE_NAME}-rg
  export SPRING_APPS_SERVICE=${UNIQUE_NAME}-asa
  export MYSQL_SERVER_NAME="${UNIQUE_NAME}-mysql"
  export POSTGRESQL_SERVER_NAME="${UNIQUE_NAME}-postgresql"
}

# Set default Azure subscription, check if exists
set_valid_subscription() {
  az account set --subscription ${SUBSCRIPTION}
}

# Start the ASA instance
start-azure-spring-apps-instance() {
  az spring start \
    --subscription "${SUBSCRIPTION}" \
    --name "${SPRING_APPS_SERVICE}" \
    --resource-group "${RESOURCE_GROUP}"
}

# Start the PostgreSQL server (restarts automatically after 7 days)
start-postgresql-server() {
  az postgres flexible-server start \
    --subscription "${SUBSCRIPTION}" \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${POSTGRESQL_SERVER_NAME}"
}

# Start the MySQL server (restarts automatically after 7 days)
start-mysql-server() {
  az mysql flexible-server start \
    --subscription "${SUBSCRIPTION}" \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${MYSQL_SERVER_NAME}"
}

# Configure the ASA Build Tool 
configure-build-tool() {
  
  az spring update \
    --subscription "${SUBSCRIPTION}" \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${SPRING_APPS_SERVICE}" \
    --build-pool-size S7

  # See documentation
  #   https://learn.microsoft.com/en-us/azure/spring-apps/how-to-enterprise-build-service?tabs=azure-portal
  #
  # Scale set	  CPU/Gi
  # S1          2 vCPU, 4 Gi
  # S2          3 vCPU, 6 Gi
  # S3          4 vCPU, 8 Gi
  # S4          5 vCPU, 10 Gi
  # S5          6 vCPU, 12 Gi
  # S6          8 vCPU, 16 Gi
  # S7          16 vCPU, 32 Gi
  # S8          32 vCPU, 64 Gi
  # S9          64 vCPU, 128 Gi

}

####################################################################
# MAIN
####################################################################
# set -euxo pipefail
set -eo pipefail

while getopts ":n:r:s:" flag
do
  case "$flag" in
    n)
      UNIQUE_NAME=${OPTARG}
      echo "UNIQUE_NAME: $UNIQUE_NAME"
      ;;
    s)
      SUBSCRIPTION=${OPTARG}
      echo "SUBSCRIPTION: $SUBSCRIPTION"
      ;;
    r)
      REGION=${OPTARG}
      echo "REGION: $REGION"
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit_abnormal
      ;;
    *) exit_abnormal
      ;;
  esac
done

set -x 

set_environment_variables
# set_valid_subscription
start-azure-spring-apps-instance
configure-build-tool
start-postgresql-server
start-mysql-server

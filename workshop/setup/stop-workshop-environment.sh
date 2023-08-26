#!/bin/bash
#
# stop-workshop-environment.sh
#
#   Stops ASAE instance
#   Stops PostgreSQL instance
#   Stops MySQL instance
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
stop-azure-spring-apps-instance() {
  az spring stop \
    --subscription "${SUBSCRIPTION}" \
    --name "${SPRING_APPS_SERVICE}" \
    --resource-group "${RESOURCE_GROUP}"
}

# Start the PostgreSQL server (restarts automatically after 7 days)
stop-postgresql-server() {
  az postgres flexible-server stop \
    --subscription "${SUBSCRIPTION}" \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${POSTGRESQL_SERVER_NAME}"
}

# Start the MySQL server (restarts automatically after 7 days)
stop-mysql-server() {
  az mysql flexible-server stop \
    --subscription "${SUBSCRIPTION}" \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${MYSQL_SERVER_NAME}"
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
stop-azure-spring-apps-instance
stop-postgresql-server
stop-mysql-server

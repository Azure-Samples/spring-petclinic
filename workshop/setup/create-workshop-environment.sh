#!/bin/bash
#
# create-workshop-environment.sh
#
#   Creates a Resource Group
#   Creates an Azure Spring Apps Enterprise instance with Build Service S7
#   Creates a Log Analytics workspace
#   Creates PostgreSQL flexible server instance with an empty database
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
  echo "  e.g. $0 -n springone-native-workshop00 -s aaaabbbb-cccc-dddd-eeee-ffffgggghhhh -r eastus"
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
  export RESOURCE_GROUP=${UNIQUE_NAME}-rg
  export SPRING_APPS_SERVICE=${UNIQUE_NAME}-asa
  export LOG_ANALYTICS_WORKSPACE=${UNIQUE_NAME}-log-analytics

  export JAR_APP="jar-app"
  export NATIVE_APP="native-app"
  export DEFAULT_BUILDER="default"
  export NATIVE_BUILDER="native"

  export MYSQL_SERVER_NAME="${UNIQUE_NAME}-mysql"
  export MYSQL_SERVER_ADMIN_NAME="mysql_user"
  export MYSQL_SERVER_ADMIN_PASSWORD="8kJTTap82at7rnwPB5#u"
  export MYSQL_SERVER_FULL_NAME=${MYSQL_SERVER_NAME}.mysql.database.azure.com
  export MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_SERVER_ADMIN_NAME}\@${MYSQL_SERVER_NAME}
  export MYSQL_DATABASE_NAME="petclinic"
  export MYSQL_IDENTITY="mysql-identity"
  export MYSQL_DATABASE_CONNECTION_NAME="mysql_petclinic_connection"

  export POSTGRESQL_SERVER_NAME="${UNIQUE_NAME}-postgresql"
  export POSTGRESQL_SERVER_ADMIN_NAME="postgres_user"
  export POSTGRESQL_SERVER_ADMIN_PASSWORD="usX547fT5#QqsKGuY3EJ"
  export POSTGRESQL_SERVER_FULL_NAME="${POSTGRESQL_SERVER_NAME}.postgresql.database.azure.com"
  export POSTGRESQL_DATABASE_NAME="petclinic"
  export POSTGRESQL_DATABASE_CONNECTION_NAME="postgres_petclinic_connection"
}

# Set default Azure subscription, check if exists
set_valid_subscription() {
  az account set --subscription "${SUBSCRIPTION}"
}

# Create a resource group
create_resource_group() {
  az group create --name "${RESOURCE_GROUP}" --location "${REGION}" --subscription "${SUBSCRIPTION}"
}

# Create an instance of Azure Spring Apps Enterprise
create-azure-spring-apps-enterprise-instance() {
  az spring create --name ${SPRING_APPS_SERVICE} \
    --no-wait \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION} \
    --sku Enterprise \
    --enable-alv \
    --build-pool-size S1
}

# Create Log Analytics Workspace
create-log-analytics-and-bind-to-asa() {
  az monitor log-analytics workspace create \
    --subscription "${SUBSCRIPTION}" \
    --workspace-name ${LOG_ANALYTICS_WORKSPACE} \
    --location ${REGION} \
    --resource-group ${RESOURCE_GROUP}  

  export LOG_ANALYTICS_RESOURCE_ID=$(az monitor log-analytics workspace show \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --workspace-name ${LOG_ANALYTICS_WORKSPACE} | jq -r '.id')

  export SPRING_APPS_RESOURCE_ID=$(az spring show \
    --subscription "${SUBSCRIPTION}" \
    --name ${SPRING_APPS_SERVICE} \
    --resource-group ${RESOURCE_GROUP} | jq -r '.id')  

  az monitor diagnostic-settings create --name "send-logs-and-metrics-to-log-analytics" \
    --subscription "${SUBSCRIPTION}" \
    --resource ${SPRING_APPS_RESOURCE_ID} \
    --workspace ${LOG_ANALYTICS_RESOURCE_ID} \
    --logs '[
         {
           "category": "ApplicationConsole",
           "enabled": true,
           "retentionPolicy": {
             "enabled": false,
             "days": 0
           }
         },
         {
            "category": "SystemLogs",
            "enabled": true,
            "retentionPolicy": {
              "enabled": false,
              "days": 0
            }
          },
         {
            "category": "IngressLogs",
            "enabled": true,
            "retentionPolicy": {
              "enabled": false,
              "days": 0
             }
           }
       ]' \
       --metrics '[
         {
           "category": "AllMetrics",
           "enabled": true,
           "retentionPolicy": {
             "enabled": false,
             "days": 0
           }
         }
       ]'

}

# Create PostgreSQL server
create-postgresql-server-and-database() {
  az postgres flexible-server create \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION} \
    --name ${POSTGRESQL_SERVER_NAME} \
    --admin-user ${POSTGRESQL_SERVER_ADMIN_NAME} \
    --admin-password ${POSTGRESQL_SERVER_ADMIN_PASSWORD} \
    --tier Burstable \
    --sku-name Standard_B1ms \
    --storage-size 32 \
    --yes

  # See documentation:
  #  https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-compute-storage
  #
  #  Standard_D2s_v3 might not be always available in some regions, e.g. westus2
  # 

  az postgres flexible-server db create \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --server-name ${POSTGRESQL_SERVER_NAME} \
    --database-name ${POSTGRESQL_DATABASE_NAME} \

}

# Create MySQL server
create-mysql-server-and-database() {

  # create mysql server and provide access from Azure resources
  az mysql flexible-server create \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION} \
    --name ${MYSQL_SERVER_NAME} \
    --admin-user ${MYSQL_SERVER_ADMIN_NAME}  \
    --admin-password ${MYSQL_SERVER_ADMIN_PASSWORD} \
    --public-access 0.0.0.0 \
    --tier Burstable \
    --sku-name Standard_B1ms \
    --storage-size 32

  # allow access from your dev machine for testing
  MY_IP=$(curl -s whatismyip.akamai.com)
  az mysql flexible-server firewall-rule create \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --name ${MYSQL_SERVER_NAME} \
    --rule-name devMachine \
    --start-ip-address ${MY_IP} \
    --end-ip-address ${MY_IP}

  # create database
  az mysql flexible-server db create \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --server-name ${MYSQL_SERVER_NAME} \
    --database-name ${MYSQL_DATABASE_NAME}

  # increase connection timeout
  az mysql flexible-server parameter set \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --server ${MYSQL_SERVER_NAME} \
    --name wait_timeout \
    --value 2147483

  # set timezone   
  az mysql flexible-server parameter set \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --server ${MYSQL_SERVER_NAME} \
    --name time_zone \
    --value "US/Pacific"

  # create managed identity for mysql. By assigning the identity to the mysql server, it will enable Azure AD authentication
  az identity create \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION} \
    --name ${MYSQL_IDENTITY} \

  IDENTITY_ID=$(az identity show --name ${MYSQL_IDENTITY} --resource-group ${RESOURCE_GROUP} --subscription "${SUBSCRIPTION}" --query id -o tsv)

}

# Configure Tanzu Build Service
configure-tanzu-build-service() {

  az spring update \
    --subscription "${SUBSCRIPTION}" \
    --name $SPRING_APPS_SERVICE \
    --resource-group $RESOURCE_GROUP \
    --build-pool-size S7

  az spring build-service builder update -n ${DEFAULT_BUILDER} \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --builder-file azure/builder-default.json \
    --service ${SPRING_APPS_SERVICE} \

  az spring build-service builder create -n ${NATIVE_BUILDER} \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --builder-file azure/builder-native.json \
    --service ${SPRING_APPS_SERVICE} \

}

# Configure Dev Tools Portal
configure-dev-tools-portal() {
  az spring dev-tool update \
    --subscription "${SUBSCRIPTION}" \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_APPS_SERVICE} \
    --assign-endpoint
}

# Write to env variables file
write-out-setup-env-variables-file() {

  SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
  echo "Script directory: $SCRIPT_DIR"
  SETUP_FILE=${SCRIPT_DIR}/setup-env-variables-${UNIQUE_NAME}.sh
  echo "Writing out to ${SETUP_FILE} ..."
  echo "" > ${SETUP_FILE}
  
  echo "# ==== Azure Spring Apps INFO ====" >> ${SETUP_FILE}
  echo "export SUBSCRIPTION='${SUBSCRIPTION}'" >> ${SETUP_FILE}
  echo "export RESOURCE_GROUP='${RESOURCE_GROUP}'" >> ${SETUP_FILE}
  echo "export SPRING_APPS_SERVICE='${SPRING_APPS_SERVICE}'" >> ${SETUP_FILE}
  echo "export LOG_ANALYTICS_WORKSPACE='${LOG_ANALYTICS_WORKSPACE}'" >> ${SETUP_FILE}
  echo "export REGION='${REGION}'" >> ${SETUP_FILE}
  echo "" >> ${SETUP_FILE}
  echo "export JAR_APP='jar-app'" >> ${SETUP_FILE}
  echo "export NATIVE_APP='native-app'" >> ${SETUP_FILE}
  echo "" >> ${SETUP_FILE}
  echo "export DEFAULT_BUILDER='default'" >> ${SETUP_FILE}
  echo "export NATIVE_BUILDER='native'" >> ${SETUP_FILE}
  echo "" >> ${SETUP_FILE}
  echo "# ==== MYSQL INFO ====" >> ${SETUP_FILE}
  echo "export MYSQL_SERVER_NAME='${MYSQL_SERVER_NAME}'" >> ${SETUP_FILE}
  echo "export MYSQL_SERVER_ADMIN_NAME='${MYSQL_SERVER_ADMIN_LOGIN_NAME}'" >> ${SETUP_FILE}
  echo "export MYSQL_SERVER_ADMIN_PASSWORD='${MYSQL_SERVER_ADMIN_PASSWORD}'" >> ${SETUP_FILE}
  echo "export MYSQL_SERVER_FULL_NAME='${MYSQL_SERVER_FULL_NAME}'" >> ${SETUP_FILE}
  echo "export MYSQL_SERVER_ADMIN_LOGIN_NAME='${MYSQL_SERVER_ADMIN_LOGIN_NAME}'" >> ${SETUP_FILE}
  echo "export MYSQL_DATABASE_NAME='${MYSQL_DATABASE_NAME}'" >> ${SETUP_FILE}
  echo "export MYSQL_IDENTITY='${MYSQL_IDENTITY}'" >> ${SETUP_FILE}
  echo "export MYSQL_DATABASE_CONNECTION_NAME='${MYSQL_DATABASE_CONNECTION_NAME}'" >> ${SETUP_FILE}
  echo "" >> ${SETUP_FILE}
  echo "# ==== POSTGRESQL INFO ====" >> ${SETUP_FILE}
  echo "export POSTGRESQL_SERVER_NAME='${POSTGRESQL_SERVER_NAME}'" >> ${SETUP_FILE}
  echo "export POSTGRESQL_SERVER_ADMIN_NAME='${POSTGRESQL_SERVER_ADMIN_NAME}'" >> ${SETUP_FILE}
  echo "export POSTGRESQL_SERVER_ADMIN_PASSWORD='${POSTGRESQL_SERVER_ADMIN_PASSWORD}'" >> ${SETUP_FILE}
  echo "export POSTGRESQL_SERVER_FULL_NAME='${POSTGRESQL_SERVER_FULL_NAME}'" >> ${SETUP_FILE}
  echo "export POSTGRESQL_DATABASE_NAME='${POSTGRESQL_DATABASE_NAME}'" >> ${SETUP_FILE}
  echo "export POSTGRESQL_DATABASE_CONNECTION_NAME='${POSTGRESQL_DATABASE_CONNECTION_NAME}'" >> ${SETUP_FILE}
  echo "" >> ${SETUP_FILE}
  echo "# ==== SET DEFAULT SUBSCRIPTION AND CONFIGURE DEFAULTS ====" >> ${SETUP_FILE}
  echo "az account set --subscription ${SUBSCRIPTION}" >> ${SETUP_FILE}
  echo "az configure --defaults \\" >> ${SETUP_FILE}                          
  echo "    group=${RESOURCE_GROUP} \\" >> ${SETUP_FILE}
  echo "    location=${REGION} \\" >> ${SETUP_FILE}
  echo "    spring=${SPRING_APPS_SERVICE}" >> ${SETUP_FILE}
  echo "" >> ${SETUP_FILE}

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
# set_valid_subscription
create_resource_group
create-azure-spring-apps-enterprise-instance
create-log-analytics-and-bind-to-asa
create-postgresql-server-and-database
create-mysql-server-and-database
configure-tanzu-build-service
configure-dev-tools-portal
write-out-setup-env-variables-file

echo "Success! You have built an Azure Spring Apps environment for the workshop:"
echo ""
echo " RESOURCE_GROUP: ${RESOURCE_GROUP}"
echo " SUBSCRIPTION:   ${SUBSCRIPTION}"
echo " REGION:         ${REGION}"
echo ""
echo "Done."

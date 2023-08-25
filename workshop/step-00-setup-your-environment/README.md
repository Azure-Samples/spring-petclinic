# Workshop Content

* [Deploy Spring Native Application to Azure Spring Apps Enterprise](../README.md)
  * [Unit 0 - Prerequisites and Setup](../step-00-setup-your-environment/README.md)
    * [Prerequisites](#prerequisites)
    * [Install the Azure CLI extension](../step-00-setup-your-environment#install-the-azure-cli-extension)
    * [Pre-configure the environment](../step-00-setup-your-environment#pre-configure-the-environment)
      * [Clone the Repository](../step-00-setup-your-environment#clone-the-repository)
      * [Configure Environment Variables](../step-00-setup-your-environment#configure-environment-variables)
      * [Login to Azure](../step-00-setup-your-environment#login-to-azure)
      * [Create Azure Spring Apps Enterprise instance](../step-00-setup-your-environment#create-azure-spring-apps-enterprise-instance)
      * [Configure Log Analytics for Azure Spring Apps](../step-00-setup-your-environment#configure-log-analytics-for-azure-spring-apps)
      * [Create MySQL Database](../step-00-setup-your-environment#create-mysql-database)
      * [Create PostgreSQL Database](../step-00-setup-your-environment#create-postgresql-database)
      * [Configure Tanzu Build Service](../step-00-setup-your-environment#configure-tanzu-build-service)
      * [Configure Dev Tools Portal](../step-00-setup-your-environment#configure-dev-tools-portal)
  * [Unit 1 - Create an Azure Spring Apps application](../step-01-create-asa-app/README.md)
  * [Unit 2 - Deploy an Azure Spring Apps application](../step-02-deploy-asa-app/README.md)
  * [Unit 3a - Bind to Database](../step-03a-bind-to-postgresql-database/README.md)
  * [Unit 3b - Bind to Database](../step-03a-bind-to-mysql-database/README.md)
  * [Unit 4 - Measuring and Optimizing Usage](../step-04-measuring-and-optimizing-usage/README.md)
  * [Unit 5 - Run and Build App Locally](../step-05-run-and-build-app-locally/README.md)

# Unit 0 - Prerequisites and Setup

This module defines all prerequisites and helps you prepare the environment for the rest of the workshop. Typically, this module will be preconfigured before you start your workshop.

Please consult your workshop instructor to confirm the workshop setup has been pre-initialized for you:
* An Azure resource group
* A pre-created Azure Spring Apps Enterprise instance
* Log Analytics created and attached to the Azure Spring Apps instance
* A SQL database server with configured access, database instance, credentials (e.g. MySQL or PostgreSQL)
* Managed identity to allow Azure Spring App instance to connect to database

## Prerequisites

In order to deploy a Java app to cloud, you need an Azure subscription.
If you do not already have an Azure subscription, you can activate your
[MSDN subscriber benefits](https://azure.microsoft.com/pricing/member-offers/msdn-benefits-details/)
or sign up for a [free Azure account]((https://azure.microsoft.com/free/)).

In addition, you will need the following:

| [Azure CLI version 2.47.0 or higher](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest)
| [Git](https://git-scm.com/)
| [`jq` utility](https://stedolan.github.io/jq/download/)
|

Note -  On Windows, the [`jq` utility](https://stedolan.github.io/jq/download/) should be renamed from `jq-win64.exe` to `jq.exe` and added to the `PATH`

Note - The Bash shell. While Azure CLI should behave identically on all environments, shell
semantics vary. Therefore, only bash can be used with the commands in this repo.
To complete these repo steps on Windows, use Git Bash that accompanies the Windows distribution of
Git. Use only Git Bash to complete this training on Windows. Do not use WSL.

### OR Use Azure Cloud Shell

Or, you can use the Azure Cloud Shell. Azure hosts Azure Cloud Shell, an interactive shell
environment that you can use through your browser. You can use the Bash with Cloud Shell
to work with Azure services. You can use the Cloud Shell pre-installed commands to run the
code in this README without having to install anything on your local environment. To start Azure
Cloud Shell: go to [https://shell.azure.com](https://shell.azure.com), or select the
Launch Cloud Shell button to open Cloud Shell in your browser.

To run the code in this article in Azure Cloud Shell:

1. Start Cloud Shell.
2. Select the Copy button on a code block to copy the code, e.g. `GZSWYRXCF`.
3. Paste the code into the Cloud Shell session by selecting Ctrl+Shift+V on Windows and Linux or by selecting Cmd+Shift+V on macOS.
4. Select Enter to run the code.

## Install the Azure CLI extension

Install the Azure Spring Apps extension for the Azure CLI using the following command

```shell
az extension add --name spring
```

If the extension is already installed, update it with the following command

```shell
az extension update --name spring
```

Note - In some cases, the update command may fail and it will be necessary to reinstall the Azure
Spring Apps extension. Use the following command to remove previous versions and install the latest 
Azure Spring Apps extension:

```shell
az extension remove --name spring-cloud
az extension remove --name spring
az extension add --name spring
```

## Pre-configure the environment

In case the workshop instructor cannot confirm that the environment has been pre-configured,
here are the steps you need to do before you can start with this workshop:

### Clone the Repository

Please clone this repository in your shell (or Cloud Shell), e.g.

```shell
mkdir source-code
cd source-code
git clone https://github.com/Azure-Samples/spring-petclinic
cd spring-petclinic
```

### Configure Environment Variables

Create a bash script with environment variables by making a copy of the supplied template:

```
cp ./azure/setup-env-variables-template.sh ./azure/setup-env-variables.sh
```

Open `./azure/setup-env-variables.sh` and enter the following information:

```shell
# ==== Azure Spring Apps INFO ====
export SUBSCRIPTION=subscription-id                 # replace it with your subscription-id
export RESOURCE_GROUP=resource-group-name           # existing resource group or one that will be created in next steps
export SPRING_APPS_SERVICE=azure-spring-apps-name   # name of the service that will be created in the next steps
export LOG_ANALYTICS_WORKSPACE=log-analytics-name   # existing workspace or one that will be created in next steps
export REGION=region-name                           # choose a region with Enterprise tier support

export JAR_APP="jar-app"
export NATIVE_APP="native-app"

export DEFAULT_BUILDER="default"
export NATIVE_BUILDER="native"

# ==== MYSQL INFO ====
export MYSQL_SERVER_NAME="mysql-petclinic" # customize this
export MYSQL_SERVER_ADMIN_NAME="azureuser" # customize this
export MYSQL_SERVER_ADMIN_PASSWORD="SuperS3cr3t" # customize this
export MYSQL_SERVER_FULL_NAME=${MYSQL_SERVER_NAME}.mysql.database.azure.com
export MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_SERVER_ADMIN_NAME}\@${MYSQL_SERVER_NAME}
export MYSQL_DATABASE_NAME="petclinic"
export MYSQL_IDENTITY="mysql-identity"
export MYSQL_DATABASE_CONNECTION_NAME="mysql_petclinic"

# ==== POSTGRESQL INFO ====
export POSTGRESQL_SERVER_NAME="postgres-petclinic" # customize this
export POSTGRESQL_SERVER_ADMIN_NAME="azureuser" # customize this
export POSTGRESQL_SERVER_ADMIN_PASSWROD="SuperS3cr3t" # customize this
export POSTGRESQL_SERVER_FULL_NAME="${POSTGRESQL_SERVER_NAME}.postgres.database.azure.com"
export POSTGRESQL_DATABASE_NAME="petclinic"
export POSTGRESQL_DATABASE_CONNECTION_NAME="postgres_petclinic"
```

The REGION value should be one of available regions for Azure Spring Apps (e.g. eastus).
Please visit [here](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=spring-apps&regions=all)
for all available regions for Azure Spring Apps.

Then, set the environment:

```shell
source ./azure/setup-env-variables.sh
```

### Login to Azure

Login to the Azure CLI and choose your active subscription.

```shell
az login
az account list -o table
az account set --subscription ${SUBSCRIPTION}
```

### Create Azure Spring Apps Enterprise instance

Prepare a name for your Azure Spring Apps service. The name must be between 4 and 32 characters
long and can contain only lowercase letters, numbers, and hyphens. The first character of the
service name must be a letter and the last character must be either a letter or a number.

Create a resource group to contain your Azure Spring Apps service.

> Note: This step can be skipped if using an existing resource group

```shell
az group create --name ${RESOURCE_GROUP} \
    --location ${REGION}
```

Accept the legal terms and privacy statements for the Enterprise tier.

> Note: This step is necessary only if your subscription has never been used to create an Enterprise tier instance of Azure Spring Apps.

```shell
az provider register --namespace Microsoft.SaaS
az term accept --publisher vmware-inc --product azure-spring-cloud-vmware-tanzu-2 --plan asa-ent-hr-mtr
```

Create an instance of Azure Spring Apps Enterprise.

```shell
az spring create --name ${SPRING_APPS_SERVICE} \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION} \
    --sku Enterprise \
    --enable-alv \
    --build-pool-size S7 
```

> Note: If the `create` command fails, try updating the Azure Spring Apps extension described [here](#install-the-azure-cli-extension)

> Note: The service instance will take around 10-15 minutes to deploy.

Set your default resource group name and cluster name using the following commands:

```shell
az configure --defaults \
    group=${RESOURCE_GROUP} \
    location=${REGION} \
    spring=${SPRING_APPS_SERVICE}
```

### Configure Log Analytics for Azure Spring Apps

Create a Log Analytics Workspace to be used for your Azure Spring Apps service.

> Note: This step can be skipped if using an existing workspace

```shell
az monitor log-analytics workspace create \
  --workspace-name ${LOG_ANALYTICS_WORKSPACE} \
  --location ${REGION} \
  --resource-group ${RESOURCE_GROUP}   
```

Retrieve the resource ID for the recently create Azure Spring Apps Service and Log Analytics Workspace:

```shell
export LOG_ANALYTICS_RESOURCE_ID=$(az monitor log-analytics workspace show \
    --resource-group ${RESOURCE_GROUP} \
    --workspace-name ${LOG_ANALYTICS_WORKSPACE} | jq -r '.id')

export SPRING_APPS_RESOURCE_ID=$(az spring show \
    --name ${SPRING_APPS_SERVICE} \
    --resource-group ${RESOURCE_GROUP} | jq -r '.id')
```

Configure diagnostic settings for the Azure Spring Apps Service:

```shell
az monitor diagnostic-settings create --name "send-logs-and-metrics-to-log-analytics" \
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
```

> Note: For Git Bash users, this command may fail when resource IDs are misinterpreted as file paths because they begin with `/`. 
> 
> If the above command fails, try setting MSYS_NO_PATHCONV using:
> 
> `export MSYS_NO_PATHCONV=1`

### Create MySQL Database

Create a MySQL database in Azure Database for MySQL. Alternatively, you can create PostgreSQL database instead, described in the next step.

```bash
# create mysql server and provide access from Azure resources
az mysql flexible-server create \
    --name ${MYSQL_SERVER_NAME} \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION} \
    --admin-user ${MYSQL_SERVER_ADMIN_NAME}  \
    --admin-password ${MYSQL_SERVER_ADMIN_PASSWORD} \
    --public-access 0.0.0.0 \
    --tier Burstable \
    --sku-name Standard_B1ms \
    --storage-size 32

# allow access from your dev machine for testing
MY_IP=$(curl -s whatismyip.akamai.com)
az mysql flexible-server firewall-rule create \
        --resource-group ${RESOURCE_GROUP} \
        --name ${MYSQL_SERVER_NAME} \
        --rule-name devMachine \
        --start-ip-address ${MY_IP} \
        --end-ip-address ${MY_IP}

# create database
az mysql flexible-server db create \
        --resource-group ${RESOURCE_GROUP} \
        --server-name ${MYSQL_SERVER_NAME} \
        --database-name ${MYSQL_DATABASE_NAME}

# increase connection timeout
az mysql flexible-server parameter set \
    --resource-group ${RESOURCE_GROUP} \
    --server ${MYSQL_SERVER_NAME} \
    --name wait_timeout \
    --value 2147483

# set timezone   
az mysql flexible-server parameter set \
    --resource-group ${RESOURCE_GROUP} \
    --server ${MYSQL_SERVER_NAME} \
    --name time_zone \
    --value "US/Pacific"

# create managed identity for mysql. By assigning the identity to the mysql server, it will enable Azure AD authentication
az identity create \
    --name ${MYSQL_IDENTITY} \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION}

IDENTITY_ID=$(az identity show --name ${MYSQL_IDENTITY} --resource-group ${RESOURCE_GROUP} --query id -o tsv)
```

### Create PostgreSQL Database

Alternative to MySQL in previous step is PostgreSQL. Create a PostgreSQL database in Azure Database for PostgreSQL.

```bash
az postgres flexible-server create \
  --resource-group ${RESOURCE_GROUP} \
  --location ${REGION} \
  --name ${POSTGRESQL_SERVER_NAME} \
  --admin-user ${POSTGRESQL_SERVER_ADMIN_NAME} \
  --admin-password ${POSTGRESQL_SERVER_ADMIN_PASSWORD} \
  --sku-name Standard_D2s_v3 \
  --storage-size 32 \
  --yes

az postgres flexible-server db create \
  --database-name ${POSTGRESQL_DATABASE_NAME} \
  --server-name ${POSTGRESQL_SERVER_NAME}
```

### Configure Tanzu Build Service

Update an existing `default` builder, and create a custom builder in Tanzu Build Service, using
the Azure CLI:

```shell
az spring build-service builder update -n ${DEFAULT_BUILDER} \
    --builder-file azure/builder-default.json \
    --no-wait

az spring build-service builder create -n ${NATIVE_BUILDER} \
    --builder-file azure/builder-native.json \
    --no-wait
```

You can inspect the buildpacks in each of the builders, e.g.

```bash
az spring build-service builder show -n ${DEFAULT_BUILDER}
az spring build-service builder show -n ${NATIVE_BUILDER}
```

Specifically, we are interested in these buildpacks:
* `tanzu-buildpacks/java-azure` in `default` builder
* `tanzu-buildpacks/java-native-image` in `native` builder

### Configure Dev Tools Portal

By default, an instance of Azure Spring Apps Enterprise does not have assigned public endpoint for
Dev Tools Portal (App Live View and App Accelerator).

You can assign endpoint either in Azure Portal GUI, or using Azure CLI:

```bash
az spring dev-tool update \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_APPS_SERVICE} \
    --assign-endpoint
```

You can check the public endpoint either in Azure Portal GUI, or using Azure CLI:

```bash
az spring dev-tool show --query properties.url --output tsv
```

or using `jq` utility to parse JSON output, instead of JMESPath `-query`:

```bash
az spring dev-tool show | jq -r '.properties.url'
```


> Next: [Unit 1 - Create an Azure Spring Apps application](../step-01-create-asa-app/README.md)
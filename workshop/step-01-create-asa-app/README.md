# Workshop Contents

* [Deploy Spring Native Application to Azure Spring Apps Enterprise](../README.md)
  * [Unit 0 - Prerequisites and Setup](../step-00-setup-your-environment/README.md)
  * [Unit 1 - Create an Azure Spring Apps application](../step-01-create-asa-app/README.md)
    * [Clone the Repository](../step-01-create-asa-app#clone-the-repository)
    * [Configure Environment Variables](../step-01-create-asa-app#configure-environment-variables)
    * [Login to Azure](../step-01-create-asa-app#login-to-azure)
    * [Configure Defaults](../step-01-create-asa-app#configure-defaults)
    * [Create Application Placeholders](../step-01-create-asa-app#create-application-placeholders)
  * [Unit 2 - Deploy an Azure Spring Apps application](../step-02-deploy-asa-app/README.md)
  * [Unit 3a - Bind to PostgreSQL Database](../step-03a-bind-to-postgresql-database/README.md)
  * [Unit 3b - Bind to MySQL Database](../step-03a-bind-to-mysql-database/README.md)
  * [Unit 4 - Measuring and Optimizing Usage](../step-04-measuring-and-optimizing-usage/README.md)
  * [Unit 5 - Run and Build App Locally](../step-05-run-and-build-app-locally/README.md)

# Unit 1 - Create an Azure Spring Apps application

In this module, we will clone the repository, configure the environment variables and create placeholders in Azure Spring Apps instance, for two versions of the Spring Petclinic application:
* Java application (e.g. `jar-app`)
* Native application (e.g. `native-app`)

## Clone the Repository

Check with the workshop instructor if this step has already been configured for you.

Please clone this repository in your shell (or Cloud Shell), e.g.

```shell
mkdir source-code
cd source-code
git clone https://github.com/Azure-Samples/spring-petclinic
cd spring-petclinic
```

## Configure Environment Variables

Check with the workshop instructor if this step has already been configured for you.

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

## Login to Azure

Login to the Azure CLI and choose your active subscription.

```shell
az login
az account list -o table
az account set --subscription ${SUBSCRIPTION}
```

## Configure Defaults

Set your default resource group name and cluster name using the following commands:

```shell
az configure --defaults \
    group=${RESOURCE_GROUP} \
    location=${REGION} \
    spring=${SPRING_APPS_SERVICE}
```

## Create Application Placeholders 

Create an application for each service:

```shell
az spring app create --name ${JAR_APP} --cpu 2 --memory 4Gi --assign-endpoint &
az spring app create --name ${NATIVE_APP} --cpu 2 --memory 4Gi --assign-endpoint &
wait
```

Feel free to observe the two applications (placeholders) created in Azure Portal GUI.

Similarly, you can check the applications (placeholders) configuration details using Azure CLI:

```shell
az spring app show --name ${JAR_APP}
az spring app show --name ${NATIVE_APP}
```

> Next: [Unit 2 - Deploy an Azure Spring Apps application](../step-02-deploy-asa-app/README.md)
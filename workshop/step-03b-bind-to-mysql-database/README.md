# Workshop Content

* [Deploy Spring Native Application to Azure Spring Apps Enterprise](../README.md)
  * [Unit 0 - Prerequisites and Setup](../step-00-setup-your-environment/README.md)
  * [Unit 1 - Create an Azure Spring Apps application](../step-01-create-asa-app/README.md)
  * [Unit 2 - Deploy an Azure Spring Apps application](../step-02-deploy-asa-app/README.md)
  * [Unit 3a - Bind to PostgreSQL Database](../step-03a-bind-to-postgresql-database/README.md)
  * [Unit 3b - Bind to MySQL Database](../step-03b-bind-to-mysql-database/README.md)
    * [Create MySQL Database](../step-03b-bind-to-mysql-database#create-mysql-database)
    * [Configure Application with MySQL Database](../step-03b-bind-to-mysql-database#configure-application-with-mysql-database)
    * [Create MySQL Service Connector for each Application](../step-03b-bind-to-mysql-database#create-service-connector-for-each-application)
    * [Deploy the Java application](../step-03b-bind-to-mysql-database#deploy-the-java-application)
    * [Deploy the Java Native Image application](../step-03b-bind-to-mysql-database#deploy-the-java-native-image-application)
    * [Observe the Log Stream for Applications](../step-03b-bind-to-mysql-database#observe-the-log-stream-for-applications)
  * [Unit 4 - Measuring and Optimizing Usage](../step-04-measuring-and-optimizing-usage/README.md)
  * [Unit 5 - Run and Build App Locally](../step-05-run-and-build-app-locally/README.md)

# Unit 3 - Bind to Database (MySQL)

In this module we can will connect to an existing SQL database (e.g. MySQL).
We will use a database connector in Azure Spring Apps for each of the apps.
We need to use a proper `application.properties` file when building a Java Native image.

## Create MySQL Database

Check with the workshop instructor if this step has already been pre-configured for you.

Create a MySQL database in Azure Database for MySQL.

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

## Configure Application with MySQL Database

> NOTE: By default, the source code is configured to use MySQL database. Spring applications can
dynamically load the application configuration based on the runtime, class loaders, environment
variables, etc.

In this module, we will use MySQL database that was pre-created for you (or you created in
previous step).

We will use the pre-configured `src/main/resources/application.properties` file, e.g.

```
# database init, supports mysql and postgresql too
# database=h2
database=mysql
spring.sql.init.schema-locations=classpath*:db/${database}/schema.sql
spring.sql.init.data-locations=classpath*:db/${database}/data.sql

# Web
spring.thymeleaf.mode=HTML

# JPA
spring.jpa.hibernate.ddl-auto=none
spring.jpa.open-in-view=true

# Internationalization
spring.messages.basename=messages/messages

# Actuator
management.endpoints.web.exposure.include=*

# Logging
logging.level.org.springframework=INFO
# logging.level.org.springframework.web=DEBUG
# logging.level.org.springframework.context.annotation=TRACE

# Maximum time static resources should be cached
spring.web.resources.cache.cachecontrol.max-age=12h

# SQL is written to be idempotent so this is safe
spring.sql.init.mode=always

# tomcat connection pool sizing
server.tomcat.threads.max=400
server.tomcat.accept-count=1000
server.tomcat.min-spare-threads=100
server.tomcat.max-connections=10000

# database connection pool sizing
spring.datasource.hikari.minimum-idle=10
spring.datasource.hikari.maximum-pool-size=400
```

Let's copy this file from the provided templates, e.g.

```shell
cp ./src/main/resources/copy-mysql.application.properties ./src/main/resources/application.properties
```

## Create Service Connector for each Application

In order to bind the external SQL database, we need to create a service connector for each app:

```shell
# Create MySQL service connector for Java app
az spring connection create mysql-flexible \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_APPS_SERVICE} \
    --connection ${MYSQL_DATABASE_CONNECTION_NAME} \
    --app ${JAR_APP} \
    --deployment default \
    --tg ${RESOURCE_GROUP} \
    --server ${MYSQL_SERVER_NAME} \
    --database ${MYSQL_DATABASE_NAME} \
    --secret name=${MYSQL_SERVER_ADMIN_NAME} secret=${MYSQL_SERVER_ADMIN_PASSWORD} \
    --client-type springboot

# Create MySQL service connector for Java Native Image app
az spring connection create mysql-flexible \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_APPS_SERVICE} \
    --connection ${MYSQL_DATABASE_CONNECTION_NAME} \
    --app ${NATIVE_APP} \
    --deployment default \
    --tg ${RESOURCE_GROUP} \
    --server ${MYSQL_SERVER_NAME} \
    --database ${MYSQL_DATABASE_NAME} \
    --secret name=${MYSQL_SERVER_ADMIN_NAME} secret=${MYSQL_SERVER_ADMIN_PASSWORD} \
    --client-type springboot 
```

## Deploy the Java application

As in previous module, we will re-deploy the application in the same manner, e.g.

```shell
# Deploy Petclinic app built as Java bytecode 
az spring app deploy --name ${JAR_APP} \
    --source-path . \
    --build-env BP_JVM_VERSION=17
```

## Deploy the Java Native Image application

Again, as in previous module, we will redeploy the application using the Azure CLI:

```shell
# Deploy Petclinic app built as Java Native Image
az spring app deploy --name ${NATIVE_APP} \
    --builder ${NATIVE_BUILDER} \
    --build-cpu 8 \
    --build-memory 16Gi \
    --source-path . \
    --build-env BP_JVM_VERSION=17 BP_NATIVE_IMAGE=true BP_MAVEN_BUILD_ARGUMENTS="-Dmaven.test.skip=true -Pnative package"
```

This will again take few minutes to complete.

## Observe the Log Stream for Applications

Again, as in previous module, we can observe the logs, e.g.

```shell
# Get log stream for the deployed Java app
az spring app logs -n ${JAR_APP} -f
```

```shell
# Get log stream for the deployed Java Native Image app
az spring app logs -n ${NATIVE_APP} -f
```

> Explore: Check that the PostgreSQL database is really being used by both applications, e.g.

```
HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@28878a52
HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@76e29807
```

> Explore: Check how long did it take for an application to start, e.g.

```
Started PetClinicApplication in 0.538 seconds (process running for 0.543)
```

> Next: [Unit 4 - Measuring and Optimizing Usage](../step-04-measuring-and-optimizing-usage/README.md)
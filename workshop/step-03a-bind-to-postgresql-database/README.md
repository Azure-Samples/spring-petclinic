# Workshop Content

* [Deploy Spring Native Application to Azure Spring Apps Enterprise](../README.md)
  * [Unit 0 - Prerequisites and Setup](../step-00-setup-your-environment/README.md)
  * [Unit 1 - Create an Azure Spring Apps application](../step-01-create-asa-app/README.md)
  * [Unit 2 - Deploy an Azure Spring Apps application](../step-02-deploy-asa-app/README.md)
  * [Unit 3a - Bind to PostgreSQL Database](../step-03a-bind-to-postgresql-database/README.md)
    * [Create PostgreSQL Database](../step-03a-bind-to-postgresql-database#create-postgresql-database)
    * [Configure Application with PostgreSQL Database](../step-03a-bind-to-postgresql-database#configure-application-with-postgresql-database)
    * [Create PostgreSQL Service Connector for each Application](../step-03a-bind-to-postgresql-database#create-service-connector-for-each-application)
    * [Deploy the Java application](../step-03a-bind-to-postgresql-database#deploy-the-java-application)
    * [Deploy the Java Native Image application](../step-03a-bind-to-postgresql-database#deploy-the-java-native-image-application)
    * [Observe the Log Stream for Applications](../step-03a-bind-to-postgresql-database#observe-the-log-stream-for-applications)
  * [Unit 3b - Bind to MySQL Database](../step-03b-bind-to-mysql-database/README.md)
  * [Unit 4 - Measuring and Optimizing Usage](../step-04-measuring-and-optimizing-usage/README.md)
  * [Unit 5 - Run and Build App Locally](../step-05-run-and-build-app-locally/README.md)

# Unit 3a - Bind to PostgreSQL Database

In this module we can will connect to an existing SQL database (e.g. PostgreSQL).
We will use a database connector in Azure Spring Apps for each of the apps.
We need to use a proper `application.properties` file when building a Java Native image.

## Create PostgreSQL Database

Check with the workshop instructor if this step has already been pre-configured for you.

Create a PostgreSQL database in Azure Database for PostgreSQL.

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

## Configure Application with PostgreSQL Database

> NOTE: By default, the source code is configured to use MySQL database. Spring applications can
dynamically load the application configuration based on the runtime, class loaders, environment
variables, etc.

In this module, we will use PostgreSQL database that was pre-created for you (or you created in
previous step).

We will use the pre-configured `src/main/resources/application.properties` file, e.g.

```
# database init, supports mysql and postgresql too
# database=h2
database=postgres
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
cp ./src/main/resources/copy-postgres.application.properties ./src/main/resources/application.properties
```

## Create Service Connector for each Application

In order to bind the external SQL database, we need to create a service connector for each app:

```shell
# Create PostgreSQL service connector for Java app
az spring connection create postgres-flexible \
    --resource-group $RESOURCE_GROUP \
    --service $SPRING_APPS_SERVICE \
    --app ${JAR_APP} \
    --target-resource-group $RESOURCE_GROUP \
    --server ${POSTGRESQL_SERVER_NAME} \
    --database ${POSTGRESQL_DATABASE_NAME} \
    --client-type springBoot \
    --connection ${POSTGRESQL_DATABASE_CONNECTION_NAME} \
    --secret name=${POSTGRESQL_SERVER_ADMIN_NAME} secret=${POSTGRESQL_SERVER_ADMIN_PASSWORD}

# Create PostgreSQL service connector for Java Native Image app
az spring connection create postgres-flexible \
    --resource-group $RESOURCE_GROUP \
    --service $SPRING_APPS_SERVICE \
    --app ${NATIVE_APP} \
    --target-resource-group $RESOURCE_GROUP \
    --server ${POSTGRESQL_SERVER_NAME} \
    --database ${POSTGRESQL_DATABASE_NAME} \
    --client-type springBoot \
    --connection ${POSTGRESQL_DATABASE_CONNECTION_NAME} \
    --secret name=${POSTGRESQL_SERVER_ADMIN_NAME} secret=${POSTGRESQL_SERVER_ADMIN_PASSWORD}
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
HikariPool-1 - Added connection org.postgresql.jdbc.PgConnection@43e2ce67
HikariPool-1 - Added connection org.postgresql.jdbc.PgConnection@11759e4a
```

> Explore: Check how long did it take for an application to start, e.g.

```
Started PetClinicApplication in 0.538 seconds (process running for 0.543)
```

> Next: [Unit 4 - Measuring and Optimizing Usage](../step-04-measuring-and-optimizing-usage/README.md)

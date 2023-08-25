# Workshop Content

* [Deploy Spring Native Application to Azure Spring Apps Enterprise](../README.md)
  * [Unit 0 - Prerequisites and Setup](../step-00-setup-your-environment/README.md)
  * [Unit 1 - Create an Azure Spring Apps application](../step-01-create-asa-app/README.md)
  * [Unit 2 - Deploy an Azure Spring Apps application](../step-02-deploy-asa-app/README.md)
    * [Configure Application with H2 Database](../step-02-deploy-asa-app/README.md#configure-application-with-h2-database)
    * [Configure Tanzu Build Service](../step-02-deploy-asa-app/README.md#configure-tanzu-build-service)
    * [Deploy the Java application](../step-02-deploy-asa-app/README.md#deploy-the-java-application)
    * [Deploy the Java Native Image application](../step-02-deploy-asa-app/README.md#deploy-the-java-native-image-application)
    * [Observe the Log Stream for Applications](../step-02-deploy-asa-app/README.md#observe-the-log-stream-for-applications)
    * [Observe the Application](../step-02-deploy-asa-app/README.md#observe-the-application)
  * [Unit 3a - Bind to PostgreSQL Database](../step-03a-bind-to-postgresql-database/README.md)
  * [Unit 3b - Bind to MySQL Database](../step-03b-bind-to-mysql-database/README.md)
  * [Unit 4 - Measuring and Optimizing Usage](../step-04-measuring-and-optimizing-usage/README.md)
  * [Unit 5 - Run and Build App Locally](../step-05-run-and-build-app-locally/README.md)

# Unit 2 - Deploy an Azure Spring Apps application

In this module we deploy the both versions of the app. We will use two different builders in 
Tanzu Build Service, one for each version of the application:
* Java Azure buildpack (e.g. `default`)
* Java Native Image buildpack (e.g. `native`)

## Configure Application with H2 Database

> NOTE: By default, the source code is configured to use MySQL database. Spring applications can
dynamically load the application configuration based on the runtime, class loaders, environment
variables, etc.

In this module, we will use H2 (in-memory) SQL database first, as it doesn't require any external
SQL databases.

We will use the pre-configured `src/main/resources/application.properties` file, e.g.

```
# database init, supports mysql and postgresql too
database=h2
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
```

Let's copy this file from the provided templates, e.g.

```shell
cp ./src/main/resources/copy-h2.application.properties ./src/main/resources/application.properties
```

## Configure Tanzu Build Service

Check with the workshop instructor if this step has already been configured for you.

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

## Deploy the Java application

Deploying Java applications to Azure Spring Apps Enterprise is very easy.

There are two different options to build and deploy a Java application:
* From source code
* Using packaged JAR application

We will use `default` builder with `tanzu-buildpacks/java-azure` buildpack to build
an application from source code.

Deploy the application using Azure CLI:

```shell
# Deploy Petclinic app built as Java bytecode 
az spring app deploy --name ${JAR_APP} \
    --source-path . \
    --build-env BP_JVM_VERSION=17
```

This will take few minutes to complete.

## Deploy the Java Native Image application

Deploying Java applications to Azure Spring Apps Enterprise, built as Java Native images, using
GraalVM in `Java Native Image` buildpack is very easy.

> Note: Downside of using Java Native Image builder is that the application is built statically,
so the building process takes a bit longer, and all dynamic references need to be known ahead of time.
Therefore, we have limited options when using dynamic features of Spring configuration.

> Note: We will need to rebuild and redeploy the application when using MySQL or PostgreSQL versions later
in this workshop.

Deploy the application using the Azure CLI:

```shell
# Deploy Petclinic app built as Java Native Image
az spring app deploy --name ${NATIVE_APP} \
    --builder ${NATIVE_BUILDER} \
    --build-cpu 8 \
    --build-memory 16Gi \
    --source-path . \
    --build-env BP_JVM_VERSION=17 BP_NATIVE_IMAGE=true BP_MAVEN_BUILD_ARGUMENTS="-Dmaven.test.skip=true -Pnative package"
```

This will take few minutes to complete.

## Observe the Log Stream for Applications

Use the following commands to get the latest 100 lines of app console logs from the deployed applications:

```shell
# Get log stream for the deployed Java app
az spring app logs -n ${JAR_APP} --lines 100
```

```shell
# Get log stream for the deployed Java Native Image app
az spring app logs -n ${NATIVE_APP} --lines 100
```

By adding a `-f` parameter you can get real-time log streaming from the app.
Try log streaming for the deployed applications.

```shell
# Get log stream for the deployed Java app
az spring app logs -n ${JAR_APP} -f
```

```shell
# Get log stream for the deployed Java Native Image app
az spring app logs -n ${NATIVE_APP} -f
```

You can use `az spring app logs -h` to explore more parameters and log stream functionalities.

> Explore: Try to find in the logs what database connection is being used, e.g.
```
HikariPool-1 - Added connection conn0: url=jdbc:h2:mem:b04a5693-1e75-4048-8191-5779de587734 user=SA
```

## Observe the Application

Feel free to explore Azure Portal GUI to find the application URLs.

You can also find the application URL using Azure CLI:

```shell
az spring app show -n ${JAR_APP} --query properties.url --output tsv
az spring app show -n ${NATIVE_APP} --query properties.url --output tsv
```

Alternatively, you can use `jq` utility to parse the JSON without the quotes, e.g.

```shell
az spring app show -n ${JAR_APP} -o JSON | jq -r '.properties.url'
az spring app show -n ${NATIVE_APP} -o JSON | jq -r '.properties.url'
```

> Next: [Unit 3a - Bind to PostgreSQL Database](../step-03a-bind-to-postgresql-database/README.md)

> Next: [Unit 3b - Bind to MySQL Database](../step-03b-bind-to-mysql-database/README.md)

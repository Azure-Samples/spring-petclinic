# Workshop Setup

This directory contains useful scripts that prepare the ASAE environment for the workshop.

## configure-workshop-environment.sh

### Description
  * configures the subscription with providers - SaaS, Platform and Insights
  * configures `az` CLI with extensions

### Usage

```bash
./workshop/setup/configure-workshop-environment.sh -n UNIQUE_NAME -s SUBSCRIPTION 
```

### Examples

```bash
./workshop/setup/configure-workshop-environment.sh \
  -n spring-native-01 \
  -s "aaaabbbb-cccc-dddd-eeee-ffffgggghhhh" \
```

```bash
./workshop/setup/configure-workshop-environment.sh \
  -n spring-native-01 \
  -s "spring-native-01 - Azure Pass" \
```

## create-workshop-environment.sh

### Description
  * configures the subscription with providers - SaaS, Platform and Insights;
  * creates a Resource Group
  * creates an Azure Spring Apps Enterprise instance with Build Service S7
  * creates a Log Analytics workspace
  * creates PostgreSQL flexible server instance with an empty database
  * creates MySQL flexible server instance with an empty database
  * writes the `setup-env-variables.sh` script that students can use.

### Usage

```bash
./workshop/setup/create-workshop-environment.sh -n UNIQUE_NAME -s SUBSCRIPTION -r REGION 
```

### Examples

```bash
./workshop/setup/create-workshop-environment.sh \
  -n spring-native-01 \
  -s "aaaabbbb-cccc-dddd-eeee-ffffgggghhhh" \
  -r eastus
```

```bash
./workshop/setup/create-workshop-environment.sh \
  -n spring-native-01 \
  -s "spring-native-01 - Azure Pass" \
  -r eastus
```


## stop-workshop-environment.sh

### Description
  * stops the ASAE instance
  * stops the PostgreSQL flexible server instance
  * stops the MySQL flexible server instance
  
### Usage

```bash
./workshop/setup/stop-workshop-environment.sh -n UNIQUE_NAME -s SUBSCRIPTION -r REGION 
```

### Examples

```bash
./workshop/setup/stop-workshop-environment.sh \
  -n spring-native-01 \
  -s "aaaabbbb-cccc-dddd-eeee-ffffgggghhhh" \
  -r eastus
```

```bash
./workshop/setup/stop-workshop-environment.sh \
  -n spring-native-01 \
  -s "spring-native-01 - Azure Pass" \
  -r eastus
```

## start-workshop-environment.sh

### Description
  * starts the ASAE instance
  * starts the PostgreSQL flexible server instance
  * starts the MySQL flexible server instance
  
### Usage

```bash
./workshop/setup/start-workshop-environment.sh -n UNIQUE_NAME -s SUBSCRIPTION -r REGION 
```

### Examples

```bash
./workshop/setup/start-workshop-environment.sh \
  -n spring-native-01 \
  -s "aaaabbbb-cccc-dddd-eeee-ffffgggghhhh" \
  -r eastus
```

```bash
./workshop/setup/start-workshop-environment.sh \
  -n spring-native-01 \
  -s "spring-native-01 - Azure Pass" \
  -r eastus
```

## check-workshop-environment-status.sh

### Description
  * checks the ASAE instance status
  * checks the PostgreSQL flexible server status
  * checks the MySQL flexible server status
  
### Usage

```bash
./workshop/setup/check-workshop-environment-status.sh -n UNIQUE_NAME -s SUBSCRIPTION -r REGION 
```

### Examples

```bash
./workshop/setup/check-workshop-environment-status.sh \
  -n spring-native-01 \
  -s "aaaabbbb-cccc-dddd-eeee-ffffgggghhhh" \
  -r eastus
```

```bash
./workshop/setup/check-workshop-environment-status.sh \
  -n spring-native-01 \
  -s "spring-native-01 - Azure Pass" \
  -r eastus
```

## Examples with multiple subscriptions

If you want to call these scripts for many subscriptions, you could use a `for`` loop, e.g.

```bash
for id in `seq -f "%02g" 1 30`
do
  UNIQUE_NAME="spring-native-${id}"
  SUBSCRIPTION="${UNIQUE_NAME} - Azure Pass"
  ./workshop/setup/stop-workshop-environment.sh -n "${UNIQUE_NAME}" -s "${SUBSCRIPTION}" -r eastus
done
```

```bash
for id in `seq -f "%02g" 1 30`
do
  UNIQUE_NAME="spring-native-${id}"
  SUBSCRIPTION="${UNIQUE_NAME} - Azure Pass"
  ./workshop/setup/start-workshop-environment.sh -n "${UNIQUE_NAME}" -s "${SUBSCRIPTION}" -r eastus
done
```

```bash
for id in `seq -f "%02g" 1 30`
do
  UNIQUE_NAME="spring-native-${id}"
  SUBSCRIPTION="${UNIQUE_NAME} - Azure Pass"
  ./workshop/setup/check-workshop-environment-status.sh -n "${UNIQUE_NAME}" -s "${SUBSCRIPTION}" -r eastus
done
```

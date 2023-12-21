# State management with outbox

## Sample info

| Attribute | Details |
|--------|--------|
| Dapr runtime version | v1.12.0 |
| Dapr .NET SDK | v1.12.0 |
| Language | C# |
| Environment | Local |

## Overview
In this sample, you'll run applications to demonstrate Dapr's state management outbox pattern. One application generates orders to save data in a state store which then *transactionally* sends pub/sub messages to a listening notification application. See [How-To: Enable the transactional outbox pattern](https://docs.dapr.io/developing-applications/building-blocks/state-management/howto-outbox/) to understand when this pattern is a good choice for your architecture.

> **Note:** This example leverages the Dapr client SDK.

This quickstart includes two applications: 
 - A .NET client application `order-processor` which creates orders, saves and deletes them to a state store.
 - A .NET notification application `order-notification` which receives pub/sub messages for topics from a message broker when the state store is updated.

## Run apps with multi-app run

You can run both applications using a [multi-app run template file](https://docs.dapr.io/developing-applications/local-development/multi-app-dapr-run/multi-app-overview/) with `dapr run -f .`

1. Open a new terminal window and run the `order-processor` and the `order-notification` apps using the multi app run template defined in [dapr.yaml](./dapr.yaml):

2. Run the applications:

  ```bash
    dapr run -f .
  ```
When orders are created and `saved` to the state store you see a corresponding notification message topic. 

```bash
== APP - order-processor == Saving Order: Order { orderId = 1 }
== APP - order-notification == Order notification received : {"orderId":1}
```
When orders are `deleted` you also see a corresponding notifications message.

```bash
== APP - order-processor == Deleting Order: Order { orderId = 2 }
== APP - order-notification == Order notification received : {"orderId":2}
```
3. Switch from Redis to MySQL

Redis is not a true transactional store, however it is easy to switch the underlying state store from Redis to MySQL. You can read about how to use the Dapr MySQL component [here](https://docs.dapr.io/reference/components-reference/supported-state-stores/setup-mysql/)
 - Install MySQL as a container image using the password `mysecret` for the root user.

 ```bash
 docker run --name mysql -d \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=mysecret \
    --restart unless-stopped \
    mysql:8
```
 - Change the `Program.cs` code in order-processor directory to use the `statestoresql` state store.
 
  ```bash
 string DAPR_STORE_NAME = "statestoresql";
 ```
 - Run the applications again with the `dapr run -f .` command

4. Stop and clean up the application processes either with CTRL+C command or running `dapr stop -f` . from another terminal window.

```bash
    dapr stop -f .
```

## Observing the messages
You can install a viewer for the messages and state store. For example if you are using Redis you can install the [Redis weijan.vscode-redis-client]( https://marketplace.visualstudio.com/items?itemName=cweijan.vscode-redis-client)
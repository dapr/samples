# State Management with Outbox

In this sample, you'll microservices to demonstrate Dapr's state management outbox. An application generates orders to save data in a state store which transactionally sends pub/sub messages to a listening notification application. See [How-To: Enable the transactional outbox pattern](https://docs.dapr.io/developing-applications/building-blocks/state-management/howto-outbox/) to understand when this pattern is a good choice for your architecture.

> **Note:** This example leverages the Dapr client SDK.

This quickstart includes two services: 
 - A .NET client application `order-processor` which creates orders, saves and deletes them to a state store.
 - A .NET notification application `order-notification` which receives pub/sub messages for topics when the state store is updated.

## Run apps with multi-app run

You can run both applications using a [multi-app run template file](https://docs.dapr.io/developing-applications/local-development/multi-app-dapr-run/multi-app-overview/) with `dapr run -f .`

1. Open a new terminal window and run  `order-processor` and the `order-notification` apps using the multi app run template defined in [dapr.yaml](./dapr.yaml):

2. Run the applications:

  ```bash
    dapr run -f .
  ```
When orders are created and `saved` to the state store you see a corresponding notifications message. 

```bash
== APP - order-processor == Saving Order: Order { orderId = 1 }
== APP - order-notification == Order notification received : {"orderId":1}
```
When orders are `deleted` you also see a corresponding notifications message.

```bash
== APP - order-processor == Deleting Order: Order { orderId = 2 }
Exited App successfully
== APP - order-notification == Order notification received : {"orderId":2}
```

3. Stop and clean up the application processes either with CTRL+C command or running `dapr stop -f` . from another terminal window.

```bash
    dapr stop -f .
```
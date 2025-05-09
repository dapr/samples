# Dapr Samples

>Note: The Dapr samples have been recently reorganized. Samples that are aimed for newcomers and are meant to help users get started quickly with Dapr have been migrated to a separate repository [dapr/quickstarts](https://github.com/dapr/quickstarts).

Samples in this repository showcase [Dapr](https://dapr.io/) capabilities using different languages and address wide array of common scenarios. Some focus on specific usage patterns or particular Dapr capability while others are end-to-end demos leveraging several Dapr building blocks and capabilities.

If you are new to Dapr, you may want to review following resources first:

* [Getting started with Dapr](https://docs.dapr.io/getting-started/)
* [Dapr overview](https://docs.dapr.io/concepts/overview/) 
* [Dapr quickstarts](https://github.com/dapr/quickstarts) - a collection of simple tutorials covering Dapr's main capabilities

> Note, these samples are maintained by the Dapr community and are not guaranteed to work properly with the latest Dapr runtime version.

## Samples in this repository

| Sample | Details |
|------|-------|
| [Twitter Sentiment Processor](./twitter-sentiment-processor) | Code sample used to demo Dapr during Microsoft's Build 2020 conference showing a polyglot distributed application which performs sentiment processing for tweets |
| [Hello world slim (no Docker dependency)](./hello-dapr-slim) | This sample is a version of the [hello-world](https://github.com/dapr/quickstarts/tree/master/hello-world) quickstart sample showing how to install initialize and use Dapr without having Docker in your local environment |
| [Hello TypeScript](./hello-typescript) | This sample is a version of the [hello-world](https://github.com/dapr/quickstarts/tree/master/hello-world) quickstart sample showing how to use Dapr in a TypeScript project. |
| [Docker compose sample](./hello-docker-compose) | Demonstrates how to get Dapr running locally with Docker Compose |
| [Dapr, Azure Functions, and KEDA](./functions-and-keda) | Shows Dapr being used with Azure Functions and KEDA to create a polygot Functions-as-a-Service application which leverages Dapr pub/sub |
| [Middleware OAuth to Google APIs - Interactive](./middleware-oauth-google) | Demonstrates use of Dapr middleware to enable OAuth 2.0 authorization and inject client secrets for Google APIs. |
| [Middleware OAuth to Microsoft and AAD APIs - Non Interactive](./middleware-oauth-microsoftazure) | Demonstrates use of Dapr middleware to enable OAuth 2.0 authorization and inject client secrets for Microsoft and Azure Active Directory apps.  |
| [Read Kubernetes Events](./read-kubernetes-events) | Shows Dapr being used with the Kubernetes Input binding to watch for events in Kubernetes cluster |
| [Batch File Processing](./batch-file-processing) | This sample demonstrates an end-to-end sample for processing a batch of related text files using microservices and Dapr. Through this sample you will learn about Dapr's state management, bindings, Pub/Sub, and end-to-end tracing. |
| [Dapr integration in Azure APIM](./dapr-apim-integration) | Dapr configuration in Azure API Management service using self-hosted gateway on Kubernetes. Illustrates exposing Dapr API for service method invocation, publishing content to a Pub/Sub topic, and binding invocation with request content transformation. |
| [Distributed Calendar](./dapr-distributed-calendar) | Shows use of statestore, pubsub and output binding features of Dapr to roughly create a distributed version of a MVCS architecture application. |
| [Hello Service Fabric](./hello-service-fabric) | Shows use of statestore, pubsub and service invocation in a Service Fabric environment running the Dapr sidecar as a guest executable. |
| [Pub-sub routing](./pub-sub-routing) | Demonstrates how to use Dapr to enable pub-sub applications with message routing.  |
| [Distributed Calculator with Knative Serving](./knative-distributed-calculator) | Demonstrates how to use Dapr and Knative Serving using distributed calculator from quickstarts.  |
| [commercetools GraphQL sample output binding](./commercetools-graphql-sample/) | Connects to commercetools, allowing you to query or manipulate a commercetools projects using a provided GraphlQL query.  |
| [WebAssembly Middleware](./hello-wasm) | Demonstrates how to serve HTTP responses directly from the dapr sidecar using WebAssembly.  |
| [Workflow + external endpoint invocation](./workflow-external-invocation) | Demonstrates how to use the Dapr Workflow API to coordinate an order process that includes an activity which uses service invocation for non-Dapr endpoints. |
| [Workflow + multi-app microservice in Python](./workflow-orderprocessing-python) | Demonstrates how to use the Dapr Workflow Python SDK to coordinate an order process across multiple dapr-enabled microservices. |
| [Outbox in .NET](./outbox) | Demonstrates how to use the outbox transactions with Redis and MySql statestores and Redis as the message broker |
| [Consuming Kafka messages without CloudEvents](./pubsub-raw-payload) | Demonstrates how to integrate a Kafka producer using the Confluent Kafka SDK with a Dapr-powered consumer in .NET applications |
| [AWS EKS Pod Identity](./dapr-eks-podidentity) | Demonstrates how to set up Dapr with AWS EKS Pod Identity for accessing AWS Secrets Manager |
| [GitOps with Argo CD and Dapr](./dapr-argocd) | Demonstrates how to install Dapr in a Kubenetes cluster using Argo CD |

## External samples

| Sample | Details |
|------|-------|
| [Dapr RetroPOS](https://github.com/robece/dapr-retropos) | Dapr Retro Point of Sales is a sample of backend workflow based on microservices. |
| [Dapr Traffic Control](https://github.com/edwinvw/dapr-traffic-control) | Simulated traffic-control system with speeding cameras. This sample features all the Dapr building-blocks. This is also the sample application used in the book [Dapr for .NET Developers](https://docs.microsoft.com/en-us/dotnet/architecture/dapr-for-net-developers/). |
| [Dapr Examples](https://github.com/mstrYoda/dapr-examples) | Example usage of Dapr in Golang. This repository contains examples about to use of state store, access management, pubsub and subscription.|
| [Java Pub/Sub Sample](https://github.com/Azure-Samples/pubsub-dapr-aks-java/tree/main) | Demonstrate a pub/sub messaging architecture using Dapr for a Java application running in a Kubernetes cluster. |
| [eShop on Dapr](https://github.com/dotnet-architecture/eShopOnDapr) | A sample .NET Core E-Commerce application based on [eShopOnContainers](https://github.com/dotnet-architecture/eShopOnContainers), powered by Dapr. |

## Sample maintenance

Each sample includes *README.md* which provides information about the validated versions of Dapr for that sample.

If you would like to have a sample updated or better yet, update it yourself to a newer version of Dapr, please see the [contribution guide](./CONTRIBUTING.md) to learn more about opening issues and submitting pull requests to this repository.

> Note, over time, for maintainability reasons, some samples may be removed from this repository.

## Sample contribution

If you want to contribute a sample to this repo, please see the sample [contribution guide](./CONTRIBUTING.md) for details on the PR process.

Samples should follow these high-level guiding principles:

* Sample should have a meaningful name that helps users understand what this sample is about
* Sample code should be complete (i.e. no major code additions should be needed to make the sample work)
* Each sample should include a *README.md* file clearly explaining what the sample does and how to run it including prerequisites. This file should also include details on the Dapr core version this sample is compatible with (see below).
* Highly recommended:
  * architecture diagrams of the sample application
  * scripts and automation to allow users to easily run samples which require complex setup and multiple steps to run

Along with the sample code and README, samples should be listed in this page in the above [samples table](#samples-in-this-repository)

Sample info section at the top of the main sample README should follow the following template:

| Attribute | Details |
|--------|--------|
| Dapr runtime version | vX.X |
| Language | [Languages used in the sample code] |
| Environment | [Environment name] |

>Note: If you are not sure what Dapr runtime version you are running, use the Dapr CLI command `dapr --version`

Example:

| Attribute | Details |
|--------|--------|
| Dapr runtime version | v1.12.0 |
| Language | Go, C# (.NET Core), Node.js |
| Environment | Local or Kubernetes |

## Code of Conduct

Please refer to our [Dapr Community Code of Conduct](https://github.com/dapr/community/blob/master/CODE-OF-CONDUCT.md)

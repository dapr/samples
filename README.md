# Dapr Samples

>Note: The Dapr samples have been recently reorganized. Samples that are aimed for newcomers and are meant to help users get started quickly with Dapr have been migrated to a separate repository [dapr/quickstarts](https://github.com/dapr/quickstarts). 

Samples in this repository showcase [Dapr](https://dapr.io/) capabilities using different languages and address wide array of common scenarios. Some focus on specific usage patterns or particular Dapr capability while others are end-to-end demos leveraging several Dapr building blocks and capabilities.

If you are new to Dapr, you may want to review following resources first:

* [Getting started with Dapr](https://github.com/dapr/docs/blob/master/getting-started/README.md)
* [Dapr overview](https://github.com/dapr/docs/blob/master/overview/README.md) 
* [Dapr quickstarts](https://github.com/dapr/quickstarts) - a collection of simple tutorials covering Dapr's main capabilities

> Note, these samples are maintained by the Dapr community and are not guaranteed to work properly with the latest Dapr runtime version. 

## Samples in this repository

| Sample | Details | 
|------|-------|
| [Twitter Sentiment Processor](./twitter-sentiment-processor) | Code sample used to demo Dapr during Micorosft's Build 2020 conference showing a polyglot distributed application which performs sentiment processing for tweets |
| [Hello world slim (no Docker dependency)](./hello-dapr-slim) | This sample is a version of the [hello-world](https://github.com/dapr/quickstarts/tree/master/hello-world) quickstart sample showing how to install initialize and use Dapr without having Docker in your local environment |
| [Docker compose sample](./hello-docker-compose) | Demonstrates how to get Dapr running locally with Docker Compose |
| [Dapr, Azure Functions, and KEDA](./functions-and-keda) | Shows Dapr being used with Azure Functions and KEDA to create a polygot Functions-as-a-Service application which leverages Dapr pub/sub |
| [OAuth Authorization to external service](./middleware-clientcredentials) | Demonstrates how to inject a service principal OAuth Bearer Token within a Dapr service-to-service invocation to call secured APIs |
| [Read Kubernetes Events](./read-kubernetes-events) | Shows Dapr being used with the Kubernetes Input binding to watch for events in Kubernetes cluster |

## External samples

>This section will include external links to Dapr related samples, located outside the Dapr Samples repository.

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
| Dapr runtime version | v0.7.1 |
| Language | Go, C# (.NET Core), Node.js | 
| Environment | Local or Kubernetes |


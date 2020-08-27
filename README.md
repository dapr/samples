# Dapr Samples

>Note: The Dapr samples have been recently reorganized. Samples that are aimed for newcomers and are meant to help users get started quickly with Dapr have been migrated to a separate repository [dapr/quickstarts](https://github.com/dapr/quickstarts). Please see that repository for any samples that were previously found under the Samples repository.

This repository contains code samples that show the usage of [Dapr](https://dapr.io/) capabilities. Different samples in this repository may use different languages and show Dapr as it may be used in different environments and scenarios. Some of these samples may be small applications that show a very specific usage of a single Dapr capability and some may show how a distributed application with multiple services may leverage several Dapr building blocks and capabilities.

This repository is meant to be used for code reference and is maintained for and by the Dapr community. Please see below for details on [sample maintenance approach](#sample-maintenance) and on how to [contribute a new sample](#sample-contribution) 

## Get started

This repo has a variety of different sample code, if you are new to Dapr it is recommended you review the following useful resources first:
- [Getting started with Dapr](https://github.com/dapr/docs/blob/master/getting-started/README.md)
- [Dapr overview](https://github.com/dapr/docs/blob/master/overview/README.md) article in the [Dapr docs](https://github.com/dapr/docs)
- [Dapr quickstarts](https://github.com/dapr/quickstarts) - a collection of simple tutorials with sample code that demonstrate the main Dapr capabilities

## Samples in this repository

| Sample | Details | 
|------|-------|
| [Twitter Sentiment Processor](./twitter-sentiment-processor) | Code sample used to demo Dapr during Micorosft's Build 2020 conference showing a polyglot distributed application which performs sentiment processing for tweets |
| [Hello world slim (no Docker dependency)](./hello-dapr-slim) | This sample is a version of the [hello-world](https://github.com/dapr/quickstarts/tree/master/hello-world) quickstart sample showing how to install initialize and use Dapr without having Docker in your local environment |
| [Docker compose sample](./hello-docker-compose) | Demonstrates how to get Dapr running locally with Docker Compose |
| [Dapr, Azure Functions, and KEDA](./functions-and-keda) | Shows Dapr being used with Azure Functions and KEDA to create a polygot Functions-as-a-Service application which leverages Dapr pub/sub |
| [Batch File Processing](./batch-file-processing) | This sample demonstrates an end-to-end sample for processing a batch of related text files using microservices and Dapr. Through this sample you will learn about Dapr's state management, bindings, Pub/Sub, and end-to-end tracing. |

## Sample maintenance

Samples in this repository are maintained by the Dapr community and are not guaranteed to work properly with the latest Dapr runtime version. Each sample had a *README.md* file which provides details about the sample code including what is the most recent Dapr version it has been validated with.

If you would like to have a sample updated or better yet, update it yourself to a newer version of Dapr, please see the [contribution guide](./CONTRIBUTING.md) to learn more about opening issues and submitting pull requests to this repository.

Some samples, overtime, may be retired and removed from this repository if the community feels they are no longer relevant or provide value to Dapr developers.

## Sample contribution

If you want to contribute a sample to this repo, please see the sample [contribution guide](./CONTRIBUTING.md) for details on the PR process.

Samples should follow these high-level guiding principles:
- Samples should have a meaningful name that helps users of this repository understand what this sample is about
- Sample code should be complete (i.e. no major code additions should be needed to make the sample work)
- Each sample should include a *README.md* file clearly explaining what the sample does and how to run it including prerequisites. This file should also include details on the Dapr core version this sample is compatible with (see below). Highly recommended to include architecture diagrams of the sample application in the README file
- It is highly recommended to include scripts and automation to allow users to easily run samples which require complex setup and multiple steps to run
- Along with the sample code and README, samples should be listed in this page in the above [samples table](#samples-in-this-repository)

Sample info section at the top of the main sample README should follow the following template
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

## External samples

>This section will include external links to Dapr related samples, located outside the Dapr GitHub repositories.

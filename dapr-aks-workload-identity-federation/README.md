# Dapr with Azure Workload Identity and Azure Key Vault

## Sample info

| Attribute | Details |
|--------|--------|
| Dapr runtime version | 1.15.0 |
| Dapr Workflow dotnet SDK | 1.15.0 |
| Language | csharp |
| Environment | Local |

This directory contains a sample application which can be used in combination with the 
official Dapr documentation for [workload identity federation on Azure](https://docs.dapr.io/developing-applications/integrations/azure/azure-authentication/howto-wif/).

The application code uses the [Dapr secrets building block](https://docs.dapr.io/developing-applications/building-blocks/secrets/secrets-overview/)
to access a secret called `"dapr"` stored in the Azure Key Vault.

## Building the sample application

### Prerequisites

 - The dotnet SDK
 - A compatible container build tool like [Docker](https://www.docker.com/) or [Podman](https://podman.io/)

The sample [can be built as a container](https://learn.microsoft.com/dotnet/core/containers/overview?tabs=linux) by running the following command in the `app` directory:

```bash
dotnet publish /t:PublishContainer -c Release
```

Once built, the image will be available on your machine as `dapraksworkloadidentityfederation`.
You then can re-tag the image and push it up to a registry your AKS cluster has visibility to:

```bash
docker tag dapraksworkloadidentityfederation <your-container-registry>.azurecr.io/dapraksworkloadidentityfederation
docker push <your-container-registry>.azurecr.io/dapraksworkloadidentityfederation
```
Note: your container tag and registry will vary based on your setup.

## Running the sample application

If you'd like to try running the sample application, you can use the deployment manifest for this sample as a starting point, or read the 
[official guide](https://docs.dapr.io/developing-applications/integrations/azure/azure-authentication/howto-wif/) for additional steps on how to configure your AKS cluster.

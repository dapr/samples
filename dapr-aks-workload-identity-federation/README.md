# Dapr with Azure AKS Pod Identity and Azure Key Vault

This directory contains a sample application which can be used in combination with the 
official dapr documentation for [workload identity federation on Azure](https://docs.dapr.io/developing-applications/integrations/azure/azure-authentication/howto-wif/).

The application code uses the [dapr secrets building block](https://docs.dapr.io/developing-applications/building-blocks/secrets/secrets-overview/)
to access a secret called `"dapr"`.  

## Building the sample application

The sample can be built as a container by running the following command in the `app` directory:

```bash
dotnet publish --os linux --arch x64 /t:PublishContainer -c Release
```

Once built, the image will be available on your machine as `dapraksworkloadidentityfederation`.
You then can re-tag the image and push it up to a registry your AKS cluster has visibility to:

```bash
docker tag dapraksworkloadidentityfederation your-container-registry.azurecr.io/dapraksworkloadidentityfederation
docker push your-container-registry.azurecr.io/dapraksworkloadidentityfederation
```
(your container tag and registry will vary based on your setup)

## Running the sample application

If you'd like to try running the sample application, you can use the deployment manifest for this sample as a starting point, or head over to
[our official guide](https://docs.dapr.io/developing-applications/integrations/azure/azure-authentication/howto-wif/) for additional steps on how to configure your AKS cluster.

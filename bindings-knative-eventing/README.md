# Distributed calculator using Knative Serving

| Attribute               | Details                    |
| ----------------------- | -------------------------- |
| Dapr runtime version    | v1.5.0                     |
| Knative Serving version | v1.0                       |
| Language                | Javascript, Python, Go, C# |
| Environment             | Kubernetes                 |

This is a distrubuted calculator application from [Dapr quickstart](https://github.com/dapr/quickstarts/tree/master/distributed-calculator) using Knative Serving (with Kourier) to host React Calculator. This is build as proof-of-concept to show how to use Knative Serving with Dapr.

## Contents

## Prerequisites

This sample requires you to have the following installed on your machine:

- [Dapr CLI](https://github.com/dapr/cli/tree/release-1.5) v1.5.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- An online hoster Kubernetes cluster, such as [AKS](https://docs.dapr.io/operations/hosting/kubernetes/cluster/setup-aks/) or [GKE](https://cloud.google.com/kubernetes-engine/)

Also, unless you have already done so, clone the repository with the samples and `cd` into the right directory:

```bash
git clone https://github.com/dapr/samples.git
cd samples/bindings-knative-eventing
```

## Step 1 - Make sure that your kubectl client is working

The first thing you need is an enabled Kubernetes cluster. This sample was tested on fully-fledged cluster.

Once you have that make sure you get a positive response from the following kubectl command

```bash
kubectl get pods
```

This should either have output as `No resources found in default namespace.` or should list the pods running the `default` namesapce.

## Step 2 - Setup Dapr

Follow [instructions](https://docs.dapr.io/getting-started/install-dapr/) to download and install the Dapr CLI and initialize Dapr.

## Step 3 - Setup Knative Serving and Eventing

> **Note**: Here you can find full [instruction](https://knative.dev/docs/install/serving/install-serving-with-yaml/) of how to install and configure Knative Serving. All the information below in steps 3 and 4 is an excerpt from it which was used and tested.

### Install Knative Serving CRDs

```bash
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-crds.yaml
```

### Install Knative Serving Core

```bash
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.0.0/serving-core.yaml
```

### Install Knative Kourier - networking layer

```bash
kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.0.0/kourier.yaml
```

### Configure Knative to use Kourier

```bash
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'
```

### Verify installation

```bash
kubectl get pods -n knative-serving
```

All pods inside `knative-serving` namespace should have `Running` or `Completed` status.

## Step 3 - Configure DNS for Knative

### Fetch the External IP address by running the command

```bash
kubectl --namespace kourier-system get service kourier
```

### Configure DNS

This sample was tested with real DNS. In this case, you need to take External IP address from previous step and add to your DNS wildcard `A` record (e.g. `*.knative.example.com`).

### Direct Knative to use that domain

Please change `knative.example.com` below to your domain.

```bash
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"knative.example.com":""}}'
```

### Install Knative Eventing CRDs

```bash
kubectl apply -f kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.0.0/eventing-crds.yaml
```

### Install Knative Eventing Core

```bash
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.0.0/eventing-core.yaml
```

### Install Knative Extention - Kafka Source

```bash
kubectl apply -f https://github.com/knative-sandbox/eventing-kafka/releases/download/knative-v1.0.0/source.yaml
```

## Step 4 - Setup Distributed Calculator

### Install Kafka cluster

As a part of this sample I'm using Strimzi to create and install Kafka cluster. Here is the [instruction](https://strimzi.io/quickstarts/) of how to do that.

Here is a quick excerpt from it:

### Create namespace for Kafka

```bash
kubectl create namespace kafka
```

### Apply all installation files (this will also create Strimzi operator)

```bash
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
```

### Wait until Strimzi operator is up and running

```bash
kubectl get pod -n kafka
```

### Create new Kafka cluster

```bash
kubectl apply -f https://strimzi.io/examples/latest/kafka/kafka-persistent-single.yaml -n kafka
```

### Wait until Kafka cluster is up and running

```bash
kubectl wait kafka/my-cluster --for=condition=Ready --timeout=300s -n kafka
```

## Step 5 - Setup Sample

### Apply Knative part

```bash
kubectl apply -f knative/.
```

### Apply Dapr part

```bash
kubectl apply -f dapr/.
```

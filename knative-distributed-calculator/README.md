# Distributed calculator using Knative Serving

| Attribute               | Details                    |
| ----------------------- | -------------------------- |
| Dapr runtime version    | v1.5.0                     |
| Knative Serving version | v1.0                       |
| Language                | Javascript, Python, Go, C# |
| Environment             | Kubernetes > v1.20         |

This is a distributed calculator application from [Dapr quickstart](https://github.com/dapr/quickstarts/tree/master/distributed-calculator) using Knative Serving (with Kourier) to host React Calculator. This is built as a proof-of-concept to show how to use Knative Serving with Dapr.

## Prerequisites

This sample requires you to have the following installed on your machine:

- [Dapr CLI](https://github.com/dapr/cli/tree/release-1.5) v1.5.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- An online hoster Kubernetes cluster, such as [AKS](https://docs.dapr.io/operations/hosting/kubernetes/cluster/setup-aks/) or [GKE](https://cloud.google.com/kubernetes-engine/)

Also, unless you have already done so, clone the repository with the samples and `cd` into the right directory:

```bash
git clone https://github.com/dapr/samples.git
cd samples/knative-distributed-calculator
```

## Step 1 - Make sure that your kubectl client is working

The first thing you need is an enabled Kubernetes cluster. This sample was tested on a fully-fledged cluster.

Once you have that make sure you get a positive response from the following kubectl command

```bash
kubectl get pods
```

This should either have output as `No resources found in default namespace.` or should list the pods running the `default` namespace.

## Step 2 - Setup Dapr

Follow [instructions](https://docs.dapr.io/getting-started/install-dapr/) to download and install the Dapr CLI and initialize Dapr.

## Step 3 - Setup Knative Serving

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

This sample was tested with real DNS. In this case, you need to take the External IP address from the previous step and add it to your DNS wildcard `A` record (e.g. `*.knative.example.com`).

### Direct Knative to use that domain

Please change `knative.example.com` below to your domain.

```bash
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"knative.example.com":""}}'
```

## Step 4 - Setup Distributed Calculator

### Install Redis store

Follow [these instructions](https://docs.dapr.io/getting-started/configure-state-pubsub/) to create and configure a Redis store.

Here is a quick excerpt from it using Helm:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install redis bitnami/redis
```

### Install Distributed Calculator

Navigate to the deploy directory in this quickstart directory:

```bash
cd deploy
```

Deploy all of your resources:

```bash
kubectl apply -f .
```

> **Note**: This is the same Distributed Calculator from [quickstart](https://github.com/dapr/quickstarts/tree/release-1.5/distributed-calculator) except for the React deployment.

### Verification

Get URL for your React application:

```bash
kubectl get service.serving
```

Example output:

```bash
NAME                   URL                                                        LATESTCREATED               LATESTREADY                 READY   REASON
calculator-front-end   http://calculator-front-end.default.knative.example.com    calculator-front-end-rev1   calculator-front-end-rev1   True
```

Make sure that `READY` is set to `True`. Otherwise, please wait until all the necessary components are configured by Knative. The address, in this case, is `http://calculator-front-end.default.knative.example.com`.

Navigate to this address with your browser and you should see the distributed calculator. Do some calculations to make sure that all works as expected.

### Behind the scene

By default, Knative will scale to zero its workloads if there is no traffic to them. Wait for a couple of minutes and run the next command to list all pods in `default` namespace:

```bash
kubectl get pods
```

Example output:

```bash
NAME                           READY   STATUS    RESTARTS   AGE
addapp-86cfcb8969-mvzs8        2/2     Running   0          2d23h
divideapp-6b94b477f5-58n92     2/2     Running   0          2d23h
multiplyapp-545c4bc54d-n6vrd   2/2     Running   0          2d23h
redis-master-0                 1/1     Running   0          2d23h
redis-replicas-0               1/1     Running   0          2d23h
redis-replicas-1               1/1     Running   0          2d23h
redis-replicas-2               1/1     Running   0          2d23h
subtractapp-5c6c6bc4fc-wlbqv   2/2     Running   0          2d23h
```

As you can see, there are no `calculator-front-end` pods.

Navigate back to the address with your browser to generate some traffic.

Return back to and list all pods once again:

```bash
NAME                                                    READY   STATUS    RESTARTS   AGE
addapp-86cfcb8969-mvzs8                                 2/2     Running   0          2d23h
calculator-front-end-rev1-deployment-6fd89f78df-6ttr2   3/3     Running   0          6s
divideapp-6b94b477f5-58n92                              2/2     Running   0          2d23h
multiplyapp-545c4bc54d-n6vrd                            2/2     Running   0          2d23h
redis-master-0                                          1/1     Running   0          2d23h
redis-replicas-0                                        1/1     Running   0          2d23h
redis-replicas-1                                        1/1     Running   0          2d23h
redis-replicas-2                                        1/1     Running   0          2d23h
subtractapp-5c6c6bc4fc-wlbqv                            2/2     Running   0          2d23h
```

As you can see there is `calculator-front-end-rev1-deployment-6fd89f78df-6ttr2` pod with 3 containers running inside: `calculator-front-end`, `queue-proxy` and `daprd`.

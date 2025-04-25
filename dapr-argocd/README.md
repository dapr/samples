# Dapr + Argo CD Example

This repository demonstrates how to deploy Dapr and Redis using Argo CD, along with a sample application that uses Dapr's State Management building block with Redis.

## Repository Structure

- `/gitops`: Contains all Argo CD, Dapr, and Redis configuration files
- `/app`: Contains the sample node and python applications

## Prerequisites

- Kubernetes cluster (v1.21+ recommended)
- kubectl configured to access your cluster
- Helm v3
- Git

## 1: Fork and clone this this repository

## 2: Install Argo CD

First, you need to install Argo CD on your Kubernetes cluster:

```bash
# Create a namespace for Argo CD
kubectl create namespace argocd

# Apply the Argo CD installation manifest
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Then, install the Argo CD cli:

```bash
brew install argocd
```

After installation, access the Argo CD UI:

```bash
# Port-forward to the Argo CD server
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Get the initial admin password:

```bash
argocd admin initial-password -n argocd
```

Using the username `admin` and the password from above, login to Argo CD's IP or hostname (on our case, we are running it on `localhost:8080`):

```bash
argocd login localhost:8080
```

You can also access the UI by navigating to `https://localhost:8080` in your browser.

For a detailed step-by-step process on how to install Argo CD, follow the [official documentation](https://argo-cd.readthedocs.io/en/stable/getting_started/).

## 3: Install Dapr Using the Argo CD CLI

An Argo CD application is a custom Kubernetes resource that defines how an application should be deployed and managed using the GitOps methodology. It specifies the source configuration (usually a Git repository, Helm chart, or directory path), the destination cluster and namespace, sync policies for automation, and special synchronization options. This resource acts as the bridge connecting your desired state (defined in Git) with the actual state in your Kubernetes cluster.

When deployed, Argo CD continuously monitors both your Git repository and Kubernetes cluster to ensure they remain synchronized. Any deviation triggers either an alert or an automatic reconciliation based on your configuration. The application can be created and managed through Argo CD's web UI, CLI commands, YAML manifests, or API calls, making it a flexible foundation for implementing continuous delivery in Kubernetes environments.

Here, the Argo CD CLI is used to create the application for our Dapr deployment:

```bash
argocd app create dapr \
  --repo https://github.com/<your-username>/dapr-argocd.git \
  --path gitops/dapr \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dapr-system
```

Sync the application and verify the installation:

```bash
argocd app sync dapr
argocd app get dapr
kubectl get pods -n dapr-system
```

## 4: Install Redis Using Argo CD

Create an Argo CD application for Redis:

```bash
argocd app create redis \
  --repo https://github.com/<your-username>/dapr-argocd.git \
  --path gitops/redis \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace redis
```

Sync the application and verify the installation:

```bash
argocd app sync redis
argocd app get redis
kubectl get pods -n redis
```

## 5: Configure Dapr Components

Create the namespace:

```bash
kubectl create namespace argocd-demo
```

Create the Dapr state store component application:

```bash
argocd app create dapr-components \
  --repo https://github.com/<your-username>/dapr-argocd.git \
  --path gitops/dapr-components \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd-demo
```

Sync the application:

```bash
argocd app sync dapr-components
argocd app get dapr-components
```

## 6: Deploy the Sample Application

Deploy the `node` and `python` applications:

```bash
# Node app
argocd app create node \
  --repo https://github.com/<your-username>/dapr-argocd.git \
  --path app/node \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd-demo

# Python app
argocd app create python \
  --repo https://github.com/<your-username>/dapr-argocd.git \
  --path app/python \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd-demo
```

This will deploy both the node and python services in the `argocd-demo` namespace.

Verify the deployments:

```bash
kubectl get pods -n argocd-demo
```

You should see both pods running with their Dapr sidecars.

```bash
nodeapp-7578bfc4dd-chs7x     2/2     Running   0          29m
pythonapp-587fb8f7db-s55k6   2/2     Running   0          22m
```

## 7: Verify the Communication

First, run port-forward to access the node service:

```bash
kubectl port-forward service/nodeapp 8081:80 -n argocd-demo
```

This will make your service available on `http://localhost:8081`.

In a new terminal run:

```bash
curl -d '{"data":{"orderId":"42"}}' -H "Content-Type:application/json" -X POST http://localhost:8081/neworder
```

Expected output:

```bash
{ "orderId": "42" }
```

# Read Kubernetes events 

This tutorial will show an example of running Dapr with a Kubernetes events input binding. You'll be deploying the [Node](./node) application and will require a component definition with a Kubernetes event binding [component](./deploy/kubernetes.yaml). 

## Sample info
| Attribute | Details |
|--------|--------|
| Dapr runtime version | v0.10.0 |
| Language | Node.js | 
| Environment | Local or Kubernetes |


## Prerequisites
This sample requires you to have the following installed on your machine:
- [Docker](https://docs.docker.com/get-docker/)
- [Dapr](https://github.com/dapr/cli/tree/release-0.10) v0.10.0+
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- A Kubernetes cluster, such as [Minikube](https://docs.dapr.io/operations/hosting/kubernetes/cluster/setup-minikube/), [AKS](https://docs.dapr.io/operations/hosting/kubernetes/cluster/setup-aks/) or [GKE](https://cloud.google.com/kubernetes-engine/)

Also, unless you have already done so, clone the repository with the samples and ````cd```` into the right directory:
```
git clone https://github.com/dapr/samples.git
cd samples/read-kubernetes-events
```
  
## Step 1 - Make sure that your kubectl client is working

The first thing you need is an RBAC enabled Kubernetes cluster. This could be running on your machine using Minikube, or it could be a fully-fledged cluser in Azure using [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/). 

Once you have that make sure you get a positive response from the following kubectl command

```
kubectl get pods
```

This should either have output as `No resources found in default namespace.` or should list the pods running the `default` namesapce.

## Step 2 - Running the code locally

1. Setup Dapr 

Follow [instructions](https://docs.dapr.io/getting-started/install-dapr/) to download and install the Dapr CLI and initialize Dapr.

2. Understand the code

Now that Dapr is set up locally, navigate to the Read Kubernetes Events sample:

```bash
cd node
```

In the `app.js` you'll find a simple `express` application, which exposes a single route and handler. First, take a look at the top of the file: 

```js
const express = require('express');
const bodyParser = require('body-parser');
require('isomorphic-fetch');
const app = express();
app.use(bodyParser.json());
const port = 3000;
```

The port defined here is the default port the node app runs on. 

Next, take a look at the ```kube-events``` handler:

```js
app.post('/kube-events', (req, res) => {
    console.log("Hello from Kube Events!");
    console.log(req.body);
    res.status(200).send();
});
```

This simple gets the request, prints a log line and the request body in the console. 

3. Understand the component definition:

```bash
cd ../deploy/
```

The `kubernetes.yaml` file defines the component that Dapr has to register with the particular configuration. The binding spec can be seen [here](https://docs.dapr.io/operations/components/setup-bindings/supported-bindings/kubernetes-binding/).

```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: kube-events
  namespace: kube-events
spec:
  type: bindings.kubernetes
  metadata:
  - name: namespace
    value: kube-events
  - name: resyncPreiodInSec
    value: "5"
```

This registers a `bindings.kubernetes` component with the name `kube-events` (which is also the route for the post request) and defines the namespace to watch `kube-events` and the period to resync with the server `5`s.

4. Run the code locally 

The sample uses default kubectl config from the local machine and does not need Dapr or the application to be deployed in Kubernetes. This is simply to illustrate that functionality of the Kubernetes events input binding. 

* Navigate to Node subscriber directory in your CLI: 
    ```bash
      cd ./node
    ```
* Install dependencies:
    ```bash
      npm install
    ```
* Run Node sample app with Dapr: 
    ```bash
      dapr run --app-id bindings-kevents-nodeapp --app-port 3000 node app.js --components-path ../deploy
    ```
You should see the output:

```
ℹ️  Updating metadata for app command: node app.js
✅  You're up and running! Both Dapr and your app logs will appear here.
```
5. Create a few Kubernetes Events to view through the application

The application is watching the namespace `kube-events`. If it is already present in your kubernetes cluster you might be seeing some events already. If not follow the steps below. 

* Create namespace `kube-events` if not present:

```bash
kubectl create ns kube-events
```

* Deploy a quick Kubernetes hello-world application in the created namespace:

```bash
kubectl create deployment hello-node -n kube-events --image=k8s.gcr.io/echoserver:1.4
```

Output logs from the node application should be of the form:

```
== APP == Hello from Kube Events!

== APP == {

== APP ==   event: 'add',

== APP ==   oldVal: {

== APP ==     metadata: { creationTimestamp: null },

== APP ==     involvedObject: {},
              ...
== APP ==   },

== APP ==   newVal: {

== APP ==     metadata: {

== APP ==       name: 'hello-node.162c269e7cedc889',

== APP ==       namespace: 'kube-events',

== APP ==       selfLink: '/api/v1/namespaces/kube-events/events/hello-node.162c269e7cedc889',
                ...
== APP ==   }

== APP == }
```

> Note that the event is categorized as an `add` event. There are three types of events that the binding monitors `add`, `delete` and `update` events.

* Delete the deployment just created:

```bash
kubectl delete deployment hello-node -n kube-events
```

Output should be 

```
== APP == Hello from Kube Events!
== APP == {
== APP ==   event: 'delete',
== APP ==   oldVal: {
== APP ==     metadata: {
== APP ==       name: 'hello-node.162c2661c524d095',
== APP ==       namespace: 'kube-events',
== APP ==       selfLink: '/api/v1/namespaces/kube-events/events/hello-node.162c2661c524d095',
                ...
== APP ==   }
== APP == }
```

> Note that the event is categorized as a `delete` event.

* Delete namepace (if it was created for this sample):

```bash
kubectl delete ns kube-events
```

## Step 3 - Running in a Kubernetes cluster

### Prerequisites 
Apart from the previous requisites the following are needed.
1. Need a shell capable of running make for building and pushing container to Docker Hub repo.
2. `makefile` also uses `sed` command for editing file on the fly.
3. [Docker Hub](https://hub.docker.com) account.

1. You will be using the same app that was used in Step 2 to test locally. For running the application in Kubernetes, a container is needed. 
2. Once the repo has been cloned, change to the read-kubernetes-events directory
```bash
cd read-kubernetes-events
```
3. Set the environment variable DOCKER_REPO to your docker hub username
```bash
export DOCKER_REPO=<REPO>
```
4. Build the application container
```bash
make build
```

The output should be of the form 
```
docker build -f node/Dockerfile node/. -t docker.io/<REPO>/k8s-events-node:edge
...
Successfully built 908b65d9d01f
Successfully tagged <REPO>/k8s-events-node:edge
```
5. Push the container to your docker hub repository
```bash
make push
```
> Note: you might need to login to your docker hub repo. [Docker Hub quickstart](https://docs.docker.com/docker-hub/)

6. Create namespace `kube-events` if not present:

```bash
kubectl create ns kube-events
```
7. Apply the kubernetes configuration to your cluster using the kubectl command. 
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: kube-events
  namespace: kube-events
spec:
  type: bindings.kubernetes
  metadata:
  - name: namespace
    value: kube-events
  - name: resyncPreiodInSec
    value: "5"
```
```bash
kubectl apply -f ./deploy/kubernetes.yaml
```

8. View the `./deploy/node.yaml` file. It does the following 
* Creates a role called `events-reader` with permission to `get, list and watch` `events` resource. More details can be found [here](https://docs.dapr.io/operations/components/setup-bindings/supported-bindings/kubernetes-binding/).
* Creates a role binding called `read-events` which binds default ServiceAccount in `kube-events` namespace to the Role previously created.
* Create a service called `events-nodeapp`.
* Creates a deployment called `events-nodeapp` with reference to be container created and pushed in steps 4 and 5.

The container referred to is 
```
  image: DOCKER_REPO/k8s-events-node:edge # When applying using make, the DOCKER_REPO is replaced with the environment variable
```
The DOCKER_REPO name needs to be replaced with the name of your DOCKER_REPO for which an environment variable was created. The process is encapsulated in a make command.

9. To apply the `node.yaml` configuration to kubernetes cluster, make sure you are within the folder `read-kubernetes-events` and run
```bash
make apply-node-app-k8s
```
The output will be of the form

```
sed -e s"/DOCKER_REPO/<REPO>/g" ./deploy/node.yaml | kubectl apply -f -
role.rbac.authorization.k8s.io/events-reader created
rolebinding.rbac.authorization.k8s.io/read-events created
service/events-nodeapp created
deployment.apps/events-nodeapp created
```

10. You can now observe the logs 

```bash 
kubectl get pods -n kube-events
```

Output will be of the form:

```
NAME                              READY   STATUS    RESTARTS   AGE
events-nodeapp-69cdb56c6d-m7qd8   2/2     Running   0          3m56s
```

Run:
```
kubectl -n kube-events logs -f events-nodeapp-69cdb56c6d-m7qd8 node
```

Output should be of the form

```
Hello from Kube Events!
{ event: 'add',
  oldVal:
   { metadata: { creationTimestamp: null },
     involvedObject: {},
     source: {},
...},
  newVal:
   { metadata:
      { name: 'events-nodeapp.162cd2271581f9dc',
        namespace: 'kube-events',
        selfLink: '/api/v1/namespaces/kube-events/events/events-nodeapp.162cd2271581f9dc',
        ...
     reportingComponent: '',
     reportingInstance: '' } }
```

11. Cleanup

* Delete the applied configuration `node.yaml`
```bash
make delete-node-app-k8s
```

Output should be of the form:
```
sed -e s"/DOCKER_REPO/<REPO>/g" ./deploy/node.yaml | kubectl delete -f -
role.rbac.authorization.k8s.io "events-reader" deleted
rolebinding.rbac.authorization.k8s.io "read-events" deleted
service "events-nodeapp" deleted
deployment.apps "events-nodeapp" deleted
```

* Delete the applied configuration `kubernetes.yaml`
```
kubectl delete -f ./deploy/kubernetes.yaml
```

* Delete namepace (if it was created for this sample):

```bash
kubectl delete ns kube-events
```

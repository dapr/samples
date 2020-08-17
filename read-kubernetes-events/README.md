# Read Kubernetes Events 

This tutorial will show an example of running Dapr with a Kubernetes Events Input bindg. You'll be deploying the [Node](./node) application along with components [described](./node/components/).

## Prerequisites
This quickstart requires you to have the following installed on your machine:
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- A Kubernetes cluster, such as [Minikube](https://github.com/dapr/docs/blob/master/getting-started/cluster/setup-minikube.md), [AKS](https://github.com/dapr/docs/blob/master/getting-started/cluster/setup-aks.md) or [GKE](https://cloud.google.com/kubernetes-engine/)

Also, unless you have already done so, clone the repository with the quickstarts and ````cd```` into the right directory:
```
git clone [-b <dapr_version_tag>] https://github.com/dapr/samples.git
cd samples/read-kubernetes-events
```
> **Note**: Use `git clone https://github.com/dapr/samples.git` when using the edge version of dapr runtime.
  
## Step 1 - Make sure that your kubectl client is working

The first thing you need is an RBAC enabled Kubernetes cluster. This could be running on your machine using Minikube, or it could be a fully-fledged cluser in Azure using [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/). 

Once you have that make sure you get a positive response from the following kubectl command

```
kubectl get pods
```

This should either have output as `No resources found in default namespace.` or should list the pods running the `default` namesapce.

## Step 2 - Running the code locally

1. Setup Dapr 

Follow [instructions](https://github.com/dapr/docs/blob/master/getting-started/environment-setup.md#environment-setup) to download and install the Dapr CLI and initialize Dapr.

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
cd ../components/
```

Here the yaml file defines the component that Dapr has to register with the particular configuration. 

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
      cd ../node
    ```
* Install dependencies:
    ```bash
      npm install
    ```
* Run Node sample app with Dapr: 
    ```bash
      dapr run --app-id bindings-kevents-nodeapp --app-port 3000 node app.js --components-path ./components
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

== APP ==     source: {},

== APP ==     firstTimestamp: null,

== APP ==     lastTimestamp: null,

== APP ==     eventTime: null,

== APP ==     reportingComponent: '',

== APP ==     reportingInstance: ''

== APP ==   },

== APP ==   newVal: {

== APP ==     metadata: {

== APP ==       name: 'hello-node.162c269e7cedc889',

== APP ==       namespace: 'kube-events',

== APP ==       selfLink: '/api/v1/namespaces/kube-events/events/hello-node.162c269e7cedc889',

== APP ==       uid: 'd1baf297-e1e0-462e-8377-ca82ff8eefed',

== APP ==       resourceVersion: '692745',

== APP ==       creationTimestamp: '2020-08-17T20:00:29Z',

== APP ==       managedFields: [Array]

== APP ==     },

== APP ==     involvedObject: {

== APP ==       kind: 'Deployment',

== APP ==       namespace: 'kube-events',

== APP ==       name: 'hello-node',

== APP ==       uid: 'bbb68f59-74e3-40b5-aa2a-dd0769024f99',

== APP ==       apiVersion: 'apps/v1',

== APP ==       resourceVersion: '692741'

== APP ==     },

== APP ==     reason: 'ScalingReplicaSet',

== APP ==     message: 'Scaled up replica set hello-node-7bf657c596 to 1',

== APP ==     source: { component: 'deployment-controller' },

== APP ==     firstTimestamp: '2020-08-17T20:00:29Z',

== APP ==     lastTimestamp: '2020-08-17T20:00:29Z',

== APP ==     count: 1,

== APP ==     type: 'Normal',

== APP ==     eventTime: null,

== APP ==     reportingComponent: '',

== APP ==     reportingInstance: ''

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
== APP ==       uid: '2323b838-6513-487a-bbfb-4ad3138687d9',
== APP ==       resourceVersion: '692240',
== APP ==       creationTimestamp: '2020-08-17T19:56:09Z',
== APP ==       managedFields: [Array]
== APP ==     },
== APP ==     involvedObject: {
== APP ==       kind: 'Deployment',
== APP ==       namespace: 'kube-events',
== APP ==       name: 'hello-node',
== APP ==       uid: '499390b7-da42-4be5-9cf5-284635140b63',
== APP ==       apiVersion: 'apps/v1',
== APP ==       resourceVersion: '692131'
== APP ==     },
== APP ==     reason: 'ScalingReplicaSet',
== APP ==     message: 'Scaled up replica set hello-node-7bf657c596 to 1',
== APP ==     source: { component: 'deployment-controller' },
== APP ==     firstTimestamp: '2020-08-17T19:56:09Z',
== APP ==     lastTimestamp: '2020-08-17T19:56:09Z',
== APP ==     count: 1,
== APP ==     type: 'Normal',
== APP ==     eventTime: null,
== APP ==     reportingComponent: '',
== APP ==     reportingInstance: ''
== APP ==   },
== APP ==   newVal: {
== APP ==     metadata: { creationTimestamp: null },
== APP ==     involvedObject: {},
== APP ==     source: {},
== APP ==     firstTimestamp: null,
== APP ==     lastTimestamp: null,
== APP ==     eventTime: null,
== APP ==     reportingComponent: '',
== APP ==     reportingInstance: ''
== APP ==   }
== APP == }
```

> Note that the event is categorized as a `delete` event.

* Delete namepace (if it was created for this sample):

```bash
kubectl delete ns kube-events
```

## Next steps
- Explore additional [samples](../README.md#Samples-in-this-repository) and deploy them locally or on Kubernetes.

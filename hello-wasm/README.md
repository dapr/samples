# Hello Wasm

## Sample info

| Attribute            | Details |
|----------------------|---------|
| Dapr runtime version | v1.10   |
| Language             | TinyGo  | 
| Environment          | Local   |

## Overview

This is an example of how to serve HTTP responses directly from the dapr sidecar using WebAssembly.

## Prerequisites
As this is a simple example, we can use `dapr` directly, without Docker or Kubernetes.
If you wish to modify the sample WebAssembly, you will also need to install `tinygo` to compile it.

- [dapr](https://docs.dapr.io/operations/hosting/self-hosted/self-hosted-no-docker) 
- [TinyGo](https://tinygo.org/getting-started/install/)

## Step 1 - Clone this project

With `dapr` setup, clone this repository, then navigate to the `hello-wasm` sample: 

```bash
git clone https://github.com/dapr/samples.git
cd samples/hello-wasm
```

## Step 2 - Understand the code and configuration 

This example uses WebAssembly, which at runtime is embedded into the sidecar process.
In other words, it does not require a separate app to use.

To add custom middleware, you need a wasm binary (file with a `.wasm` extension),
compatible with [http-wasm](https://http-wasm.io/) middleware. You can re-use an
existing wasm binary, or compile your own.

For example, [wasm/main.go](wasm/main.go) compiles to [`wasm/main.wasm`](wasm/main.wasm),
and includes the critical code below.

```go
// handleRequest serves a static response from the Dapr sidecar.
func handleRequest(req api.Request, resp api.Response) (next bool, reqCtx uint32) {
	// Serve a response that shows the invoked request URI.
	resp.Headers().Set("Content-Type", "text/plain")
	resp.Body().WriteString("hello " + req.GetURI())
	return // skip any downstream middleware, as we wrote a response.
}
```

The above writes a response and skips any downstream middleware. This means the request is served from Dapr directly.

To configure this requires two pieces.

* [config.yaml](config.yaml): which enables wasm in the HTTP pipeline.
* [components/wasm.yaml](components/wasm.yaml): configures the wasm binary [`wasm/main.wasm`](wasm/main.wasm)

## Step 3 - Run Dapr

```sh
dapr run --app-id embedded --dapr-http-port 3500 --config config.yaml --resources-path components
```

* `--config config.yaml` is the path to [config.yaml](config.yaml).
* `--components-path components` is the directory that includes [wasm.yaml](components/wasm.yaml).

The command should output text that looks like the following, along with logs:

```
ℹ️  Starting Dapr with id embedded. HTTP Port: 3500. gRPC Port: 56067
...
INFO[0000] enabled middleware.http.wasm/http  middleware  app_id=embedded instance=MacBook-Pro.local scope=dapr.runtime type=log ver=1.10.4
...
✅  You're up and running! Dapr logs will appear here.
...
```
> **Note**: the `--app-port` (the port the app runs on) is configurable. The Node app happens to run on port 3000, but you could configure it to run on any other port. Also note that the Dapr `--app-port` parameter is optional, and if not supplied, a random available port is used.

## Step 4 - Invoke an arbitrary endpoint

Now that Dapr and the Node.js app are running, you can invoke the echo method.

Here's an example using dapr
```sh
$ dapr invoke --verb GET --app-id embedded --method 1
/v1.0/invoke/embedded/method/1
✅  App invoked successfully
```

Here's an example using curl
```sh
$ curl http://localhost:3500/v1.0/invoke/embedded/method/1
hello /v1.0/invoke/embedded/method/1
```

*Note:* If you used a different port, be sure to update your URL accordingly.

## Step 5 - Cleanup

To stop your service from running, simply stop the "dapr run" process. Alternatively, you can spin down your service with the Dapr CLI "stop" command. For example, to spin down the service, run this command in a new command line terminal: 

```bash
dapr stop --app-id embedded
```

To see that services have stopped running, run `dapr list`, noting that your services no longer appears!

## Next Steps

Now that you've started with wasm middleware, consider these next steps:
- Look at the [wasm middleware](https://docs.dapr.io/reference/components-reference/supported-middleware/middleware-wasm/) documentation.

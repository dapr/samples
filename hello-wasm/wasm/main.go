package main

import (
	"github.com/http-wasm/http-wasm-guest-tinygo/handler"
	"github.com/http-wasm/http-wasm-guest-tinygo/handler/api"
)

func main() {
	handler.HandleRequestFn = handleRequest
}

// handleRequest serves a static response from the Dapr sidecar.
func handleRequest(req api.Request, resp api.Response) (next bool, reqCtx uint32) {
	// Serve a response that shows the invoked request URI.
	resp.Headers().Set("Content-Type", "text/plain")
	resp.Body().WriteString("hello " + req.GetURI())
	return // skip any downstream middleware, as we wrote a response.
}

package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
)

func main() {
	// Health check endpoint
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	// Endpoint to test secret retrieval
	http.HandleFunc("/test-secret", func(w http.ResponseWriter, r *http.Request) {
		// Call Dapr secrets endpoint
		resp, err := http.Get("http://localhost:3500/v1.0/secrets/aws-secretstore/test-secret")
		if err != nil {
			log.Printf("Error getting secret: %v", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer resp.Body.Close()

		// Read and return the response
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Printf("Error reading response: %v", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		fmt.Fprintf(w, "Secret response: %s", string(body))
	})

	log.Println("Starting server on port 8080...")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}

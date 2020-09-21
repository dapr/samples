package main

import (
	"context"
	"fmt"
	"log"

	"net/http"
	"os"
	"strings"

	"github.com/dapr/go-sdk/service/common"
	daprd "github.com/dapr/go-sdk/service/http"
)

var (
	logger     = log.New(os.Stdout, "", 0)
	address    = getEnvVar("ADDRESS", ":8080")
	pubSubName = getEnvVar("PUBSUB_NAME", "http-events")
	topicName  = getEnvVar("TOPIC_NAME", "messages")
)

func main() {
	// create a Dapr service
	s := daprd.NewService(address)

	// add some topic subscriptions
	subscription := &common.Subscription{
		PubsubName: pubSubName,
		Topic:      topicName,
		Route:      fmt.Sprintf("/%s", topicName),
	}

	if err := s.AddTopicEventHandler(subscription, eventHandler); err != nil {
		logger.Fatalf("error adding topic subscription: %v", err)
	}

	// start the service
	if err := s.Start(); err != nil && err != http.ErrServerClosed {
		logger.Fatalf("error starting service: %v", err)
	}
}

func eventHandler(ctx context.Context, e *common.TopicEvent) error {
	logger.Printf(
		"event - PubsubName:%s, Topic:%s, ID:%s, Data: %v",
		e.PubsubName, e.Topic, e.ID, e.Data,
	)

	// TODO: do something with the cloud event data

	return nil
}

func getEnvVar(key, fallbackValue string) string {
	if val, ok := os.LookupEnv(key); ok {
		return strings.TrimSpace(val)
	}
	return fallbackValue
}

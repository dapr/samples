package main

import (
	"fmt"
	"net/http"

	ce "github.com/cloudevents/sdk-go/v2"
	"github.com/gin-gonic/gin"
)

const (
	// SupportedCloudEventVersion indicates the version of CloudEvents suppored by this handler
	SupportedCloudEventVersion = "0.3"

	//SupportedCloudEventContentTye indicates the content type supported by this handlers
	SupportedCloudEventContentTye = "application/json"
)

type subscription struct {
	Topic string `json:"Topic"`
	Route string `json:"Route"`
}

func subscribeHandler(c *gin.Context) {
	
	topics := []subscription{
		subscription{
			Topic: sourceTopic,
			Route: "/" + sourceTopic,
		},
	}
	
	logger.Printf("subscription tipics: %v", topics)
	c.JSON(http.StatusOK, topics)
}

func rootHandler(c *gin.Context) {

	proto := c.GetHeader("x-forwarded-proto")
	if proto == "" {
		proto = "http"
	}

	c.HTML(http.StatusOK, "index", gin.H{
		"host":    c.Request.Host,
		"proto":   proto,
		"version": AppVersion,
	})

}

func eventHandler(c *gin.Context) {

	e := ce.NewEvent()
	if err := c.ShouldBindJSON(&e); err != nil {
		logger.Printf("error binding event: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Bad Request",
			"message": "Error processing your request, see logs for details",
		})
		return
	}

	// logger.Printf("received event: %v", e.Context)

	eventVersion := e.Context.GetSpecVersion()
	if eventVersion != SupportedCloudEventVersion {
		logger.Printf("invalid event spec version: %s", eventVersion)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Bad Request",
			"message": fmt.Sprintf("Invalid spec version (want: %s got: %s)",
				SupportedCloudEventVersion, eventVersion),
		})
		return
	}

	eventContentType := e.Context.GetDataContentType()
	if eventContentType != SupportedCloudEventContentTye {
		logger.Printf("invalid event content type: %s", eventContentType)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Bad Request",
			"message": fmt.Sprintf("Invalid content type (want: %s got: %s)",
				SupportedCloudEventContentTye, eventContentType),
		})
		return
	}

	// logger.Printf("tweet: %s", string(e.Data()))

	broadcaster.Broadcast(e.Data())

	c.JSON(http.StatusOK, nil)
}

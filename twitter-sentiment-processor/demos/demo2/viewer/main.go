package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"gopkg.in/olahol/melody.v1"
)

var (
	logger = log.New(os.Stdout, "VIEWER == ", 0)

	// AppVersion will be overritten during build
	AppVersion = "v0.0.1-default"

	// The route name to process the incoming tweets on
	topicRoute = "showOnWebSite"

	broadcaster *melody.Melody
)

func main() {

	gin.SetMode(gin.ReleaseMode)

	// router
	r := gin.New()
	r.Use(gin.Recovery())

	// ws
	broadcaster = melody.New()
	broadcaster.Upgrader.CheckOrigin = func(r *http.Request) bool { return true }

	// static
	r.LoadHTMLGlob("resource/template/*")
	r.Static("/static", "./resource/static")
	r.StaticFile("/favicon.ico", "./resource/static/img/favicon.ico")

	// simple routes
	r.GET("/", rootHandler)
	r.GET("/dapr/subscribe", subscribeHandler)

	// websockets
	r.GET("/ws", func(c *gin.Context) {
		broadcaster.HandleRequest(c.Writer, c.Request)
	})

	// topic route
	viewerRoute := fmt.Sprintf("/%s", topicRoute)
	logger.Printf("viewer route: %s", viewerRoute)
	r.POST(viewerRoute, eventHandler)

	// server
	hostPort := net.JoinHostPort("0.0.0.0", "8083")
	logger.Printf("Server (%s) starting: %s \n", AppVersion, hostPort)
	if err := r.Run(hostPort); err != nil {
		logger.Fatal(err)
	}
}

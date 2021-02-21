package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/mux"
)

var daprPort = os.Getenv("DAPR_HTTP_PORT")

const stateStoreName = `events`

var stateURL = fmt.Sprintf(`http://localhost:%s/v1.0/state/%s`, daprPort, stateStoreName)

// Event represents an event, be it meetings, birthdays etc
type Event struct {
	Name string
	Date string
	ID   string
}

func addEvent(w http.ResponseWriter, r *http.Request) {
	var event Event

	err := json.NewDecoder(r.Body).Decode(&event)
	log.Printf("Error while decoding", err)
	log.Printf("Event Name: %s", event.Name)
	log.Printf("Event Date: %s", event.Date)
	log.Printf("Event ID: %s", event.ID)

	var data = make([]map[string]string, 1)
	data[0] = map[string]string{
		"key":   event.ID,
		"value": event.Name + " " + event.Date,
	}
	state, _ := json.Marshal(data)
	log.Printf(string(state))

	resp, err := http.Post(stateURL, "application/json", bytes.NewBuffer(state))
	if err != nil {
		log.Fatalln("Error posting to state", err)
		http.Error(w, "Failed to write to store", http.StatusServiceUnavailable)
	}
	log.Printf("Response after posting to state: %s", resp.Status)
	http.Error(w, "All Okay", http.StatusOK)
}

func deleteEvent(w http.ResponseWriter, r *http.Request) {
	type Identity struct {
		ID string
	}
	var eventID Identity

	err := json.NewDecoder(r.Body).Decode(&eventID)
	log.Printf("Error decoding id")

	deleteURL := stateURL + "/" + eventID.ID
	log.Printf("Delete URL: ", deleteURL)

	req, err := http.NewRequest(http.MethodDelete, deleteURL, nil)
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatalln("Error deleting event", err)
	}
	log.Printf("Response after delete call: ", resp.Status)

	defer resp.Body.Close()
	bodyBytes, _ := ioutil.ReadAll(resp.Body)

	log.Printf(string(bodyBytes))
}

func main() {
	router := mux.NewRouter()

	router.HandleFunc("/addEvent", addEvent).Methods("POST")
	router.HandleFunc("/deleteEvent", deleteEvent).Methods("POST")
	log.Fatal(http.ListenAndServe(":6000", router))
}

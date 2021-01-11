# dapr-distributed-calendar

| Attribute | Details |
|--------|--------|
| Dapr runtime version | v0.11.3 |
| Language | Javascript, Python, Go |
| Environment | Local or Kubernetes |

This is a sample application built using Dapr as a proof-of-concept. I have experimented with the state store, pubsub and output bindings features available with Dapr.
I have used multiple languages for writing the different parts of this calendar app. This demonstrates the language-agnostic nature of Dapr and the flexibility that it bings to developing
applications.

## Contents

* [**Motivation**](https://github.com/wjayesh/dapr-distributed-calendar#motivation)

* [**Architecture**](https://github.com/wjayesh/dapr-distributed-calendar#architecture)
  * [**Controller**](https://github.com/wjayesh/dapr-distributed-calendar#controller-written-in-javascript)
  * [**Services**](https://github.com/wjayesh/dapr-distributed-calendar#services)

* [**How to run**](https://github.com/wjayesh/dapr-distributed-calendar#how-to-run)

* [**Test using Postman**](https://github.com/wjayesh/dapr-distributed-calendar#test-using-postman)


## Motivation

I am really enthusiastic about cool open source projects and I'm a fan of Azure. When I learnt about Dapr early this year, I knew I needed to get my hands dirty playing
around with what Dapr had to offer.
I wanted to explore Dapr an experience building a distributed application with it to understand what it brought to the table 
in comparison to conventional applications. 

I had built a SpringBoot app on MVCS architecture before; it was a monolith application, all written in Java. 
Building a roughly similar architecture as a distributed applicaiton would intuitively require some additional work pertaining to service discovery, inter-pod communication
and network security. Things could get complicated if I needed additional checks, statestores or other controls which I would have to implement on my own.
This, in addition to the actual application itself. 

I wanted to find out how Dapr simplified this process and what additional work I would have to put in to get a distributed version of the same applciation using Dapr. 

## Architecture

I have tried to model this system on the Model View Controller Service (MVCS) architecture, as already mentioned. 


![Diagram](https://user-images.githubusercontent.com/37150991/100470841-07c3d380-30ff-11eb-855c-711026ad4804.png)


### Controller (written in Javascript)

  * The controller supports creation of new events and deletion of existing events. 
    It forwards these requests to the **Go** code using service invocation.
  
    *Shown below is the add event flow*. 
  
    ```js
    app.post('/newevent', (req, res) => {
    const data = req.body.data;
    const eventId = data.id;
    console.log("New event registration! Event ID: " + eventId);


    console.log("Data passed as body to Go", JSON.stringify(data))
    fetch(invokeUrl+`/addEvent`, {
        method: "POST",
        body: JSON.stringify(data),
        headers: {
            "Content-Type": "application/json"
        }
    })
    ```
    where the invokeURL is defined as:
    ```js
    const invokeUrl = `http://localhost:${daprPort}/v1.0/invoke/${eventApp}/method`;
    ```
  
  
  * On creation of a new event, it publishes a message to a **pubsub** topic which is then picked up by the **Python** subscriber. 
  
    *Pubishing to the topic*
  
    ```js
    function send_notif(data) {
      var message = {
          "data": {
              "message": data,
          }
      };
      console.log("Message: ", message)
      request( { uri: publishUrl, method: 'POST', json: JSON.stringify(message) } );
    }
    ```
    where the publish URL is:
    ```js
    const publishUrl = `http://localhost:${daprPort}/v1.0/publish/${pubsub_name}/${topic}`;
    ```
    
### Services

The services handle the requests forwarded by the controller. Each of the tasks listed with the controller is handled by a service written in 
a different language. I'll detail the implementation below.

* **Event Service** (written in Go):
  This service uses the statestore component Redis for storing and deleting events from memory. The code snippet shown below is from 
  `go_events.go` and demonstrates adding an event to the state store. 

  ```go
   var data = make([]map[string]string, 1)
   data[0] = map[string]string{
    "key":   event.ID,
    "value": event.Name + " " + event.Date,
   }
   state, _ := json.Marshal(data)
   log.Printf(string(state))


   resp, err := http.Post(stateURL, "application/json", bytes.NewBuffer(state))
  ```

  where the stateURL is defined as:


  ```go
  var stateURL = fmt.Sprintf(`http://localhost:%s/v1.0/state/%s`, daprPort, stateStoreName)
  ```

* **Messaging Service** (written in Python):

  This service subscribes to the topic that we post messages to, from the controller. It then uses the [SendGrid](https://docs.dapr.io/operations/components/setup-   bindings/supported-bindings/sendgrid/) output binding to 
  send an email about creation of a new event. 
  I have used the Dapr client for Python while writing this service. 

  The code below shows how the service registers as a **subscriber** with Dapr for a specific topic.
  

  ```python
  @app.route('/dapr/subscribe', methods=['GET'])
  def subscribe():
      subscriptions = [{'pubsubname': 'pubsub',
                        'topic': 'events-topic',
                        'route': 'getmsg'}]
      return jsonify(subscriptions)
  ```
  
  > The Dapr runtime calls the `/dapr/subscribe` endpoint to register new apps as subscribers. The other way to do this would be defining a configuration
  file, linked [here](https://github.com/dapr/docs/blob/3509967baa65ece9fb822e2948e4eb7ed8d34af5/daprdocs/content/en/developing-applications/building-blocks/pubsub/howto-publish-subscribe.md#declarative-subscriptions). 
  
  The following code receives the message posted to the topic and then calls the `send_email` function.
  
  ```py
  @app.route('/getmsg', methods=['POST'])
  def subscriber():
    print(request.json, flush=True)
    
    jsonRequest = request.json
    data = jsonRequest["data"]["data"]["message"]
    print(data, flush=True)
    
    send_email()
  ```

  The send_email functions calls the SendGrid binding with the message payload:
  
  ```py
  def send_email():
    with DaprClient() as d:
            
        req_data = {
            'metadata': {
                'emailTo': emailTo,
                'subject': subject
            },
            'data': data
        }


        print(req_data, flush=True)


        # Create a typed message with content type and body
        resp = d.invoke_binding(binding_name, 'create', json.dumps(req_data))
  ```
  
  where invoke_binding is a library function from the Dapr client. In the previous cases, we had called the endpoints directly; here we 
  use a function already implemented for us.


## How to Run

The project has three different apps, in Go, Python and Node. We have to build them and then utilise the `dapr run` command to start these apps.

First, make sure that your component definitions are present under `$HOME/.dapr/components` if you're on Linux and under `%USERPROFILE%\.dapr\components` if you're using Windows. This is because the `dapr run` command makes use of the yaml definitions provided here at runtime. 
 
You can find the component definitions I've used in this project under `components` of the root directory. The password and api keys have been removed and will need to be provided at runtime. In Kubernetes, you can make use of Secrets for these values. Check out [secret stores](https://docs.dapr.io/developing-applications/building-blocks/secrets/secrets-overview/) component of Dapr!

After the components are created with the correct fields, we can build and run the individual apps.

### Go

1) Go inside the `go` directory and build the project Make sure you have `gorilla/mux`  package installed. If not, run the following command:

```
go get -u github.com/gorilla/mux
```
2) Build the app.

```
go build go_events.go
```
3) Run Dapr

```
dapr run --app-id go-events --app-port 6000 --dapr-http-port 3503 ./go-events
```

### Python

1) Install required dependencies. 

```
pip3 install wheel python-dotenv flask_cors flask
```

2) Set environment variable for Flask.

```bash
#Linux/Mac OS:
export FLASK_RUN_PORT=5000

#Windows:
set FLASK_RUN_PORT=5000
```

3) Start Dapr.

```
dapr run --app-id messages --app-port 5000 --dapr-http-port 3501 flask run
```

### Node

1) Install dependencies.

```
npm install
```

2) Start Dapr.

```
dapr run --app-id controller --app-port 3000 --dapr-http-port 3500 node node_controller.js
```

## Test Using Postman

### Posting a new event to the controller:

  * Postman client used to send request body at "/newevent" endpoint.
    <img width="960" alt="Postman_xZToyg3V5V" src="https://user-images.githubusercontent.com/37150991/103376151-decd9e80-4b01-11eb-899e-526077298036.png">

  * The Dapr logs inside the **controller** showing the data that is being passed to the Go app for persisting in storage. 

    <img width="723" alt="Code_q47W3rzXWh" src="https://user-images.githubusercontent.com/37150991/103376099-bcd41c00-4b01-11eb-962d-381dada3b8d4.png">

  * The Dapr logs inside the **go-events** app showing the data received along with the status response. 

    <img width="731" alt="Code_ofFsZ9hUTU" src="https://user-images.githubusercontent.com/37150991/103376139-d5443680-4b01-11eb-98e8-8ae83fc2c5dd.png">



### Invoking the state endpoint to test statestore feature:

  * Posting to the **events** statestore, a body with a key-value pair as shown. 

    <img width="960" alt="Postman_vOcZin57HI" src="https://user-images.githubusercontent.com/37150991/103376192-fc9b0380-4b01-11eb-8aae-3dbf2e744672.png">

  * Checking the value of key at the events statestore.

    <img width="960" alt="Postman_BLqZjqVt5x" src="https://user-images.githubusercontent.com/37150991/103376177-ed1bba80-4b01-11eb-9be7-012d0d9ed324.png">



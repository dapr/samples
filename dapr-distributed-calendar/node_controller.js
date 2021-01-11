
const express = require('express');
const bodyParser = require('body-parser');
require('isomorphic-fetch');

const app = express();
app.use(bodyParser.json());

const daprPort = process.env.DAPR_HTTP_PORT || 3500;

const eventApp = `go-events`;
const invokeUrl = `http://localhost:${daprPort}/v1.0/invoke/${eventApp}/method`;

const topic = 'events-topic'
const pubsub_name = 'pubsub'
const publishUrl = `http://localhost:${daprPort}/v1.0/publish/${pubsub_name}/${topic}`;

const port = 3000;

function send_notif(data) {
    var message = {
        "data": {
            "message": data,
        }
    };
    console.log("Message: ", message)
    request( { uri: publishUrl, method: 'POST', json: JSON.stringify(message) } );
}

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
    }).then((response) => {
        if (!response.ok) {
            throw "Failed to persist state.";
        }

        console.log("Successfully persisted state.");
        res.status(200).send();
    }).catch((error) => {
        console.log(error);
        res.status(500).send({message: error});
    });
    send_notif(data)
});

app.delete('/event/:id', (req, res) => {  
    const key = req.params.id;      
    console.log('Invoke Delete for ID ' + key);         

    var obj = {"id" : key};
    console.log("Data passed as body to Go", JSON.stringify(obj))
    fetch(invokeUrl+'/deleteEvent', {
        method: "POST",  
        body: JSON.stringify(obj),  
        headers: {
            "Content-Type": "application/json"
        }
    }).then((response) => {
        if (!response.ok) {n
            throw "Failed to delete state.";
        }

        console.log("Successfully deleted state.");
        res.status(200).send();
    }).catch((error) => {
        console.log(error);
        res.status(500).send({message: error});
    });    
});


app.listen(port, () => console.log(`Node App listening on port ${port}!`));
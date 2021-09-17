// ------------------------------------------------------------
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
// ------------------------------------------------------------

const express = require('express');
require('isomorphic-fetch');

const app = express();

// Dapr publishes messages with the application/cloudevents+json content-type
app.use(express.json({ type: 'application/*+json' }));

const port = process.env.APP_HTTP_PORT || 3000;
const daprPort = process.env.DAPR_HTTP_PORT || 3500;
const stateUrl = `http://localhost:${daprPort}/v1.0/state/statestore/`;

// Uses service invocation from Dapr to return the last stored order
app.get('/order', (_req, res) => {
    fetch(`${stateUrl}/order`)
        .then((response) => {
            return response.json();
        }).then((orders) => {
            res.send(orders);
        });
});

// Used to receive new orders from Dapr pub/sub
app.post('/neworder', (req, res) => {
    const order = req.body.data.order;
    const orderId = order.orderId;
    console.log("Got a new order from service call! Order ID: " + orderId);

    storeState(order);

    res.status(200).send();
});

// Stores the order into the Dapr state store
function storeState(order) {
    const state = [{
        key: "order",
        value: order
    }];

    fetch(stateUrl, {
        method: "POST",
        body: JSON.stringify(state),
        headers: {
            "Content-Type": "application/json"
        }
    }).then((response) => {
        console.log((response.ok) ? "Successfully persisted state" : "Failed to persist state" + response);
    });
}

app.listen(port, () => console.log(`Node App listening on port ${port}!`));
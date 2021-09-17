// ------------------------------------------------------------
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
// ------------------------------------------------------------

const express = require('express');
require('isomorphic-fetch');

const app = express();
app.use(express.json());

const port = process.env.APP_HTTP_PORT || 3000;
const daprPort = process.env.DAPR_HTTP_PORT || 3500;
const stateUrl = `http://localhost:${daprPort}/v1.0/state/statestore/`;

app.get('/order', (_req, res) => {
    fetch(`${stateUrl}/order`)
        .then((response) => {
            return response.json();
        }).then((orders) => {
            res.send(orders);
        });
});

app.post('/neworder', (req, res) => {
    const data = req.body.data;
    const orderId = data.orderId;
    console.log("Got a new order! Order ID: " + orderId);

    const state = [{
        key: "order",
        value: data
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

    res.status(200).send();
});

app.listen(port, () => console.log(`Node App listening on port ${port}!`));
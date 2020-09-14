const express = require('express');
const bodyParser = require('body-parser');

const subscribe = require('./routes/subscribe');

const app = express();

// Dapr publishes messages with the "application/cloudevents+json" content-type
app.use(bodyParser.json({ type: 'application/*+json' }));
app.use(bodyParser.json());

app.use('/', subscribe);

const port = 3000;
app.listen(port, () => console.log(`Batch Processor listening on port ${port}!`));
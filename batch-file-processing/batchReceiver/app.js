const express = require('express');
const bodyParser = require('body-parser');

const blobAddedHandler = require('./routes/blobAddedHandler');

const app = express();
app.use(bodyParser.json());

app.use('/blobAddedHandler', blobAddedHandler);

const port = 3000;
app.listen(port, () => console.log(`Batch Receiver listening on port ${port}!`));
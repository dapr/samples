const express = require('express');
const router = express.Router();
const axios = require('axios');

const combineOrderContent = require('../ordersBuilder');

const daprPort = process.env.DAPR_HTTP_PORT || 3500;

router.get('/dapr/subscribe', (req, res) => {
    res.json([{
        topic: "batchReceived",
        route: "batchReceived",
        pubsubname: "messagebus"
    }]);
});

router.post('/batchReceived', async (req, res) => {
    const traceparentId = req.headers['traceparent'] ? req.headers['traceparent'] : "";

    const daprHeaders = {
        'traceparent': traceparentId
    };

    const batchId = req.body.data.batchId;
    console.log(`${logPrefix(traceparentId)} received batch: ${batchId}`);

    await new Promise(r => setTimeout(r, generateRandomSleep(2000, 3000)));

    let orders;
    try {       
        console.log(`${logPrefix(traceparentId)} combining order content for batch: ${batchId}`);

        orders = await combineOrderContent(batchId);
    } catch (error) {
        console.log(`${logPrefix(traceparentId)} ${error}`);
        res.status(500).send(error);
        return;
    }    

    let orderData;

    // store orders to cosmosdb
    for (let i = 0; i < orders.length; i++) {
        try {
            let order = orders[i];
            orderData = {...order, id: order.headers.salesNumber };
            console.log(`${logPrefix(traceparentId)} adding order: ${orderData.id} from batch: ${batchId}`);

            const dbOrders = 'cosmosdb-orders';
            const daprDbOrdersUrl = `http://localhost:${daprPort}/v1.0/bindings/${dbOrders}`;
            await axios.post(daprDbOrdersUrl, { data: orderData, operation: 'create' }, { headers: daprHeaders });
               
        } catch (error) {
            let message = error.response.data.message;

            // normally you would check status code, but dapr returns 500 for all non 200 codes
            if (message.includes('Entity with the specified id already exists in the system')) {
                console.log(`${logPrefix(traceparentId)} already exists orderId: ${orderData.id} batch: ${batchId}`);
                continue;
            }

            if (error.response && error.response.data) {
                console.log(`${logPrefix(traceparentId)} failed to store orderId: ${orderData.id} batch: ${batchId} code: ${error.response.status}: ${error.response.data.message}`);
            }

            res.status(500).send(error.response.data.message);
            return;
        }
    }

    console.log(`${logPrefix(traceparentId)} finished storing orders from batch: ${batchId}`);

    res.sendStatus(200);
});

function logPrefix(traceparentId) {
    let d = new Date();
    let time = d.toLocaleString('en-US', { hour12: false , timeZone: "America/Los_Angeles"}) + "." + d.getMilliseconds();
    traceparentId = traceparentId ? traceparentId.split('-')[1] : "";
    return time + " " + traceparentId;
}

function generateRandomSleep(min, max) {
    let randNum = Math.random() * (max - min) + min;
    return Math.floor(randNum);
}

module.exports = router;
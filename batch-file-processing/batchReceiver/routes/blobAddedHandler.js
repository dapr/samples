const express = require('express');
const router = express.Router();

const axios = require('axios');
const config = require('../config');

const daprPort = process.env.DAPR_HTTP_PORT || 3500;

router.post('/', async (req, res) => {
    const traceparentId = req.headers['traceparent'];
    console.log(`${logPrefix(traceparentId)} received blob created event`);

    const validationEventType = 'Microsoft.EventGrid.SubscriptionValidationEvent';
    const storageBlobCreatedEvent = 'Microsoft.Storage.BlobCreated';
    const topic = `/subscriptions/${config.subscriptionId}/resourceGroups/${config.resourceGroupName}/providers/Microsoft.Storage/storageAccounts/${config.storageAccountName}`;

    if (!req.body) res.status(400).send();

    console.log(`${logPrefix(traceparentId)} events count: ${req.body.length}`);

    for (let i = 0; i < req.body.length; i++) {
        let event = req.body[i];

        if (!event.data) {
            console.log(`${logPrefix(traceparentId)} empty event data`);
            continue;
        }

        if (event.eventType == validationEventType) {
            console.log(`Got SubscriptionValidation event data, validation code: ${event.data.validationCode}, topic: ${event.topic}`);
            res.send({'ValidationResponse': event.data.validationCode});
            return;
        } else if (event.eventType != storageBlobCreatedEvent || event.topic != topic) {
            console.log(`Unexpected event: ${event.eventType} or topic: ${event.topic}`);
            continue;
        } else {
            let blobCreatedEventData = event.data;
            console.log(`${logPrefix(traceparentId)} blob created event payload: ${JSON.stringify(blobCreatedEventData)}`);

            // get batch id and file type
            const path = blobCreatedEventData.url.split('/');
            const fileName = path[path.length - 1];
            const dashIndex = fileName.indexOf('-');
            const batchTimestamp = fileName.substring(0, dashIndex);
            const fileType = fileName.substring(dashIndex + 1, fileName.indexOf('.'));
            console.log(`${logPrefix(traceparentId)} received event for: ${fileType} from batch: ${batchTimestamp}`);

            // update state
            try {
                const daprHeaders = {
                    'traceparent': traceparentId
                };

                const daprStateUrl = `http://localhost:${daprPort}/v1.0/state/statestore`;
                let batchStateRes = await axios.get(daprStateUrl + `/${batchTimestamp}`, {
                    headers: daprHeaders
                });

                let batchState = batchStateRes.data ? batchStateRes.data : {};
                batchState[fileType] = blobCreatedEventData.url;

                const state = [{
                    key: batchTimestamp,
                    value: batchState
                }];
                
                // TODO: add etag
                await axios.post(daprStateUrl, JSON.stringify(state), { headers: daprHeaders });

                if (!receivedAllFiles(batchState)) {
                    res.status(200).send(state);
                    return;
                }

                // publish event
                console.log(`${logPrefix(traceparentId)} publishing batch received event`);
                const topic = 'batchReceived';
                let daprPublishUrl = `http://localhost:3500/v1.0/publish/messagebus/${topic}`;
                await axios.post(daprPublishUrl, {"batchId": `${batchTimestamp}`}, {
                    headers: daprHeaders
                });

            } catch (error) {
                res.status(500).send(error.response.data);
            }
        }
    }

    res.status(200).send();
});

function receivedAllFiles(batchState) {
    const fileTypes = ['OrderHeaderDetails', 'OrderLineItems', 'ProductInformation'];

    return fileTypes.every(fileType => {
        return fileType in batchState;
    });
}

function logPrefix(traceparentId) {
    let d = new Date();
    let time = d.toLocaleString('en-US', { hour12: false , timeZone: "America/Los_Angeles"}) + "." + d.getMilliseconds();
    return time + " " + traceparentId.split('-')[1];
}

module.exports = router;
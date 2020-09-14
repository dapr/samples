const express = require('express');
const bodyParser = require('body-parser');

const { createOrderHeaderCsvContent, createOrderLineItemsCsvContent, createProductInformationCsvContent, generateOrders, sendBatch } = require('./services/csvService');

const app = express();
app.use(bodyParser.json());

(async () => {
    while (true) {
        let orders = generateOrders();
    
        // Generate the CSV content
        const orderHeaderCsv = createOrderHeaderCsvContent(orders);
        const lineItemsCsv = createOrderLineItemsCsvContent(orders);
        const productInfoCsv = createProductInformationCsvContent(orders);
    
        console.log("sending a batch...");
        sendBatch(orderHeaderCsv, lineItemsCsv, productInfoCsv);
        await new Promise(r => setTimeout(r, 60000));
    }
})();

const port = 3003;
app.listen(port, () => console.log(`Batch Generator listening on port ${port}!`));
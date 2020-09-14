const { getDistributors, getProducts } = require ('./fakeDataService');
const moment = require('moment');
const axios = require('axios');
const faker = require('faker');

module.exports.createOrderHeaderCsvContent = (orders) => {
    // add headers
    let csv = 'ponumber,datetime,locationid,locationname,locationaddress,locationpostcode,totalcost,totaltax';

    // generate header details
    let headerDetails = [];
    for (let i = 0; i < orders.length; i++) {
        let order = orders[i];    
        let cost = 0;
        let tax = 0;

        for (let j = 0; j < order.lineItems.length; j++ ) {
            let item = order.lineItems[j];
            cost += item.totalCost;
            tax += item.totalTax;
        }

        headerDetails.push({
            poNumber: order.poNumber,
            dateTime: order.dateTime,
            locationId: order.distributor.locationId,
            locationName: order.distributor.locationName,
            locationAddress: order.distributor.locationAddress,
            locationPostCode: order.distributor.locationPostCode,
            totalCost: cost,
            totalTax: tax
        });
    }

    // add content
    for (let i = 0; i < headerDetails.length; i++) {
        let detail = headerDetails[i];

        csv += '\n';
        let newLine = `${detail.poNumber},${detail.dateTime},${detail.locationId},${detail.locationName},${detail.locationAddress},${detail.locationPostCode},${detail.totalCost},${detail.totalTax}`;
        csv += newLine;
    }

    return csv;
}

module.exports.createOrderLineItemsCsvContent = (orders) => {
    // add headers
    let csv = 'ponumber,productid,quantity,unitcost,totalcost,totaltax';

    for (let i = 0; i < orders.length; i++) {
        let order = orders[i];

        for (let j = 0; j < order.lineItems.length; j++) {
            let item = order.lineItems[j];

            csv += '\n';
            csv += `${item.poNumber},${item.productId},${item.quantity},${item.unitCost},${item.totalCost},${item.totalTax}`;
        }
    }

    return csv;
}

module.exports.createProductInformationCsvContent = (orders) => {
    // add headers
    let csv = 'productid,productname,productdescription';

    // add products that have been ordered
    let orderedProducts = getProducts().filter(product => orders.some(order => order.lineItems.some(lineItem => lineItem.productId == product.productId)));

    for (let i = 0; i < orderedProducts.length; i++) {
        let product = orderedProducts[i];

        csv += '\n';
        csv += `${product.productId},${product.productName},${product.productDescription}`;
    }
    
    return csv;
}

module.exports.generateOrders = () => {
    const numOrders = faker.random.number({min:1, max:8});
    const distributors = getDistributors();
    const orders = [];

    for (let i = 0; i < numOrders; i++) {
        let randomIndex = faker.random.number({min:0, max:distributors.length - 1});
        let order = {};

        order.distributor = distributors[randomIndex];
        order.dateTime = faker.date.recent(30).toLocaleString();
        order.poNumber = faker.random.alphaNumeric(6).toUpperCase();
        order.lineItems = generateLineItems(order.poNumber);

        orders.push(order);
    }

    return orders;
};

function generateLineItems(poNumber) {
    const numItems = faker.random.number({min:1, max:5});

    const products = [...getProducts()];
    let lineItems = [];

    for (let i = 0; i < numItems; i++) {
        let randomIndex = faker.random.number({min:0, max:products.length - 1});
        let item = {};

        item.poNumber = poNumber;
        item.product = products[randomIndex];
        item.productId = products[randomIndex].productId;
        item.unitCost = products[randomIndex].unitCost;
        item.quantity = faker.random.number({min:1, max:5});
        item.totalCost = item.quantity * item.unitCost;
        item.totalTax = item.totalCost * 0.1;

        products.splice(randomIndex, 1);
        lineItems.push(item);
    }

    return lineItems;
}

// Upload the CSVs to the blob
module.exports.sendBatch = async (orderHeaderCsv, lineItemsCsv, productInfoCsv) => {
    const prefix = moment().format('YYYYMMDDHHmmss');

    const orderHeaderDetailsFile = `${prefix}-OrderHeaderDetails.csv`;
    const orderLineItemsFile = `${prefix}-OrderLineItems.csv`;
    const productInformationFile = `${prefix}-ProductInformation.csv`;

    const daprPort = process.env.DAPR_HTTP_PORT || 3500;
    const storageComponentName = 'blob-storage';
    const storageBindingUrl = `http://localhost:${daprPort}/v1.0/bindings/${storageComponentName}`;

    try {
        const payload = generatePayload(orderHeaderCsv, orderHeaderDetailsFile);
        await axios.post(storageBindingUrl, payload);
    } catch (error) {
        console.log(error.message);
    }

    await new Promise(r => setTimeout(r, generateRandomSleep(500, 1000)));

    try {
        const payload = generatePayload(lineItemsCsv, orderLineItemsFile);
        await axios.post(storageBindingUrl, payload);
    } catch (error) {
        console.log(error.message);
    }

    await new Promise(r => setTimeout(r, generateRandomSleep(500, 1000)));

    try {
        const payload = generatePayload(productInfoCsv, productInformationFile);
        await axios.post(storageBindingUrl, payload);
    } catch (error) {
        console.log(error.message);
    }

    await new Promise(r => setTimeout(r, generateRandomSleep(500, 1000)));
}

function generatePayload(fileContent, fileName) {
    return payload = {
        data: `${fileContent}`,
        metadata: {
            blobName: `${fileName}`,
            ContentType: 'text/csv'
        },
        operation: 'create'
    }
}

function generateRandomSleep(min, max) {
    let randNum = Math.random() * (max - min) + min;
    return Math.floor(randNum);
}



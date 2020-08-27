const axios = require('axios');
const config = require('./config');

async function combineOrderContent(batchId) {
    const blobStorageAccountBaseUrl = config.blobStorageAccountBaseUrl + batchId;
    const storageSasToken = config.storageSasToken;

    const orderHeaderDetailsCsvUrl = `${blobStorageAccountBaseUrl}-OrderHeaderDetails.csv${storageSasToken}`;
    const orderLineItemsCsvUrl = `${blobStorageAccountBaseUrl}-OrderLineItems.csv${storageSasToken}`;
    const productInformationCsvUrl = `${blobStorageAccountBaseUrl}-ProductInformation.csv${storageSasToken}`;

    let orderHeaderDetailsContent;
    let orderLineItemsContent;
    let productInformationContent;

    // pull file content
    try {
        orderHeaderDetailsContent = (await axios.get(orderHeaderDetailsCsvUrl)).data;
    } catch (err) {
        throw `Failed to retrieve file '${orderHeaderDetailsCsvUrl}'. Please ensure file is accessible.`;
    }

    try {
        orderLineItemsContent = (await axios.get(orderLineItemsCsvUrl)).data;
    } catch (err) {
        throw `Failed to retrieve file '${orderLineItemsCsvUrl}'. Please ensure file is accessible.`;
    }

    try {
        productInformationContent = (await axios.get(productInformationCsvUrl)).data;
    } catch (err) {
        throw `Failed to retrieve file '${productInformationCsvUrl}'. Please ensure file is accessible.`;
    }

    // convert order line items into useable arrays of objects instead of strings
    let orderLineItemObjectArray = buildOrderLineItems(orderLineItemsContent);

    // convert product info into useable arrays of objects instead of strings
    let productInformationObjectArray = buildProductInformation(productInformationContent);

    // build combined order details for each order in the batch
    let combinedOrders = buildCombinedOrders(orderHeaderDetailsContent, orderLineItemObjectArray, productInformationObjectArray);

    return combinedOrders;
}

function buildCombinedOrders(orderHeaderDetailsContent, orderLineItemObjectArray, productInformationObjectArray) {
    let orderHeaderDetailsArray = orderHeaderDetailsContent.split("\n");
    let combinedOrders = [];
    for (let i = 1; i < orderHeaderDetailsArray.length; i++) {
        // add header for order
        let individualHeaderDetails = orderHeaderDetailsArray[i].split(',');
        let headers = {
            salesNumber: individualHeaderDetails[0],
            dateTime: individualHeaderDetails[1],
            locationId: individualHeaderDetails[2],
            locationName: individualHeaderDetails[3],
            locationAddress: individualHeaderDetails[4],
            locationPostcode: individualHeaderDetails[5],
            totalCost: individualHeaderDetails[6],
            totalTax: individualHeaderDetails[7]
        };

        // add details for order
        let details = [];
        let relatedOrderLineItems = orderLineItemObjectArray.filter((o) => o.salesNumber === headers.salesNumber);
        for (let relatedLineItem of relatedOrderLineItems) {
            let relatedProduct = productInformationObjectArray.find((p) => p.productId === relatedLineItem.productId);
            details.push({
                productId: relatedLineItem.productId,
                quantity: relatedLineItem.quantity,
                unitCost: relatedLineItem.unitCost,
                totalCost: relatedLineItem.totalCost,
                totalTax: relatedLineItem.totalTax,
                productName: relatedProduct.productName,
                productDescription: relatedProduct.productDescription
            });
        }
        combinedOrders.push({
            headers,
            details
        });
    }

    return combinedOrders;
}

function buildOrderLineItems(orderLineItemsContent) {
    let orderLineItemsArray = orderLineItemsContent.split("\n");
    let orderLineItemObjectArray = [];
    for (let i = 1; i < orderLineItemsArray.length; i++) {
        let individualLineItem = orderLineItemsArray[i].split(',');
        orderLineItemObjectArray.push({
            salesNumber: individualLineItem[0],
            productId: individualLineItem[1],
            quantity: individualLineItem[2],
            unitCost: individualLineItem[3],
            totalCost: individualLineItem[4],
            totalTax: individualLineItem[5]
        });
    }

    return orderLineItemObjectArray;
}

function buildProductInformation(productInformationContent) {
    let productInformationArray = productInformationContent.split("\n");
    let productInformationObjectArray = [];
    for (let i = 1; i < productInformationArray.length; i++) {
        let individualProduct = productInformationArray[i].split(',');
        productInformationObjectArray.push({
            productId: individualProduct[0],
            productName: individualProduct[1],
            productDescription: individualProduct[2]
        });
    }

    return productInformationObjectArray;
}

module.exports = combineOrderContent;
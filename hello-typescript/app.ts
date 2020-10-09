import dapr from 'dapr-client';
import grpc from "grpc";
import express from "express";
import bodyParser from "body-parser";

const daprGrpcPort = process.env.DAPR_GRPC_PORT || 50001;
const stateStoreName = `statestore`;

const port = 3000;
const app = express();

app.use(bodyParser.json());

var client = new dapr.dapr_grpc.DaprClient(
    `localhost:${daprGrpcPort}`, grpc.credentials.createInsecure());

app.post('/neworder', (req, res) => {
    const data = req.body.data;
    const orderId = data.orderId;
    console.log("Got a new order! Order ID: " + orderId);

    var save = new dapr.dapr_pb.SaveStateRequest();
    save.setStoreName(stateStoreName)
    var state = new dapr.common_pb.StateItem();
    state.setKey("order");
    state.setValue(Buffer.from(JSON.stringify(data)));
    save.addStates(state);

    client.saveState(save, (error, _) => {
        if (error) {
            console.log(error);
            res.status(500).send({message: error});
        } else {
            console.log("Successfully persisted state.");
            res.status(200).send();
        }
    });
});

app.get('/order', (_req, res) => {
    var get = new dapr.dapr_pb.GetStateRequest();
    get.setStoreName(stateStoreName)
    get.setKey("order");
    client.getState(get, (error, response) => {
        if (error) {
            console.log(error);
            res.status(500).send({message: error});
        } else {
            console.log('Found order!');
            console.log(String.fromCharCode.apply(null, response.getData()));
            res.status(200).send(String.fromCharCode.apply(null, response.getData()));
        }
    });
});

app.get( "/", ( req, res ) => {
    res.json({
        message: 'Hello World!'
      });
} );

// start the express server
app.listen( port, () => {
    // tslint:disable-next-line:no-console
    console.log( `server started at http://localhost:${ port }` );
} );
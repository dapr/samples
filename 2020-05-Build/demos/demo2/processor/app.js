const express = require('express');
const bodyParser = require('body-parser');
require('isomorphic-fetch');

// express 
const app = express();
app.use(bodyParser.json());

// cognitive API 
const apiToken = process.env.CS_TOKEN || "";
const region = process.env.AZ_REGION || "westus2";
const endpoint = `${region}.api.cognitive.microsoft.com`;
const apiURL = `https://${endpoint}/text/analytics/v2.1/sentiment`;

const port = 3002;

app.get("/", (req, res) => {
    res.status(200).send({message: "hi, nothing to see here, try => POST /sentiment-score"});
});

// service 
app.post("/sentiment-score", (req, res) => {
    let body = req.body;
    console.log("sentiment req: " + JSON.stringify(body));
    let lang = body.lang;
    let text = body.text;
    
    if (!text || !text.trim()) {
        res.status(400).send({error: "text required"});
        return;
    }
    if (!lang || !lang.trim()) {
        lang = "en";
    }

    const reqBody = {
        "documents": [{
            "id": "1",
            "language": lang,
            "text": text
          }]
      };

    fetch(apiURL, {
        method: "POST",
        body: JSON.stringify(reqBody),
        headers: {
            "Content-Type": "application/json",
            "Ocp-Apim-Subscription-Key": apiToken
        }
    }).then((_res) => {
        if (!_res.ok) {
            res.status(400).send({error: "error invoking cognitive service"});
            return;
        }
        return _res.json();
    }).then((_resp) => {
        const result = _resp.documents[0];
        console.log(JSON.stringify(result));
        res.status(200).send(result);
    }).catch((error) => {
        console.log(error);
        res.status(500).send({message: error});
    });
});

app.listen(port, () => console.log(`Node App listening on port ${port}!`));
const express = require("express");
const bodyParser = require("body-parser");
require("isomorphic-fetch");

// express
const app = express();
app.use(bodyParser.json());

// cognitive API
// The KEY 1 value from Azure Portal, Keys and Endpoint section
const apiToken = process.env.CS_TOKEN || "";
const region = process.env.AZ_REGION || "westus2";
// The Endpoint value from Azure Portal, Keys and Endpoint section
const endpoint = process.env.CS_ENDPOINT || "";
const apiURL = `${endpoint}text/analytics/v2.1/sentiment`;

const port = 3002;

app.get("/", (req, res) => {
  console.log("sentiment region: " + region);
  console.log("sentiment endpoint: " + endpoint);
  console.log("sentiment apiURL: " + apiURL);
  res.status(200).json({
    message: "hi, nothing to see here, try => POST /sentiment-score",
    region: region,
    endpoint: endpoint,
    apiURL: apiURL,
  });
});

// service
app.post("/sentiment-score", (req, res) => {
  let body = req.body;
  console.log("sentiment req: " + JSON.stringify(body));
  let lang = body.lang;
  let text = body.text;

  if (!text || !text.trim()) {
    res.status(400).send({ error: "text required" });
    return;
  }
  if (!lang || !lang.trim()) {
    lang = "en";
  }

  const reqBody = {
    documents: [
      {
        id: "1",
        language: lang,
        text: text,
      },
    ],
  };

  fetch(apiURL, {
    method: "POST",
    body: JSON.stringify(reqBody),
    headers: {
      "Content-Type": "application/json",
      "Ocp-Apim-Subscription-Key": apiToken,
    },
  })
    .then((_res) => {
      if (!_res.ok) {
        res.status(400).send({ error: "error invoking cognitive service" });
        return;
      }
      return _res.json();
    })
    .then((_resp) => {
      const result = _resp.documents[0];
      console.log(JSON.stringify(result));
      res.status(200).send(result);
    })
    .catch((error) => {
      console.log(error);
      res.status(500).send({ message: error });
    });
});

if (apiToken == "" || endpoint == "") {
  console.error("you must set CS_TOKEN and CS_ENDPOINT environment variables");
  throw new Error(
    "you must set CS_TOKEN and CS_ENDPOINT environment variables"
  );
} else {
   console.log("CS_TOKEN: " + apiToken);
   console.log("CS_ENDPOINT: " + endpoint);
}

app.listen(port, () => console.log(`Node App listening on port ${port}!`));

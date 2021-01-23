require("isomorphic-fetch");
const express = require("express");
const logger = require("./logger");
const bodyParser = require("body-parser");

// express
const port = 3002;
const app = express();
app.use(bodyParser.json());

// cognitive API
// The KEY 1 value from Azure Portal, Keys and Endpoint section
const apiToken = process.env.CS_TOKEN || "";
const region = process.env.AZ_REGION || "westus2";
// The Endpoint value from Azure Portal, Keys and Endpoint section
const endpoint = process.env.CS_ENDPOINT || "";
const apiURL = `${endpoint}text/analytics/v2.1/sentiment`;


app.get("/", (req, res) => {
  logger.debug("sentiment region: " + region);
  logger.debug("sentiment endpoint: " + endpoint);
  logger.debug("sentiment apiURL: " + apiURL);
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
  logger.debug("sentiment req: " + JSON.stringify(body));
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
      logger.debug(JSON.stringify(result));
      res.status(200).send(result);
    })
    .catch((error) => {
      logger.error(error);
      res.status(500).send({ message: error });
    });
});

if (apiToken == "" || endpoint == "") {
  logger.error("you must set CS_TOKEN and CS_ENDPOINT environment variables");
  throw new Error(
    "you must set CS_TOKEN and CS_ENDPOINT environment variables"
  );
} else {
  logger.debug("CS_TOKEN: " + apiToken);
  logger.debug("CS_ENDPOINT: " + endpoint);
}

app.listen(port, () => logger.info(`Node App listening on port ${port}!`));

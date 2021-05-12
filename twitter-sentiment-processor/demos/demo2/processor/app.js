// This app is called by the provider to score the tweets using cognitive
// services. When this app starts Dapr registers its name so other services
// can use Dapr to call this service.
require("isomorphic-fetch");
const express = require("express");
const logger = require("./logger");

// express
const port = 3002;
const app = express();
app.use(express.json());

// Cognitive Services API
// The KEY 1 value from Azure Portal, Keys and Endpoint section
const apiToken = process.env.CS_TOKEN || "";

// The Endpoint value from Azure Portal, Keys and Endpoint section
const endpoint = process.env.CS_ENDPOINT || "";

// The full URL to the sentiment service
const apiURL = `${endpoint}text/analytics/v2.1/sentiment`;

// Root get that just returns the configured values.
app.get("/", (req, res) => {
  logger.debug("sentiment endpoint: " + endpoint);
  logger.debug("sentiment apiURL: " + apiURL);
  res.status(200).json({
    message: "hi, nothing to see here, try => POST /sentiment-score",
    endpoint: endpoint,
    apiURL: apiURL,
  });
});

// This service provides this scoring method
app.post("/sentiment-score", (req, res) => {
  let body = req.body;
  let lang = body.lang;
  let text = body.text;
  logger.debug("sentiment req: " + JSON.stringify(body));

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

  // Call cognitive service to score the tweet
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
       // Send the response back to the other service.
      const result = _resp.documents[0];
      logger.debug(JSON.stringify(result));
      res.status(200).send(result);
    })
    .catch((error) => {
      logger.error(error);
      res.status(500).send({ message: error });
    });
});

// Make sure we have all the required information
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

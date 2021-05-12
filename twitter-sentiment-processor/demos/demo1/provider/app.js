// This app is called by the Dapr each time a Tweet is received. In later
// demos this calls a service to score the tweet. Now it just stores the
// tweet in a state store.
require("isomorphic-fetch");
const logger = require("./logger");
const express = require("express");

// express
const port = 3001;
const app = express();
app.use(express.json());

// Dapr
const daprPort = process.env.DAPR_HTTP_PORT || "3500";

// The Dapr endpoint for the state store component to store the tweets.
const stateEndpoint = `http://localhost:${daprPort}/v1.0/state/tweet-store`;

// store state
var saveContent = function (obj) {
  return new Promise(function (resolve, reject) {
    if (!obj || !obj.id) {
      reject({ message: "invalid content" });
      return;
    }
    const state = [{ key: obj.id, value: obj }];
    fetch(stateEndpoint, {
      method: "POST",
      body: JSON.stringify(state),
      headers: { "Content-Type": "application/json" },
    })
      .then((_res) => {
        if (!_res.ok) {
          logger.debug(_res.statusText);
          reject({ message: "error saving content" });
        } else {
          resolve(obj);
        }
      })
      .catch((error) => {
        logger.error(error);
        reject({ message: error });
      });
  });
};

// tweets handler
app.post("/tweets", (req, res) => {
  logger.debug("/tweets invoked...");
  const tweet = req.body;
  if (!tweet) {
    res.status(400).send({ error: "invalid content" });
    return;
  }

  let obj = {
    id: tweet.id_str,
    author: tweet.user.screen_name,
    author_pic: tweet.user.profile_image_url_https,
    content: tweet.full_text || tweet.text, // if extended then use it
    lang: tweet.lang,
    published: tweet.created_at,
    sentiment: 0.5, // default to neutral sentiment
  };

  saveContent(obj)
    .then(function (rez) {
      logger.debug("rez: " + JSON.stringify(rez));
      res.status(200).send({});
    })
    .catch(function (error) {
      logger.error(error.message);
      res.status(500).send(error);
    });
});

app.listen(port, () => console.log(`Port: ${port}!`));

// This app is called by the Dapr each time a Tweet is received. In demo1 this
// service just saved the tweets to the state store. Now we are going to call
// another service via Dapr to score the tweet using direct invocation. Once
// the tweet is processed it is posted to a pub/sub service to be read by
// another service.
require("isomorphic-fetch");
require("es6-promise").polyfill();
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

// The Dapr endpoint for the Pub/Sub component used to communicate with other
// services in a loosely coupled way. Tweets is the name of the component and
// processed is the name of the topic to which other services will subscribe.
const pubEndpoint = `http://localhost:${daprPort}/v1.0/publish/tweet-pubsub/scored`;

// The Dapr endpoint used to invoke the sentiment-score method on the processor service.
// We are able to invoke the service using its appId processor
const serviceEndpoint = `http://localhost:${daprPort}/v1.0/invoke/processor/method/sentiment-score`;

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
      headers: {
        "Content-Type": "application/json",
        traceparent: obj.trace_parent,
        tracestate: obj.trace_state,
      },
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
    trace_state: req.get("tracestate"),
    trace_parent: req.get("traceparent"),
    sentiment: 0.5, // default to neutral sentiment
  };

  logger.debug("obj: " + JSON.stringify(obj));

  scoreSentiment(obj)
    .then(saveContent)
    .then(publishContent)
    .then(function (rez) {
      logger.debug("rez: " + JSON.stringify(rez));
      res.status(200).send({});
    })
    .catch(function (error) {
      logger.error(error.message);
      res.status(500).send(error);
    });
});

// score sentiment
var scoreSentiment = function (obj) {
  return new Promise(function (resolve, reject) {
    fetch(serviceEndpoint, {
      method: "POST",
      body: JSON.stringify({ lang: obj.lang, text: obj.content }),
      headers: {
        "Content-Type": "application/json",
        traceparent: obj.trace_parent,
        tracestate: obj.trace_state,
      },
    })
      .then((_res) => {
        if (!_res.ok) {
          logger.debug(_res.statusText);
          reject({ message: "error invoking service" });
        } else {
          return _res.json();
        }
      })
      .then((_res) => {
        logger.debug("_res: " + JSON.stringify(_res));
        obj.sentiment = _res.score;
        resolve(obj);
      })
      .catch((error) => {
        logger.debug(error);
        reject({ message: error });
      });
  });
};

// publish scored tweets
var publishContent = function (obj) {
  return new Promise(function (resolve, reject) {
    if (!obj || !obj.id) {
      reject({ message: "invalid content" });
      return;
    }
    fetch(pubEndpoint, {
      method: "POST",
      body: JSON.stringify(obj),
      headers: {
        "Content-Type": "application/json",
        traceparent: obj.trace_parent,
        tracestate: obj.trace_state,
      },
    })
      .then((_res) => {
        if (!_res.ok) {
          logger.debug(_res.statusText);
          reject({ message: "error publishing content" });
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

app.listen(port, () => logger.info(`Port: ${port}!`));

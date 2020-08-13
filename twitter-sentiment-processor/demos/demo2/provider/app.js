const express = require('express');
const bodyParser = require('body-parser');
require('es6-promise').polyfill();
require('isomorphic-fetch');

// express 
const app = express();
app.use(bodyParser.json());
const port = 3001;

// dapr 
const daprPort = process.env.DAPR_HTTP_PORT || "3500";
const serviceEndpoint = `http://localhost:${daprPort}/v1.0/invoke/processor/method/sentiment-score`;
const stateEndpoint = `http://localhost:${daprPort}/v1.0/state/tweet-store`;
const pubEndpoint = `http://localhost:${daprPort}/v1.0/publish/processed`;


// publish scored tweets 
var publishContent = function(obj) {
    return new Promise(
        function(resolve, reject) {
            if (!obj || !obj.id) {
                reject({message: "invalid content"});
                return;
            }
            fetch(pubEndpoint, {
                method: "POST",
                body: JSON.stringify(obj),
                headers: { 
                    "Content-Type": "application/json" 
                }
            }).then((_res) => {
                if (!_res.ok) {
                    console.log(_res.statusText);
                    reject({message: "error publishing content"});
                }else{
                    resolve(obj)
                }
            }).catch((error) => {
                console.log(error);
                reject({message: error});
            });
        }
    );
};

// store state 
var saveContent = function(obj) {
    return new Promise(
        function(resolve, reject) {
            if (!obj || !obj.id) {
                reject({message: "invalid content"});
                return;
            }
            const state = [{ key: obj.id, value: obj }];
            fetch(stateEndpoint, {
                method: "POST",
                body: JSON.stringify(state),
                headers: { 
                    "Content-Type": "application/json" 
                }
            }).then((_res) => {
                if (!_res.ok) {
                    console.log(_res.statusText);
                    reject({message: "error saving content"});
                }else{
                    resolve(obj)
                }
            }).catch((error) => {
                console.log(error);
                reject({message: error});
            });
        }
    );
};

// score sentiment
var scoreSentiment = function(obj) {
    return new Promise(
        function(resolve, reject) {
            fetch(serviceEndpoint, {
                method: "POST",
                body: JSON.stringify({lang: obj.lang, text: obj.content}),
                headers: { 
                    "Content-Type": "application/json"
                }
            }).then((_res) => {
                if (!_res.ok) {
                    console.log(_res.statusText);
                    reject({message: "error invoking service"});
                }else{
                    return _res.json();
                }
            }).then((_res) => {
                console.log(_res);
                obj.sentiment = _res.score;
                resolve(obj)
            }).catch((error) => {
                console.log(error);
                reject({message: error});
            });
        }
    );
};

// tweets handler 
app.post("/tweets", (req, res) => {
    console.log("/tweets invoked...");
    const tweet = req.body;
    if (!tweet) {
        res.status(400).send({error: "invalid content"});
        return;
    }

    // let ctx 

    let obj = {
        id: tweet.id_str,
        author: tweet.user.screen_name,
        author_pic: tweet.user.profile_image_url_https,
        content: tweet.full_text || tweet.text, // if extended then use it
        lang: tweet.lang,
        published: tweet.created_at,
        sentiment: 0.5 // default to neutral sentiment 
    };

    scoreSentiment(obj)
        .then(saveContent)
        .then(publishContent)
        .then(function(rez) {
            console.log(rez);
            res.status(200).send({});
        })
        .catch(function (error) {
            console.log(error.message);
            res.status(500).send(error);
        });
});


app.listen(port, () => console.log(`Port: ${port}!`));
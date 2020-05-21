const express = require('express');
const bodyParser = require('body-parser');
require('isomorphic-fetch');

// express 
const app = express();
app.use(bodyParser.json());
const port = 3001;

// dapr 
const daprPort = process.env.DAPR_HTTP_PORT || "3500";
const stateEndpoint = `http://localhost:${daprPort}/v1.0/state/tweet-store`;

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
                headers: { "Content-Type": "application/json" }
            }).then((_res) => {
                if (!_res.ok) {
                    console.log(_res.statusText);
                    reject({message: "error saving content"});
                }else{
                    resolve(obj)
                }
            }).catch((error) => {
                reject({message: error});
            });
        }
    );
};

// tweets handler 
app.post('/tweets', (req, res) => {
    const tweet = req.body;
    if (!tweet) {
        res.status(400).send({error: "invalid content"});
        return;
    }

    let obj = {
        id: tweet.id_str,
        author: tweet.user.screen_name,
        author_pic: tweet.user.profile_image_url_https,
        content: tweet.full_text || tweet.text, // if extended then use it
        lang: tweet.lang,
        published: tweet.created_at,
        sentiment: 0.5 // default to neutral sentiment 
    };

    saveContent(obj)
        .then(function(fulfilled) {
            console.log(fulfilled);
            res.status(200).send({});
        })
        .catch(function (error) {
            console.log(error.message);
            res.status(500).send(error);
        });
});


app.listen(port, () => console.log(`Port: ${port}!`));
# Demo2


## provider 


## processor

Start the service in Dapr with explicit port so we can invoke it later:

```shell
dapr run node app.js \
         --log-level debug \
         --app-id processor \
         --app-port 3000 \
         --protocol http \
         --port 3500
```

Invoke it from curl or another service will look like this:

```shell
curl -d '{"lang":"en", "text":"I am so happy this worked"}' \
     -H "Content-type: application/json" \
     "http://localhost:3500/v1.0/invoke/processor/method/sentiment-score"
```


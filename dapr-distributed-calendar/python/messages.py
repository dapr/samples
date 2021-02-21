import flask
from flask import request, jsonify
from flask_cors import CORS
import json
import sys
import time

from dapr.clients import DaprClient

app = flask.Flask(__name__)
CORS(app)

# dapr calls this endpoint to register the subscriber configuration
# an alternative way would to be declare this inside a config yaml file
@app.route('/dapr/subscribe', methods=['GET'])
def subscribe():
    subscriptions = [{'pubsubname': 'pubsub',
                      'topic': 'events-topic',
                      'route': 'getmsg'}]
    return jsonify(subscriptions)

emailTo = 'js26@iitbbs.ac.in'
subject = 'Testing Dapr binding integration'
data = ''
binding_name = 'sendgrid'

# subscriber acts as a listener for the topic events-topic
@app.route('/getmsg', methods=['POST'])
def subscriber():
    print(request.json, flush=True)
    jsonRequest = request.json
    data = jsonRequest["data"]["message"]
    print(data, flush=True)
    send_email()

# send_email sends the json payload obtained from pubsub
# to the dapr output binding for SendGrid
def send_email():
    with DaprClient() as d:
            
        req_data = {
            'metadata': {
                'emailTo': emailTo,
                'subject': subject
            },
            'data': data
        }

        print(req_data, flush=True)

        # Create a typed message with content type and body
        resp = d.invoke_binding(binding_name, 'create', json.dumps(req_data))
        print(resp, flush=True)
            

app.run()
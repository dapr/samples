import os

from flask import Flask, render_template, request, jsonify
from flask_socketio import SocketIO

APP_PORT = os.getenv("APP_PORT", "8083")
PUBSUB_NAME = os.getenv("PUBSUB_NAME", "processed")
TOPIC_NAME  = os.getenv("TOPIC_NAME", "processed-tweets")


app = Flask(__name__)
socketio = SocketIO(app)


@app.route('/dapr/subscribe', methods=['GET'])
def subscribe():
    subs = [
        {
            'pubsubname': PUBSUB_NAME,
            'topic': TOPIC_NAME,
            'route': TOPIC_NAME,
        },
    ]
    return jsonify(subs)


@app.route('/')
def index():
    return render_template('index.html')


# Subscribe processed-tweets topic
@app.route('/' + TOPIC_NAME, methods=['POST', 'PUT'])
def topic_tweets():
    event = request.json
    socketio.emit('message', event['data'], broadcast=True)
    return '', 200


@socketio.on('connect')
def socket_connect():
    print('connected', flush=True)


def main():
    socketio.run(app, port=APP_PORT)


if __name__ == "__main__":
    main()

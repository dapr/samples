import logging
import os
import time

from flask import Flask, request

APP_PORT = os.getenv("APP_PORT", "3003")

app = Flask(__name__)


@app.route("/payments/charge", methods=["POST"])
def charge():
    logging.info(f"Charging payment for order: {request.json}")

    # Simulate work
    time.sleep(1)

    return '', 200


@app.route("/payments/refund", methods=["POST"])
def refund():
    logging.info(f"Refunding payment for order: {request.json}")

    # Simulate work
    time.sleep(1)

    return '', 200


@app.route("/", methods=["GET"])
@app.route("/healthz", methods=["GET"])
def hello():
    return f"Hello from {__name__}", 200


def main():
    # Start the Flask app server
    app.run(port=APP_PORT, debug=True, use_reloader=False)


if __name__ == "__main__":
    logging.basicConfig(
        format='%(asctime)s.%(msecs)03d %(levelname)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        level=logging.INFO)
    main()

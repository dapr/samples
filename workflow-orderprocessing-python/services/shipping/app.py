import logging
import os
import time

from flask import Flask, request

APP_PORT = os.getenv("APP_PORT", "3004")

app = Flask(__name__)

is_deactivated = False


@app.route("/shipping/ship", methods=["POST"])
def ship():
    if is_deactivated:
        return "The shipping service is currently deactivated for routine maintenance.", 503
    logging.info(f"Shipping order: {request.json}")

    # Simulate work
    time.sleep(1)

    return '', 200


@app.route("/shipping/deactivate", methods=["POST"])
def deactivate():
    global is_deactivated
    is_deactivated = True
    logging.warning("The shipping service has been deactivated for routine maintenance.")
    return '', 200


@app.route("/shipping/activate", methods=["POST"])
def activate():
    global is_deactivated
    is_deactivated = False
    logging.info("The shipping service has been (re)activated.")
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

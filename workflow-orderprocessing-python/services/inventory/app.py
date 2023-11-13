import logging
import os
import time
from typing import Dict

from flask import Flask, g, request

APP_PORT = os.getenv("APP_PORT", "3002")

app = Flask(__name__)


@app.route("/inventory", methods=["GET"])
def get_inventory():
    logging.info("Getting inventory")
    if not hasattr(g, 'inventory'):
        restock_inventory()
    inventory: Dict[str, int] = g.inventory
    return inventory, 200


@app.route("/inventory/reserve", methods=["POST"])
def reserve_inventory():
    logging.info(f"Reserving inventory: {request.json}")

    order = request.json
    items = order['items']
    id = order['id']

    if not hasattr(g, 'inventory'):
        restock_inventory()

    inventory: Dict[str, int] = g.inventory

    # Check if we have enough inventory to fulfill the order
    for item in items:
        if item not in inventory or inventory[item] <= 0:
            return {
                "id": id,
                "success": False,
                "message": "Out of stock",
            }, 200

    # Update the inventory
    for item in items:
        inventory[item] = inventory[item] - 1

    # Simulate work
    time.sleep(1)

    return {
        "id": id,
        "success": True,
        "message": ""
    }, 200


@app.route("/inventory/restock", methods=["POST"])
def restock_inventory():
    logging.info("Restocking inventory")
    inventory = dict[str, int](
        {
            'milk': 10,
            'bread': 10,
            'apples': 10,
            'oranges': 10,
            'iPhone': 10,
        }
    )
    g.inventory = inventory


@app.route("/", methods=["GET"])
@app.route("/healthz", methods=["GET"])
def hello():
    return f"Hello from {__name__}", 200


def main():
    # Start the Flask app server
    app.run(port=APP_PORT, debug=True, use_reloader=False)
    app.post('/inventory/restock')


if __name__ == "__main__":
    logging.basicConfig(
        format='%(asctime)s.%(msecs)03d %(levelname)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        level=logging.INFO)
    main()

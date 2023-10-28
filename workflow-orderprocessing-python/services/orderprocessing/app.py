import json
import logging
import os
import random
import string
from dataclasses import dataclass
from datetime import timedelta

import dapr.ext.workflow as wf
from dapr.clients import DaprClient
from flask import Flask, request, url_for
from markupsafe import escape

APP_PORT = os.getenv("APP_PORT", "3000")
PUBSUB_NAME = os.getenv("PUBSUB_NAME", "orders")
TOPIC_NAME = os.getenv("TOPIC_NAME", "notifications")

APPROVAL_THRESHOLD = 1000.0
APPROVAL_TIMEOUT = timedelta(hours=24)

app = Flask(__name__)


@dataclass
class Order:
    id: str
    customer: str
    items: list
    total: float


@dataclass
class OrderResult:
    id: str
    success: bool
    message: str


@dataclass
class InventoryResult:
    id: str
    success: bool
    message: str


@dataclass
class Approval:
    approver: str
    approved: bool

    @staticmethod
    def from_dict(dict):
        return Approval(**dict)


def process_order_workflow(ctx: wf.DaprWorkflowContext, order: Order):
    yield ctx.call_activity(notify, input=f"Received order for {order.customer}: {order.items}. Total = {order.total}")

    # Call into the inventory service to reserve the items in this order
    result = yield ctx.call_activity(reserve_inventory, input=order)
    if not result.success:
        yield ctx.call_activity(notify, input=f"Inventory failed for order: {result.message}")
        return OrderResult(order.id, False, result.message)

    yield ctx.call_activity(notify, input=f"Reserved inventory for order: {order.items}")

    # Orders over $1,000 require human approval
    if order.total >= APPROVAL_THRESHOLD:
        approval_deadline = ctx.current_utc_datetime + APPROVAL_TIMEOUT
        yield ctx.call_activity(
            notify,
            input=f"Waiting for approval since order >= {APPROVAL_THRESHOLD}. Deadline = {approval_deadline}.")

        # Block the workflow on either an approval event or a timeout
        approval_task = ctx.wait_for_external_event("approval")
        timeout_expired_task = ctx.create_timer(approval_deadline)
        winner = yield wf.when_any([approval_task, timeout_expired_task])
        if winner == timeout_expired_task:
            message = "Approval deadline expired."
            yield ctx.call_activity(notify, input=message)
            return OrderResult(order.id, False, message)

        # Check the approval result
        approval: Approval = yield approval_task
        if not approval.approved:
            message = f"Order was rejected by {approval.approver}."
            yield ctx.call_activity(notify, input=message)
            return OrderResult(order.id, False, message)

        yield ctx.call_activity(notify, input=f"Order was approved by {approval.approver}.")

    # Submit the order to the payment service
    yield ctx.call_activity(submit_payment, input=order)
    yield ctx.call_activity(notify, input="Payment was processed successfully")

    # Submit the order for shipping
    try:
        yield ctx.call_activity(submit_order_to_shipping, input=order)
    except Exception as e:
        # Shipping failed, so we need to refund the payment
        yield ctx.call_activity(notify, input=f"Error submitting order for shipping: {str(e)}")
        yield ctx.call_activity(refund_payment, input=order)
        yield ctx.call_activity(notify, input="Payment refunded")

        # Allow the workflow to fail with the original failure details
        raise

    yield ctx.call_activity(notify, input="Order submitted for shipping")
    return OrderResult(order.id, True, "Order processed successfully")


def notify(ctx: wf.WorkflowActivityContext, message: str):
    logging.info(f"Sending notification: {message}")
    with DaprClient() as d:
        d.publish_event(PUBSUB_NAME, TOPIC_NAME, json.dumps({
            "order_id": ctx.workflow_id,
            "message": message
        }))


def reserve_inventory(_, order: Order) -> InventoryResult:
    logging.info(f"Reserving inventory for order: {order}")
    with DaprClient() as d:
        resp = d.invoke_method("inventory", "inventory/reserve",  http_verb="POST",  data=json.dumps(order.__dict__))
        if resp.status_code != 200:
            raise Exception(f"Error calling inventory service: {resp.status_code}")
        inventory_result = InventoryResult(**json.loads(resp.data.decode("utf-8")))
        logging.info(f"Inventory result: {inventory_result}")
        return inventory_result


def submit_payment(_, order: Order):
    logging.info(f"Submitting payment for order: {order}")
    with DaprClient() as d:
        resp = d.invoke_method("payments", "payments/charge",  http_verb="POST",  data=json.dumps(order.__dict__))
        if resp.status_code != 200:
            raise Exception(f"Error calling payment service: {resp.status_code}: {resp.text()}")


def submit_order_to_shipping(_, order: Order):
    logging.info(f"Submitting order to shipping: {order}")
    with DaprClient() as d:
        resp = d.invoke_method("shipping", "shipping/ship",  http_verb="POST",  data=json.dumps(order.__dict__))
        if resp.status_code != 200:
            raise Exception(f"Error calling shipping service: {resp.status_code}: {resp.text()}")


def refund_payment(_, order: Order):
    logging.info(f"Refunding payment for order: {order}")
    with DaprClient() as d:
        resp = d.invoke_method("payments", "payments/refund",  http_verb="POST",  data=json.dumps(order.__dict__))
        if resp.status_code != 200:
            raise Exception(f"Error calling payment service: {resp.status_code}: {resp.text()}")


# API to submit a new order
@app.route("/orders", methods=["POST"])
def submit_order():

    request_data = request.get_json()
    if not request_data:
        return """Invalid request. Should be in the form of {
            \"customer\": \"joe\", \"items\": [\"apples\", \"oranges\"], \"total\": 100.0}""", 400
    if not request_data.get("customer"):
        return "Missing customer name", 400
    if not request_data.get("items"):
        return "Missing items", 400
    if not request_data.get("total"):
        return "Missing total", 400

    order = Order(
        None,
        request_data.get("customer"),
        request_data.get("items"),
        request_data.get("total"))

    # Generate a unique ID for this order
    random_suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=5))
    order.id = f"order_{order.customer.lower()}_{random_suffix}"

    wf_client = wf.DaprWorkflowClient()
    instance_id = wf_client.schedule_new_workflow(
        process_order_workflow,
        input=order,
        instance_id=order.id)

    logging.info(f"Started workflow instance: {instance_id}")
    return f"Order received. ID = '{escape(instance_id)}'", 202, {
        'Location': url_for('check_order_status', order_id=instance_id, _external=True)
    }


@app.route("/orders/<order_id>", methods=["GET"])
def check_order_status(order_id):
    wf_client = wf.DaprWorkflowClient()
    state = wf_client.get_workflow_state(order_id)
    if not state:
        return f"Order not found: {escape(order_id)}", 404

    order_info = json.loads(state.serialized_input)
    order = Order(
        order_info.get('id'),
        order_info.get('customer'),
        order_info.get('items'),
        order_info.get('total'))
    resp = {
        "id": state.instance_id,
        "details": order.__dict__,
        "status": state.runtime_status.name,
        "created_time": state.created_at.isoformat(),
        "last_updated_time": state.last_updated_at.isoformat(),
    }

    if state.serialized_output:
        order_result_details = json.loads(state.serialized_output)
        order_result = OrderResult(
            order_result_details.get('id'),
            order_result_details.get('success'),
            order_result_details.get('message'))
        resp["order_result"] = order_result.__dict__

    if state.failure_details:
        resp["failure_details"] = {
            "message": state.failure_details.message,
            "error_type": state.failure_details.error_type,
            "stack_trace": state.failure_details.stack_trace
        }

    return resp, 200


@app.route("/orders/<order_id>/approve", methods=["POST"])
def approve_order(order_id):
    request_data = request.get_json()
    if not request_data:
        return """Invalid request. Should be in the form of { \"approver\": \"joe\", \"approved\": true }""", 400
    if not request_data.get("approver"):
        return "Missing approver name", 400
    if "approved" not in request_data:
        return "Missing approved flag", 400

    approval = Approval(
        request_data.get("approver"),
        request_data.get("approved"))

    wf_client = wf.DaprWorkflowClient()
    wf_client.raise_workflow_event(order_id, "approval", data=approval)

    return f"Approval sent for order: {escape(order_id)}", 200


@app.route("/", methods=["GET"])
@app.route("/healthz", methods=["GET"])
def hello():
    return f"Hello from {__name__}", 200


def main():
    # Start the workflow runtime
    logging.info("Starting workflow runtime...")
    wf_runtime = wf.WorkflowRuntime()  # host/port comes from env vars
    wf_runtime.register_workflow(process_order_workflow)
    wf_runtime.register_activity(notify)
    wf_runtime.register_activity(reserve_inventory)
    wf_runtime.register_activity(submit_payment)
    wf_runtime.register_activity(submit_order_to_shipping)
    wf_runtime.register_activity(refund_payment)
    wf_runtime.start()  # non-blocking

    # Start the Flask app server
    app.run(port=APP_PORT, debug=False, use_reloader=False)

    # Stop the workflow runtime to allow the process to terminate
    wf_runtime.shutdown()


if __name__ == "__main__":
    logging.basicConfig(
        format='%(asctime)s.%(msecs)03d %(levelname)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        level=logging.INFO)
    main()

using Dapr.Workflow;
using DurableTask.Core.Exceptions;

using CheckoutServiceWorkflowSample.Activities;
using CheckoutServiceWorkflowSample.Models;

namespace CheckoutServiceWorkflowSample.Workflows
{
    public class CheckoutWorkflow : Workflow<CustomerOrder, CheckoutResult>
    {
        public override async Task<CheckoutResult> RunAsync(WorkflowContext context, CustomerOrder order)
        {
            string orderId = context.InstanceId;

            // Order Received 
            await context.CallActivityAsync(
                nameof(NotifyActivity),
                new Notification($"Received order {orderId} for {order.OrderItem.Quantity} {order.OrderItem.Name}"));


            // Check Product Inventory  

            context.SetCustomStatus("Checking product inventory");

            var inventoryResult = await context.CallActivityAsync<InventoryResult>(
                nameof(CheckInventoryActivity),
                order);

            if (!inventoryResult.Available)
            {
                // End the workflow here since we don't have sufficient inventory
                await context.CallActivityAsync(
                    nameof(NotifyActivity),
                    new Notification($"{orderId} cancelled: Insufficient inventory available"));

                context.SetCustomStatus("Insufficient inventory to fulfill order");

                return new CheckoutResult(Processed: false);
            }

            var paymentRequest = new PaymentRequest(RequestId: orderId, order.Name, order.OrderItem.Name, inventoryResult.TotalCost);
            // Process payment for the order 
            try
            {

                context.SetCustomStatus("Payment processing");

                var paymentResponse = await context.CallActivityAsync<PaymentResponse>(
                    nameof(ProcessPaymentActivity),
                    paymentRequest);

                if (!paymentResponse.Success)
                {
                    // End the workflow here since we were unable to process payment 
                    await context.CallActivityAsync(
                        nameof(NotifyActivity),
                        new Notification($"{orderId} cancelled: Payment processing failed"));

                    context.SetCustomStatus("Payment failed");

                    return new CheckoutResult(Processed: false);
                }

            }
            catch (Exception ex)
            {

                if (ex.InnerException is TaskFailedException)
                {
                    await context.CallActivityAsync(
                        nameof(NotifyActivity),
                        new Notification($"Processing payment for {orderId} failed due to {ex.Message}"));
                    context.SetCustomStatus("Payment failed to process");
                    return new CheckoutResult(Processed: false);
                }
            }

            // Decrement inventory to account for execution of purchase 
            try
            {
                await context.CallActivityAsync(
                    nameof(UpdateInventoryActivity),
                    order);

                context.SetCustomStatus("Updating inventory as a result of order payment");
            }
            catch (Exception ex)
            {
                if (ex.InnerException is TaskFailedException)
                {
                    await context.CallActivityAsync(
                        nameof(NotifyActivity),
                        new Notification($"Checkout for order {orderId} failed! Processing payment refund."));

                    context.SetCustomStatus("Issuing refund due to insufficient inventory to fulfill");

                    await context.CallActivityAsync<PaymentResponse>(
                    nameof(ProcessPaymentActivity),
                    paymentRequest);

                    context.SetCustomStatus("Payment refunded");

                    return new CheckoutResult(Processed: false);
                }
            }

            await context.CallActivityAsync(
                nameof(NotifyActivity),
                new Notification($"Checkout for order {orderId} has completed!"));

            context.SetCustomStatus("Checkout completed");

            return new CheckoutResult(Processed: true);
        }
    }
}
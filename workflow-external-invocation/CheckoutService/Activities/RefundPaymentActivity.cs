using Dapr.Workflow;
using CheckoutServiceWorkflowSample.Models;

namespace CheckoutServiceWorkflowSample.Activities
{
    public class RefundPaymentActivity : WorkflowActivity<PaymentRequest, object?>
    {
        readonly ILogger _logger;

        public RefundPaymentActivity(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<RefundPaymentActivity>();
        }

        public override async Task<object?> RunAsync(WorkflowActivityContext context, PaymentRequest req)
        {
            _logger.LogInformation(
                "Refunding payment: {RequestId} for ${totalCost}",
                req.RequestId,
                req.TotalCost);

            // Simulate slow processing
            await Task.Delay(TimeSpan.FromSeconds(5));

            _logger.LogInformation(
                "Payment for request ID '{RequestId}' refunded successfully",
                req.RequestId);

            return null;
        }
    }
}
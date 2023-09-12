using Dapr.Workflow;
using Dapr.Client;
using CheckoutServiceWorkflowSample.Models;

namespace CheckoutServiceWorkflowSample.Activities
{
    public class CheckInventoryActivity : WorkflowActivity<CustomerOrder, InventoryResult>
    {
        readonly ILogger _logger;
        readonly DaprClient _client;
        static readonly string storeName = "inventorystore";

        public CheckInventoryActivity(ILoggerFactory loggerFactory, DaprClient client)
        {
            _logger = loggerFactory.CreateLogger<CheckInventoryActivity>();
            _client = client;
        }

        public override async Task<InventoryResult> RunAsync(WorkflowActivityContext context, CustomerOrder req)
        {
            // Retrieve Inventory from Dapr State Store  
            var product = await _client.GetStateAsync<InventoryItem>(storeName, req.OrderItem.Name.ToLowerInvariant());

            // If the inventory db has not been seeded, return insufficient inventory result 
            if (product == null)
            {
                return new InventoryResult(false, null, 0);
            }

            _logger.LogInformation("Status: Found {quantity} {name} in inventory", product.Quantity, product.Name);

            // Calculate order total 
            var orderTotal = product.PerItemCost * req.OrderItem.Quantity;

            // See if there're enough items to purchase
            if (product.Quantity >= req.OrderItem.Quantity)
            {
                // Simulate slow processing
                await Task.Delay(TimeSpan.FromSeconds(5));

                return new InventoryResult(true, product, orderTotal);
            }

            return new InventoryResult(false, product, orderTotal);
        }
    }
}
using Dapr.Client;
using Dapr.Workflow;
using CheckoutServiceWorkflowSample.Models;

namespace CheckoutServiceWorkflowSample.Activities
{
    class UpdateInventoryActivity : WorkflowActivity<CustomerOrder, object?>
    {
        static readonly string storeName = "inventorystore";
        readonly ILogger _logger;
        readonly DaprClient _client;

        public UpdateInventoryActivity(ILoggerFactory loggerFactory, DaprClient client)
        {
            _logger = loggerFactory.CreateLogger<UpdateInventoryActivity>();
            _client = client;
        }

        public override async Task<object?> RunAsync(WorkflowActivityContext context, CustomerOrder req)
        {
            // Simulate slow processing
            await Task.Delay(TimeSpan.FromSeconds(10));

            // Determine if there are enough Items for purchase
            var product = await _client.GetStateAsync<InventoryItem>(storeName, req.OrderItem.Name.ToLowerInvariant());

            if ((product.Quantity - req.OrderItem.Quantity) < 0)
            {
                throw new InvalidOperationException("Requested order quantity no longer available in inventory");
            }

            var newQuantity = product.Quantity - req.OrderItem.Quantity;

            // Update the statestore with the new amount of the item
            await _client.SaveStateAsync(
                storeName,
                req.OrderItem.Name.ToLowerInvariant(),
                new InventoryItem(ProductId: product.ProductId, Name: req.OrderItem.Name, PerItemCost: product.PerItemCost, Quantity: newQuantity));


            _logger.LogInformation("Stock update: {quantity} {name} left in stock", newQuantity, product.Name);

            return null;
        }
    }
}
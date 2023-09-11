using Dapr.Client;
using Microsoft.AspNetCore.Mvc;
using CheckoutServiceWorkflowSample.Models;

namespace WorkflowSample.Controllers;

[ApiController]
[Route("[controller]")]
public class InventoryController : ControllerBase
{
    private readonly ILogger<InventoryController> _logger;
    private readonly DaprClient _client;
    private static readonly string storeName = "inventorystore";
    private readonly static string[] itemKeys = new[] { "item1", "item2" };

    public InventoryController(ILogger<InventoryController> logger, DaprClient client)
    {
        _logger = logger;
        _client = client;
    }

    [HttpGet]
    public async Task<IActionResult> GetInventory()
    {
        var inventory = new List<InventoryItem>();

        foreach (var itemKey in itemKeys)
        {
            var item = await _client.GetStateAsync<InventoryItem>(storeName, itemKey.ToLowerInvariant());
            inventory.Add(item);
        }

        return new OkObjectResult(inventory);
    }

    [HttpPost("restock")]
    public async void RestockInventory()
    {
        var baseInventory = new List<InventoryItem>
        {
            new InventoryItem(ProductId: 0, Name: itemKeys[0], PerItemCost: 20, Quantity: 100),
            new InventoryItem(ProductId: 1, Name: itemKeys[1], PerItemCost: 20, Quantity: 100),
        };

        foreach (var item in baseInventory)
        {
            await _client.SaveStateAsync(storeName, item.Name.ToLowerInvariant(), item);
        }

        _logger.LogInformation("Inventory Restocked!");
    }

    [HttpDelete]
    public async void ClearInventory()
    {
        var baseInventory = new List<InventoryItem>
        {
            new InventoryItem(ProductId: 0, Name: itemKeys[0], PerItemCost: 20, Quantity: 100),
            new InventoryItem(ProductId: 1, Name: itemKeys[1], PerItemCost: 20, Quantity: 100),
        };

        foreach (var item in baseInventory)
        {
            await _client.SaveStateAsync(storeName, item.Name.ToLowerInvariant(), item);
        }

        _logger.LogInformation("Cleared inventory !");
    }
}

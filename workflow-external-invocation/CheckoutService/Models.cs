namespace CheckoutServiceWorkflowSample.Models
{
    // Orders
    public record OrderItem(string Name, int Quantity);
    public record CustomerOrder(string Name, OrderItem OrderItem);

    // Inventory
    public record InventoryItem(int ProductId, string Name, int PerItemCost, int Quantity);
    public record InventoryResult(bool Available, InventoryItem? productItem, int TotalCost);

    // Payment 
    public record PaymentRequest(string RequestId, string Name, string OrderItem, int TotalCost);
    public record PaymentResponse(bool Success);
    public record CheckoutResult(bool Processed);
}
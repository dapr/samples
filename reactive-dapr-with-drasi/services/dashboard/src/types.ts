export interface StockIssueItem {
  orderId: string
  customerId: string
  orderStatus: string
  productId: string
  stockOnHand: number
  quantity: number
  productName: string
}

export interface GoldCustomerDelay {
  orderId: string
  customerId: string
  customerName: string
  customerEmail: string
  orderStatus: string
  waitingSince: string
}
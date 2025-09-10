export interface CatalogueItem {
  productId: number;
  productName: string;
  productDescription: string;
  avgRating: number;
  reviewCount: number;
}

export interface CatalogueListResponse {
  items: CatalogueItem[];
  total: number;
}
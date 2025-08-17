import axios from 'axios';
import { CatalogueItem, CatalogueListResponse } from '../types';

const API_BASE_URL = '/catalogue-service/api';

export const catalogueApi = {
  async getAllProducts(): Promise<CatalogueListResponse> {
    const response = await axios.get<CatalogueListResponse>(`${API_BASE_URL}/catalogue`);
    return response.data;
  },

  async getProduct(productId: number): Promise<CatalogueItem> {
    const response = await axios.get<CatalogueItem>(`${API_BASE_URL}/catalogue/${productId}`);
    return response.data;
  }
};
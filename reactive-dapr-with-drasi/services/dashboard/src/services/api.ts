import axios, { AxiosError } from 'axios'
import { config } from '../config'

const API_BASE_URL = config.apiBaseUrl

interface ApiErrorResponse {
  detail?: string;
}

export const productsApi = {
  incrementStock: async (productId: string, quantityToIncrement: number) => {
    try {
      const response = await axios.put(`${API_BASE_URL}/products-service/products/${productId}/increment`, {
        quantity: quantityToIncrement
      });
      console.log('Stock incremented successfully:', response.data);
      return { success: true, data: response.data };
    } catch (error) {
      console.error('Error incrementing stock:', error);
      let errorMessage = 'An unknown error occurred';
      let errorDetail: string | undefined = undefined;
      if (axios.isAxiosError(error)) {
        const axiosError = error as AxiosError<ApiErrorResponse>;
        errorMessage = axiosError.message;
        errorDetail = axiosError.response?.data?.detail;
      } else if (error instanceof Error) {
        errorMessage = error.message;
      }
      return { success: false, error: { message: errorMessage, detail: errorDetail || errorMessage } };
    }
  }
};

export const ordersApi = {
  cancelOrder: async (orderId: string) => {
    try {
      const response = await axios.put(`${API_BASE_URL}/orders-service/orders/${orderId}/status`, {
        status: 'CANCELLED' // Directly send the new status
      });
      console.log('Order cancelled successfully:', response.data);
      return { success: true, data: response.data };
    } catch (error) {
      console.error('Error cancelling order:', error);
      let errorMessage = 'An unknown error occurred';
      let errorDetail: string | undefined = undefined;

      if (axios.isAxiosError(error)) {
        const axiosError = error as AxiosError<ApiErrorResponse>;
        errorMessage = axiosError.message;
        errorDetail = axiosError.response?.data?.detail;
      } else if (error instanceof Error) {
        errorMessage = error.message;
      }
      return { success: false, error: { message: errorMessage, detail: errorDetail || errorMessage } };
    }
  }
};
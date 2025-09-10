import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { ArrowLeft, Package, MessageSquare, BarChart, Loader2 } from 'lucide-react';
import { catalogueApi } from '../services/api';
import { CatalogueItem } from '../types';
import { StarRating } from './StarRating';

export const ProductDetail: React.FC = () => {
  const { productId } = useParams<{ productId: string }>();
  const [product, setProduct] = useState<CatalogueItem | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchProduct = async () => {
      if (!productId) return;
      
      try {
        setLoading(true);
        const data = await catalogueApi.getProduct(parseInt(productId));
        setProduct(data);
      } catch (err) {
        setError('Failed to load product details');
        console.error('Error fetching product:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchProduct();
  }, [productId]);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Loader2 className="animate-spin text-blue-600" size={48} />
      </div>
    );
  }

  if (error || !product) {
    return (
      <div className="container mx-auto px-4 py-8">
        <Link to="/" className="inline-flex items-center text-blue-600 hover:text-blue-800 mb-4">
          <ArrowLeft size={20} className="mr-1" />
          Back to Catalogue
        </Link>
        <div className="text-center py-12">
          <p className="text-red-600 text-lg">{error || 'Product not found'}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <Link to="/" className="inline-flex items-center text-blue-600 hover:text-blue-800 mb-6">
        <ArrowLeft size={20} className="mr-1" />
        Back to Catalogue
      </Link>

      <div className="bg-white rounded-lg shadow-lg overflow-hidden">
        <div className="p-8">
          <div className="flex items-start justify-between mb-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 mb-2">{product.productName}</h1>
              <p className="text-gray-600 text-lg">{product.productDescription || 'No description available'}</p>
            </div>
            <Package className="text-gray-400" size={48} />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mt-8">
            <div className="bg-gray-50 rounded-lg p-6">
              <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
                <MessageSquare className="mr-2" size={24} />
                Customer Reviews
              </h2>
              <div className="space-y-3">
                <div className="flex items-center space-x-3">
                  <StarRating rating={product.avgRating || 0} size={24} />
                  <span className="text-2xl font-semibold">{product.avgRating ? product.avgRating.toFixed(1) : 'N/A'}</span>
                  <span className="text-gray-600">out of 5</span>
                </div>
                <p className="text-gray-600">Based on {product.reviewCount} reviews</p>
              </div>
            </div>

            <div className="bg-blue-50 rounded-lg p-6">
              <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
                <BarChart className="mr-2" size={24} />
                Product Analytics
              </h2>
              <div className="space-y-4">
                <div>
                  <div className="flex justify-between mb-1">
                    <span className="text-sm font-medium text-gray-700">Customer Satisfaction</span>
                    <span className="text-sm text-gray-600">{((product.avgRating || 0) / 5 * 100).toFixed(0)}%</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div 
                      className="bg-green-600 h-2 rounded-full" 
                      style={{ width: `${(product.avgRating || 0) / 5 * 100}%` }}
                    />
                  </div>
                </div>

                <div className="pt-4 border-t border-gray-200">
                  <p className="text-sm text-gray-600">
                    <span className="font-medium">Product ID:</span> {product.productId}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
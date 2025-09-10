import React from 'react';
import { Link } from 'react-router-dom';
import { Package, MessageSquare } from 'lucide-react';
import { CatalogueItem } from '../types';
import { StarRating } from './StarRating';

interface ProductCardProps {
  product: CatalogueItem;
}

export const ProductCard: React.FC<ProductCardProps> = ({ product }) => {
  return (
    <Link 
      to={`/product/${product.productId}`}
      className="block bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow duration-200 overflow-hidden"
    >
      <div className="p-6">
        <div className="flex items-start justify-between mb-4">
          <h3 className="text-xl font-semibold text-gray-900 flex-1">
            {product.productName}
          </h3>
          <Package className="text-gray-400 ml-2" size={24} />
        </div>
        
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <StarRating rating={product.avgRating || 0} size={18} />
              <span className="text-sm text-gray-600">
                {product.avgRating ? product.avgRating.toFixed(1) : 'N/A'}
              </span>
            </div>
            <div className="flex items-center text-sm text-gray-600">
              <MessageSquare size={16} className="mr-1" />
              {product.reviewCount} reviews
            </div>
          </div>
        </div>
      </div>
      
      <div className="bg-gray-50 px-6 py-3 border-t border-gray-100">
        <p className="text-sm text-gray-500 line-clamp-2">
          {product.productDescription || 'No description available'}
        </p>
      </div>
    </Link>
  );
};
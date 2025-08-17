import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ProductList } from './components/ProductList';
import { ProductDetail } from './components/ProductDetail';

function App() {
  return (
    <Router basename="/catalogue-service">
      <div className="min-h-screen bg-gray-50">
        <nav className="bg-white shadow-sm border-b">
          <div className="container mx-auto px-4 py-4">
            <h1 className="text-2xl font-bold text-gray-900">Drasi Product Catalogue</h1>
          </div>
        </nav>
        
        <Routes>
          <Route path="/" element={<ProductList />} />
          <Route path="/product/:productId" element={<ProductDetail />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
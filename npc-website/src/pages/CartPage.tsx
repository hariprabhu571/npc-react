import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  FiArrowLeft, 
  FiShoppingCart, 
  FiPlus, 
  FiMinus, 
  FiTrash2, 
  FiStar,
  FiShield,
  FiUser,
  FiLogOut,
  FiMapPin,
  FiCalendar,
  FiClock,
  FiCheckCircle
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { API_BASE_URL } from '../config/api';
import toast from 'react-hot-toast';

interface CartItem {
  service_type_id: number;
  service_type_name: string;
  room_size: string;
  price: number;
  quantity: number;
  service_name?: string;
  service_image?: string;
}

interface UserProfile {
  customer_name?: string;
  email_id?: string;
  mobile_number?: string;
  profile_pic?: string;
}

const CartPage: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [cartItems, setCartItems] = useState<CartItem[]>([]);
  const [userProfile, setUserProfile] = useState<UserProfile>({});
  const [showProfileDropdown, setShowProfileDropdown] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const profileDropdownRef = useRef<HTMLDivElement>(null);

  // Fetch user profile
  const fetchUserProfile = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/getprofile.php`, {
        method: 'GET',
        credentials: 'include',
      });
      const data = await response.json();
      if (data.status === 'success' && data.data) {
        setUserProfile(data.data);
      }
    } catch (error) {
      console.error('Error fetching profile:', error);
    }
  };

  // Fetch profile on component mount
  React.useEffect(() => {
    fetchUserProfile();
  }, []);

  // Handle click outside profile dropdown
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (profileDropdownRef.current && !profileDropdownRef.current.contains(event.target as Node)) {
        setShowProfileDropdown(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  // Load cart items from localStorage
  useEffect(() => {
    const savedCart = localStorage.getItem('globalCart');
    if (savedCart) {
      try {
        setCartItems(JSON.parse(savedCart));
      } catch (error) {
        console.error('Error parsing cart data:', error);
        setCartItems([]);
      }
    }
  }, []);

  // Profile dropdown handlers
  const handleProfileClick = () => {
    setShowProfileDropdown(!showProfileDropdown);
  };

  const handleProfileNavigation = () => {
    navigate('/profile');
    setShowProfileDropdown(false);
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const updateQuantity = (serviceTypeId: number, roomSize: string, newQuantity: number) => {
    setCartItems(prevItems => {
      const updatedItems = prevItems.map(item => {
        if (item.service_type_id === serviceTypeId && item.room_size === roomSize) {
          return { ...item, quantity: Math.max(0, newQuantity) };
        }
        return item;
      }).filter(item => item.quantity > 0);
      
      localStorage.setItem('globalCart', JSON.stringify(updatedItems));
      return updatedItems;
    });
  };

  const removeItem = (serviceTypeId: number, roomSize: string) => {
    setCartItems(prevItems => {
      const updatedItems = prevItems.filter(item => 
        !(item.service_type_id === serviceTypeId && item.room_size === roomSize)
      );
      localStorage.setItem('globalCart', JSON.stringify(updatedItems));
      return updatedItems;
    });
    toast.success('Item removed from cart');
  };

  const calculateSubtotal = () => {
    return cartItems.reduce((total, item) => total + (item.price * item.quantity), 0);
  };

  const calculateTotal = () => {
    return calculateSubtotal();
  };

  const handleProceedToBooking = () => {
    if (cartItems.length === 0) {
      toast.error('Your cart is empty');
      return;
    }
    
    // Navigate to a booking page with cart items
    navigate('/multi-service-booking', { 
      state: { cartItems, totalAmount: calculateTotal() }
    });
  };

  const handleContinueShopping = () => {
    navigate('/dashboard');
  };

  if (cartItems.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50">
        {/* Header */}
        <header className="bg-white shadow-sm border-b fixed top-0 left-0 right-0 z-50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between items-center h-16">
              <div className="flex items-center space-x-4">
                <button
                  onClick={() => navigate('/dashboard')}
                  className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
                >
                  <FiArrowLeft className="w-5 h-5" />
                </button>
                <div className="w-10 h-10 bg-teal-600 rounded-lg flex items-center justify-center overflow-hidden">
                  <img 
                    src="/images/logo-npc.png" 
                    alt="NPC Pest Control Logo"
                    className="w-8 h-8 object-contain"
                    onError={(e) => {
                      e.currentTarget.style.display = 'none';
                      e.currentTarget.nextElementSibling?.classList.remove('hidden');
                    }}
                  />
                  <FiShield className="w-6 h-6 text-white hidden" />
                </div>
                <div>
                  <h1 className="text-xl font-semibold text-gray-900">Shopping Cart</h1>
                  <p className="text-sm text-gray-500">NPC Professional Services</p>
                </div>
              </div>
              
              <div className="flex items-center space-x-4">
                <div className="text-right">
                  <p className="text-sm font-medium text-gray-900">Welcome back,</p>
                  <p className="text-sm text-gray-500">{userProfile.customer_name || user?.name || 'User'}</p>
                </div>
                <div className="relative" ref={profileDropdownRef}>
                  <button
                    onClick={handleProfileClick}
                    className="w-8 h-8 bg-gradient-to-br from-teal-400 to-blue-500 rounded-full flex items-center justify-center overflow-hidden hover:shadow-md transition-all duration-200 cursor-pointer"
                  >
                    {userProfile.profile_pic ? (
                      <img 
                        src={`${API_BASE_URL}${userProfile.profile_pic.replace(/^\/+/, '')}`}
                        alt="Profile"
                        className="w-8 h-8 rounded-full object-cover"
                        onError={(e) => {
                          e.currentTarget.style.display = 'none';
                          e.currentTarget.nextElementSibling?.classList.remove('hidden');
                        }}
                      />
                    ) : null}
                    <FiUser className="w-4 h-4 text-white hidden" />
                  </button>
                  
                  {/* Profile Dropdown */}
                  {showProfileDropdown && (
                    <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50 border border-gray-200">
                      <button
                        onClick={handleProfileNavigation}
                        className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 transition-colors"
                      >
                        <FiUser className="w-4 h-4 mr-3" />
                        Profile
                      </button>
                      <button
                        onClick={handleLogout}
                        className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 transition-colors"
                      >
                        <FiLogOut className="w-4 h-4 mr-3" />
                        Logout
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </header>

        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pt-24">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-2xl shadow-sm p-8 text-center"
          >
            <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-6">
              <FiShoppingCart className="w-12 h-12 text-gray-400" />
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">Your cart is empty</h2>
            <p className="text-gray-600 mb-8">Add some services to get started with your booking.</p>
            <button
              onClick={handleContinueShopping}
              className="px-8 py-3 bg-gradient-to-r from-teal-600 to-teal-700 text-white rounded-xl font-semibold hover:from-teal-700 hover:to-teal-800 transition-all duration-200 transform hover:scale-105 shadow-lg"
            >
              Continue Shopping
            </button>
          </motion.div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b fixed top-0 left-0 right-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => navigate('/dashboard')}
                className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <FiArrowLeft className="w-5 h-5" />
              </button>
              <div className="w-10 h-10 bg-teal-600 rounded-lg flex items-center justify-center overflow-hidden">
                <img 
                  src="/images/logo-npc.png" 
                  alt="NPC Pest Control Logo"
                  className="w-8 h-8 object-contain"
                  onError={(e) => {
                    e.currentTarget.style.display = 'none';
                    e.currentTarget.nextElementSibling?.classList.remove('hidden');
                  }}
                />
                <FiShield className="w-6 h-6 text-white hidden" />
              </div>
              <div>
                <h1 className="text-xl font-semibold text-gray-900">Shopping Cart</h1>
                <p className="text-sm text-gray-500">NPC Professional Services</p>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              <div className="text-right">
                <p className="text-sm font-medium text-gray-900">Welcome back,</p>
                <p className="text-sm text-gray-500">{userProfile.customer_name || user?.name || 'User'}</p>
              </div>
              <div className="relative" ref={profileDropdownRef}>
                <button
                  onClick={handleProfileClick}
                  className="w-8 h-8 bg-gradient-to-br from-teal-400 to-blue-500 rounded-full flex items-center justify-center overflow-hidden hover:shadow-md transition-all duration-200 cursor-pointer"
                >
                  {userProfile.profile_pic ? (
                    <img 
                      src={`${API_BASE_URL}${userProfile.profile_pic.replace(/^\/+/, '')}`}
                      alt="Profile"
                      className="w-8 h-8 rounded-full object-cover"
                      onError={(e) => {
                        e.currentTarget.style.display = 'none';
                        e.currentTarget.nextElementSibling?.classList.remove('hidden');
                      }}
                    />
                  ) : null}
                  <FiUser className="w-4 h-4 text-white hidden" />
                </button>
                
                {/* Profile Dropdown */}
                {showProfileDropdown && (
                  <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50 border border-gray-200">
                    <button
                      onClick={handleProfileNavigation}
                      className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 transition-colors"
                    >
                      <FiUser className="w-4 h-4 mr-3" />
                      Profile
                    </button>
                    <button
                      onClick={handleLogout}
                      className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 transition-colors"
                    >
                      <FiLogOut className="w-4 h-4 mr-3" />
                      Logout
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pt-24">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Cart Items */}
          <div className="lg:col-span-2">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-2xl shadow-sm p-6"
            >
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-900">Cart Items</h2>
                <span className="text-sm text-gray-500">
                  {cartItems.length} item{cartItems.length !== 1 ? 's' : ''}
                </span>
              </div>

              <div className="space-y-4">
                <AnimatePresence>
                  {cartItems.map((item, index) => (
                    <motion.div
                      key={`${item.service_type_id}-${item.room_size}`}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: 20 }}
                      transition={{ duration: 0.3 }}
                      className="border border-gray-200 rounded-xl p-4 hover:border-teal-300 transition-colors"
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-start space-x-4">
                            <div className="w-16 h-16 bg-teal-100 rounded-lg flex items-center justify-center flex-shrink-0">
                              <FiShield className="w-8 h-8 text-teal-600" />
                            </div>
                            <div className="flex-1">
                              <h3 className="font-semibold text-gray-900 text-lg">{item.service_type_name}</h3>
                              <p className="text-sm text-gray-600 mt-1">{item.room_size}</p>
                              <div className="flex items-center space-x-2 mt-2">
                                <FiStar className="w-4 h-4 text-yellow-400 fill-current" />
                                <span className="text-sm text-gray-600">4.8</span>
                                <span className="text-gray-400">•</span>
                                <span className="text-sm text-gray-500">Professional Service</span>
                              </div>
                            </div>
                          </div>
                        </div>
                        
                        <div className="flex items-center space-x-4">
                          <div className="text-right">
                            <p className="text-2xl font-bold text-teal-600">₹{item.price}</p>
                            <p className="text-xs text-gray-500">per treatment</p>
                          </div>
                          
                          <div className="flex items-center space-x-3">
                            <button
                              onClick={() => updateQuantity(item.service_type_id, item.room_size, item.quantity - 1)}
                              className="w-8 h-8 rounded-full bg-red-100 text-red-600 flex items-center justify-center hover:bg-red-200 transition-colors"
                            >
                              <FiMinus className="w-4 h-4" />
                            </button>
                            <span className="text-lg font-semibold text-gray-900 w-8 text-center">
                              {item.quantity}
                            </span>
                            <button
                              onClick={() => updateQuantity(item.service_type_id, item.room_size, item.quantity + 1)}
                              className="w-8 h-8 rounded-full bg-teal-100 text-teal-600 flex items-center justify-center hover:bg-teal-200 transition-colors"
                            >
                              <FiPlus className="w-4 h-4" />
                            </button>
                          </div>
                          
                          <button
                            onClick={() => removeItem(item.service_type_id, item.room_size)}
                            className="p-2 text-gray-400 hover:text-red-600 transition-colors"
                            title="Remove item"
                          >
                            <FiTrash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                      
                      <div className="mt-4 pt-4 border-t border-gray-100">
                        <div className="flex justify-between items-center">
                          <span className="text-sm text-gray-600">Subtotal:</span>
                          <span className="font-semibold text-gray-900">₹{(item.price * item.quantity).toFixed(0)}</span>
                        </div>
                      </div>
                    </motion.div>
                  ))}
                </AnimatePresence>
              </div>
            </motion.div>
          </div>

          {/* Order Summary */}
          <div className="lg:col-span-1">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-2xl shadow-sm p-6 sticky top-24"
            >
              <h3 className="text-lg font-bold text-gray-900 mb-4">Order Summary</h3>
              
              <div className="space-y-3 mb-6">
                <div className="flex justify-between items-center">
                  <span className="text-gray-600">Subtotal:</span>
                  <span className="font-semibold text-gray-900">₹{calculateSubtotal().toFixed(0)}</span>
                </div>
                <div className="flex justify-between items-center pt-2 border-t">
                  <span className="text-lg font-bold text-gray-900">Total:</span>
                  <span className="text-xl font-bold text-teal-600">₹{calculateTotal().toFixed(0)}</span>
                </div>
              </div>

              <div className="space-y-3 mb-6">
                <div className="flex items-center space-x-2 text-sm text-gray-600">
                  <FiCheckCircle className="w-4 h-4 text-green-500" />
                  <span>Professional service guarantee</span>
                </div>
                <div className="flex items-center space-x-2 text-sm text-gray-600">
                  <FiCheckCircle className="w-4 h-4 text-green-500" />
                  <span>Same day availability</span>
                </div>
                <div className="flex items-center space-x-2 text-sm text-gray-600">
                  <FiCheckCircle className="w-4 h-4 text-green-500" />
                  <span>90-day warranty</span>
                </div>
              </div>

              <button
                onClick={handleProceedToBooking}
                disabled={isLoading || cartItems.length === 0}
                className="w-full px-6 py-4 bg-gradient-to-r from-teal-600 to-teal-700 text-white rounded-xl font-semibold hover:from-teal-700 hover:to-teal-800 disabled:bg-gray-300 disabled:cursor-not-allowed transition-all duration-200 transform hover:scale-105 shadow-lg"
              >
                {isLoading ? (
                  <div className="flex items-center justify-center">
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Processing...
                  </div>
                ) : (
                  `Proceed to Booking - ₹${calculateTotal().toFixed(0)}`
                )}
              </button>

              <button
                onClick={handleContinueShopping}
                className="w-full px-6 py-3 border border-gray-300 text-gray-700 rounded-xl font-medium hover:bg-gray-50 transition-colors mt-3"
              >
                Continue Shopping
              </button>
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CartPage; 
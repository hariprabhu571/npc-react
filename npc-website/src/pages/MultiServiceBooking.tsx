import React, { useState, useEffect, useRef } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { motion } from 'framer-motion';
import { 
  FiArrowLeft, 
  FiShield, 
  FiUser, 
  FiLogOut, 
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

const MultiServiceBooking: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [cartItems, setCartItems] = useState<CartItem[]>([]);
  const [totalAmount, setTotalAmount] = useState(0);
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

  // Load cart items from location state or localStorage
  useEffect(() => {
    if (location.state?.cartItems) {
      setCartItems(location.state.cartItems);
      setTotalAmount(location.state.totalAmount);
    } else {
      // Fallback to localStorage
      const savedCart = localStorage.getItem('globalCart');
      if (savedCart) {
        try {
          const items = JSON.parse(savedCart);
          setCartItems(items);
          setTotalAmount(items.reduce((total: number, item: CartItem) => total + (item.price * item.quantity), 0));
        } catch (error) {
          console.error('Error parsing cart data:', error);
          navigate('/cart');
        }
      } else {
        navigate('/cart');
      }
    }
  }, [location.state, navigate]);

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

  const handleBooking = async () => {
    setIsLoading(true);
    
    try {
      // Create booking for each cart item
      const bookingPromises = cartItems.map(async (item) => {
        const bookingData = {
          customer_name: userProfile.customer_name || user?.name || '',
          mobile_number: userProfile.mobile_number || '',
          email_id: userProfile.email_id || '',
          address: 'To be filled',
          city: 'To be filled',
          state: 'To be filled',
          pincode: 'To be filled',
          preferred_date: new Date().toISOString().split('T')[0],
          preferred_time: '09:00',
          additional_notes: '',
          service_type_id: item.service_type_id,
          service_type_name: item.service_type_name,
          room_size: item.room_size,
          price: item.price,
          quantity: item.quantity,
          total_amount: item.price * item.quantity
        };

        const response = await fetch(`${API_BASE_URL}/book_service_v2.php`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          credentials: 'include',
          body: JSON.stringify(bookingData),
        });

        const result = await response.json();
        return result;
      });

      const results = await Promise.all(bookingPromises);
      
      // Check if all bookings were successful
      const successfulBookings = results.filter(result => result.status === 'success');
      
      if (successfulBookings.length === cartItems.length) {
        // Clear cart
        localStorage.removeItem('globalCart');
        
        toast.success('All services booked successfully!');
        navigate('/bookings');
      } else {
        toast.error('Some bookings failed. Please try again.');
      }
    } catch (error) {
      console.error('Booking error:', error);
      toast.error('Booking failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  if (cartItems.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pt-24">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-2xl shadow-sm p-8 text-center"
          >
            <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-6">
              <FiShield className="w-12 h-12 text-gray-400" />
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">No services to book</h2>
            <p className="text-gray-600 mb-8">Your cart is empty. Add some services to continue.</p>
            <button
              onClick={() => navigate('/dashboard')}
              className="px-8 py-3 bg-gradient-to-r from-teal-600 to-teal-700 text-white rounded-xl font-semibold hover:from-teal-700 hover:to-teal-800 transition-all duration-200 transform hover:scale-105 shadow-lg"
            >
              Browse Services
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
                onClick={() => navigate('/cart')}
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
                <h1 className="text-xl font-semibold text-gray-900">Multi-Service Booking</h1>
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
          {/* Main Content */}
          <div className="lg:col-span-2">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-2xl shadow-sm p-6"
            >
              <h2 className="text-xl font-bold text-gray-900 mb-6">Confirm Your Multi-Service Booking</h2>
              
              <div className="space-y-4">
                {cartItems.map((item, index) => (
                  <div key={index} className="border border-gray-200 rounded-xl p-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="font-semibold text-gray-900">{item.service_type_name}</h3>
                        <p className="text-sm text-gray-600">{item.room_size} × {item.quantity}</p>
                      </div>
                      <p className="font-semibold text-gray-900">₹{(item.price * item.quantity).toFixed(0)}</p>
                    </div>
                  </div>
                ))}
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
                  <span className="font-semibold text-gray-900">₹{totalAmount.toFixed(0)}</span>
                </div>
                <div className="flex justify-between items-center pt-2 border-t">
                  <span className="text-lg font-bold text-gray-900">Total:</span>
                  <span className="text-xl font-bold text-teal-600">₹{totalAmount.toFixed(0)}</span>
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
                onClick={handleBooking}
                disabled={isLoading}
                className="w-full px-6 py-4 bg-gradient-to-r from-teal-600 to-teal-700 text-white rounded-xl font-semibold hover:from-teal-700 hover:to-teal-800 disabled:bg-gray-300 disabled:cursor-not-allowed transition-all duration-200 transform hover:scale-105 shadow-lg"
              >
                {isLoading ? (
                  <div className="flex items-center justify-center">
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Creating Bookings...
                  </div>
                ) : (
                  `Confirm Bookings - ₹${totalAmount.toFixed(0)}`
                )}
              </button>
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MultiServiceBooking; 
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { 
  FiHome, 
  FiCalendar, 
  FiUser, 
  FiLogOut, 
  FiSearch, 
  FiShield, 
  FiStar, 
  FiArrowRight,
  FiBell,
  FiSettings
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { Service, Offer } from '../types';
import { apiService } from '../services/api';
import { API_ENDPOINTS } from '../config/api';
import { useQuery } from 'react-query';
import toast from 'react-hot-toast';

const UserDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<'services' | 'offers'>('services');
  const [searchQuery, setSearchQuery] = useState('');

  // Fetch services
  const { data: servicesData, isLoading: servicesLoading, refetch: refetchServices } = useQuery(
    'services',
    () => apiService.get<Service[]>(API_ENDPOINTS.FETCH_SERVICES),
    {
      retry: 1,
      onError: (error) => {
        toast.error('Failed to load services');
      }
    }
  );

  // Fetch offers
  const { data: offersData, isLoading: offersLoading, refetch: refetchOffers } = useQuery(
    'offers',
    () => apiService.get<Offer[]>(API_ENDPOINTS.FETCH_OFFERS),
    {
      retry: 1,
      onError: (error) => {
        toast.error('Failed to load offers');
      }
    }
  );

  const services = servicesData?.data || [];
  const offers = offersData?.data || [];

  const filteredServices = services.filter(service =>
    service.service_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    service.description.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredOffers = offers.filter(offer =>
    offer.offer_name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleServiceClick = (serviceName: string) => {
    navigate(`/service/${encodeURIComponent(serviceName)}`);
  };

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const navigationItems = [
    { icon: FiHome, label: 'Home', active: true, onClick: () => {} },
    { icon: FiCalendar, label: 'Bookings', onClick: () => navigate('/bookings') },
    { icon: FiBell, label: 'Notifications', onClick: () => navigate('/notifications') },
    { icon: FiUser, label: 'Profile', onClick: () => navigate('/profile') },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <div className="w-10 h-10 bg-teal-600 rounded-lg flex items-center justify-center">
                <FiShield className="w-6 h-6 text-white" />
              </div>
              <div>
                <h1 className="text-xl font-semibold text-gray-900">NPC</h1>
                <p className="text-sm text-gray-500">Professional Services</p>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              <div className="text-right">
                <p className="text-sm font-medium text-gray-900">Welcome back,</p>
                <p className="text-sm text-gray-500">{user?.name || 'User'}</p>
              </div>
              <button
                onClick={handleLogout}
                className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <FiLogOut className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {/* Sidebar Navigation */}
          <div className="lg:col-span-1">
            <nav className="bg-white rounded-lg shadow-sm p-4">
              <ul className="space-y-2">
                {navigationItems.map((item, index) => (
                  <li key={index}>
                    <button
                      onClick={item.onClick}
                      className={`w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-left transition-colors ${
                        item.active
                          ? 'bg-teal-50 text-teal-700 border border-teal-200'
                          : 'text-gray-700 hover:bg-gray-50'
                      }`}
                    >
                      <item.icon className="w-5 h-5" />
                      <span className="font-medium">{item.label}</span>
                    </button>
                  </li>
                ))}
              </ul>
            </nav>
          </div>

          {/* Main Content */}
          <div className="lg:col-span-3">
            {/* Search Bar */}
            <div className="mb-6">
              <div className="relative">
                <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                <input
                  type="text"
                  placeholder="Search services or offers..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-colors"
                />
              </div>
            </div>

            {/* Tab Navigation */}
            <div className="mb-6">
              <div className="border-b border-gray-200">
                <nav className="-mb-px flex space-x-8">
                  <button
                    onClick={() => setActiveTab('services')}
                    className={`py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                      activeTab === 'services'
                        ? 'border-teal-500 text-teal-600'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    }`}
                  >
                    Services ({filteredServices.length})
                  </button>
                  <button
                    onClick={() => setActiveTab('offers')}
                    className={`py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                      activeTab === 'offers'
                        ? 'border-teal-500 text-teal-600'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    }`}
                  >
                    Offers ({filteredOffers.length})
                  </button>
                </nav>
              </div>
            </div>

            {/* Content */}
            {activeTab === 'services' ? (
              <div>
                {servicesLoading ? (
                  <div className="flex justify-center items-center py-12">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600"></div>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {filteredServices.map((service, index) => (
                      <motion.div
                        key={service.service_id}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.3, delay: index * 0.1 }}
                        className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow cursor-pointer"
                        onClick={() => handleServiceClick(service.service_name)}
                      >
                        <div className="h-48 bg-gradient-to-br from-teal-400 to-blue-500 rounded-t-lg flex items-center justify-center">
                          <FiShield className="w-16 h-16 text-white" />
                        </div>
                        <div className="p-6">
                          <h3 className="text-lg font-semibold text-gray-900 mb-2">
                            {service.service_name}
                          </h3>
                          <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                            {service.description}
                          </p>
                          <div className="flex items-center justify-between">
                            <div className="flex items-center space-x-1">
                              <FiStar className="w-4 h-4 text-yellow-400 fill-current" />
                              <span className="text-sm text-gray-600">4.8</span>
                            </div>
                            <button className="text-teal-600 hover:text-teal-700 font-medium text-sm flex items-center">
                              Book Now
                              <FiArrowRight className="w-4 h-4 ml-1" />
                            </button>
                          </div>
                        </div>
                      </motion.div>
                    ))}
                  </div>
                )}
              </div>
            ) : (
              <div>
                {offersLoading ? (
                  <div className="flex justify-center items-center py-12">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600"></div>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {filteredOffers.map((offer, index) => (
                      <motion.div
                        key={offer.offer_id}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.3, delay: index * 0.1 }}
                        className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow"
                      >
                        <div className="h-48 bg-gradient-to-br from-orange-400 to-red-500 rounded-t-lg flex items-center justify-center relative">
                          <div className="absolute top-4 right-4 bg-white text-orange-600 px-3 py-1 rounded-full text-sm font-semibold">
                            {Math.round(offer.offer_percentage)}% OFF
                          </div>
                          <FiStar className="w-16 h-16 text-white" />
                        </div>
                        <div className="p-6">
                          <h3 className="text-lg font-semibold text-gray-900 mb-2">
                            {offer.offer_name}
                          </h3>
                          <p className="text-gray-600 text-sm mb-4">
                            Use coupon code: {offer.coupon_number}
                          </p>
                          <div className="flex items-center justify-between">
                            <span className="text-sm text-gray-500">
                              Valid until {new Date(offer.expires_on).toLocaleDateString()}
                            </span>
                            <button className="text-orange-600 hover:text-orange-700 font-medium text-sm flex items-center">
                              View Details
                              <FiArrowRight className="w-4 h-4 ml-1" />
                            </button>
                          </div>
                        </div>
                      </motion.div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserDashboard; 
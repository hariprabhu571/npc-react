import React, { useState, useEffect, useRef } from 'react';
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
  FiSettings,
  FiMapPin,
  FiNavigation,
  FiShare2,
  FiX,
  FiCopy,
  FiExternalLink,
  FiShield as FiPrivacy,
  FiMessageSquare
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { Service, Offer, ServicesResponse, OffersResponse } from '../types';
import { apiService } from '../services/api';
import { API_ENDPOINTS, API_BASE_URL } from '../config/api';
import { useQuery } from 'react-query';
import toast from 'react-hot-toast';

// Helper function to get full image URL
const getImageUrl = (imagePath?: string): string | null => {
  if (!imagePath) return null;
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('data:')) {
    return imagePath;
  }
  return `${API_BASE_URL}${imagePath.replace(/^\/+/, '')}`;
};

// Helper function to get offer image URL
const getOfferImageUrl = (imagePath?: string): string | null => {
  if (!imagePath) return null;
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('data:')) {
    return imagePath;
  }
  // The offer_banner_location already contains the full path, just prepend the base URL
  return `${API_BASE_URL}${imagePath.replace(/^\/+/, '')}`;
};

const UserDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<'services' | 'offers'>('services');
  const [searchQuery, setSearchQuery] = useState('');
  const [location, setLocation] = useState('');
  const [locationSuggestions, setLocationSuggestions] = useState<string[]>([]);
  const [showLocationDropdown, setShowLocationDropdown] = useState(false);
  const [isDetectingLocation, setIsDetectingLocation] = useState(false);
  const [showShareModal, setShowShareModal] = useState(false);
  const locationInputRef = useRef<HTMLInputElement>(null);
  const locationDropdownRef = useRef<HTMLDivElement>(null);

  // Fetch services
  const { data: servicesData, isLoading: servicesLoading, refetch: refetchServices } = useQuery(
    'services',
    () => apiService.getServices(),
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
    () => apiService.getOffers(),
    {
      retry: 1,
      onError: (error) => {
        toast.error('Failed to load offers');
      }
    }
  );

  const services = servicesData?.services || [];
  const offers = offersData?.offers || [];

  const filteredServices = services.filter((service: Service) => {
    // Search filter
    const matchesSearch = service.service_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      service.description.toLowerCase().includes(searchQuery.toLowerCase());
    
    // Location filter (frontend filtering like Flutter app)
    let matchesLocation = true;
    if (location && location.trim()) {
      try {
        const serviceLocations = service.locations ? JSON.parse(service.locations) : [];
        matchesLocation = Array.isArray(serviceLocations) && serviceLocations.includes(location.trim());
      } catch (e) {
        // If JSON parsing fails, treat as no locations available
        matchesLocation = false;
      }
    }
    
    return matchesSearch && matchesLocation;
  });

  const filteredOffers = offers.filter((offer: Offer) =>
    offer.offer_name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleServiceClick = (serviceName: string) => {
    navigate(`/service/${encodeURIComponent(serviceName)}`);
  };

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  // Location detection and management functions
  const detectLocation = () => {
    setIsDetectingLocation(true);
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          try {
            const { latitude, longitude } = position.coords;
            const response = await fetch(
              `https://api.opencagedata.com/geocode/v1/json?q=${latitude}+${longitude}&key=YOUR_OPENCAGE_API_KEY&language=en`
            );
            const data = await response.json();
            if (data.results && data.results.length > 0) {
              const city = data.results[0].components.city || 
                          data.results[0].components.town || 
                          data.results[0].components.village ||
                          data.results[0].components.county;
              setLocation(city);
              toast.success(`Location detected: ${city}`);
            }
          } catch (error) {
            toast.error('Failed to detect location. Please enter manually.');
          } finally {
            setIsDetectingLocation(false);
          }
        },
        (error) => {
          toast.error('Location access denied. Please enter manually.');
          setIsDetectingLocation(false);
        }
      );
    } else {
      toast.error('Geolocation not supported. Please enter manually.');
      setIsDetectingLocation(false);
    }
  };

  // Sample city suggestions (in a real app, this would come from an API)
  const citySuggestions = [
    'Chennai', 'Coimbatore', 'Erode', 'Salem', 'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Kolkata', 'Pune', 'Ahmedabad',
    'Jaipur', 'Surat', 'Lucknow', 'Kanpur', 'Nagpur', 'Indore', 'Thane', 'Bhopal',
    'Visakhapatnam', 'Pimpri-Chinchwad', 'Patna', 'Vadodara', 'Ghaziabad', 'Ludhiana',
    'Agra', 'Nashik', 'Faridabad', 'Meerut', 'Rajkot', 'Kalyan-Dombivali', 'Vasai-Virar',
    'Varanasi', 'Srinagar', 'Aurangabad', 'Dhanbad', 'Amritsar', 'Allahabad', 'Ranchi',
    'Howrah', 'Jabalpur', 'Gwalior', 'Vijayawada', 'Jodhpur', 'Madurai'
  ];

  const handleLocationInputChange = (value: string) => {
    setLocation(value);
    if (value.length >= 2) {
      const filtered = citySuggestions.filter(city =>
        city.toLowerCase().includes(value.toLowerCase())
      );
      setLocationSuggestions(filtered.slice(0, 5));
      setShowLocationDropdown(true);
    } else {
      setLocationSuggestions([]);
      setShowLocationDropdown(false);
    }
  };

  const handleLocationKeyPress = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && location.trim()) {
      setShowLocationDropdown(false);
      setLocationSuggestions([]);
    }
  };

  // Share functionality
  const shareData = {
    title: 'NPC Professional Services',
    text: '🏠 Transform your home with NPC Services!\n\n🐛 Expert Pest Control Solutions\n🧹 Professional Cleaning Services\n🔧 Home Maintenance & Repairs\n⚡ Quick & Reliable Service\n\nDownload now and get your first service at special rates!\n\n#NPCServices #PestControl #HomeServices',
    url: window.location.origin
  };

  const handleShare = async (method: 'native' | 'whatsapp' | 'copy') => {
    try {
      switch (method) {
        case 'native':
          if (navigator.share) {
            await navigator.share(shareData);
          } else {
            // Fallback to copy
            await navigator.clipboard.writeText(shareData.text + '\n\n' + shareData.url);
            toast.success('Share content copied to clipboard!');
          }
          break;
        case 'whatsapp':
          const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(shareData.text + '\n\n' + shareData.url)}`;
          window.open(whatsappUrl, '_blank');
          break;
        case 'copy':
          await navigator.clipboard.writeText(shareData.text + '\n\n' + shareData.url);
          toast.success('Share content copied to clipboard!');
          break;
      }
    } catch (error) {
      toast.error('Failed to share. Please try again.');
    }
  };

  const handleLocationSelect = (selectedLocation: string) => {
    setLocation(selectedLocation);
    setShowLocationDropdown(false);
    setLocationSuggestions([]);
  };

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (locationDropdownRef.current && !locationDropdownRef.current.contains(event.target as Node)) {
        setShowLocationDropdown(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const navigationItems = [
    { icon: FiHome, label: 'Home', active: true, onClick: () => {} },
    { icon: FiCalendar, label: 'Bookings', onClick: () => navigate('/bookings') },
    { icon: FiMessageSquare, label: 'Raise a Ticket', onClick: () => navigate('/raise-ticket') },
    { icon: FiShare2, label: 'Share', onClick: () => navigate('/share') },
    { icon: FiPrivacy, label: 'Privacy Policy', onClick: () => navigate('/privacy-policy') },
    { icon: FiUser, label: 'Profile', onClick: () => navigate('/profile') },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <div className="w-10 h-10 bg-teal-600 rounded-lg flex items-center justify-center overflow-hidden">
                <img 
                  src="/images/logo-npc.png" 
                  alt="NPC Pest Control Logo"
                  className="w-8 h-8 object-contain"
                  onError={(e) => {
                    // Fallback to shield icon if logo fails to load
                    e.currentTarget.style.display = 'none';
                    e.currentTarget.nextElementSibling?.classList.remove('hidden');
                  }}
                />
                <FiShield className="w-6 h-6 text-white hidden" />
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
            {/* Search and Location Bar */}
            <div className="mb-6">
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
                {/* Search Bar */}
                <div className="lg:col-span-2">
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

                {/* Location Selector */}
                <div className="relative" ref={locationDropdownRef}>
                  <div className="relative">
                    <FiMapPin className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                    <input
                      ref={locationInputRef}
                      type="text"
                      placeholder="Enter your city..."
                      value={location}
                      onChange={(e) => handleLocationInputChange(e.target.value)}
                      onKeyPress={handleLocationKeyPress}
                      className="w-full pl-10 pr-12 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-colors"
                    />
                    <button
                      onClick={detectLocation}
                      disabled={isDetectingLocation}
                      className="absolute right-2 top-1/2 transform -translate-y-1/2 p-1 text-gray-400 hover:text-teal-600 transition-colors disabled:opacity-50"
                      title="Detect my location"
                    >
                      {isDetectingLocation ? (
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-teal-600"></div>
                      ) : (
                        <FiNavigation className="w-4 h-4" />
                      )}
                    </button>
                  </div>

                  {/* Location Suggestions Dropdown */}
                  {showLocationDropdown && locationSuggestions.length > 0 && (
                    <div className="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-lg max-h-60 overflow-y-auto">
                      {locationSuggestions.map((suggestion, index) => (
                        <div
                          key={index}
                          onClick={() => handleLocationSelect(suggestion)}
                          className="px-4 py-3 hover:bg-gray-50 cursor-pointer border-b border-gray-100 last:border-b-0 transition-colors"
                        >
                          <div className="flex items-center space-x-2">
                            <FiMapPin className="w-4 h-4 text-gray-400" />
                            <span className="text-gray-700">{suggestion}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
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
                    Services ({servicesLoading ? '...' : filteredServices.length})
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
                {/* Location Filter Indicator */}
                {location && (
                  <div className="mb-4 p-3 bg-teal-50 border border-teal-200 rounded-lg">
                    <div className="flex items-center space-x-2">
                      <FiMapPin className="w-4 h-4 text-teal-600" />
                      <span className="text-sm text-teal-700">
                        Showing {filteredServices.length} service{filteredServices.length !== 1 ? 's' : ''} available in <strong>{location}</strong>
                      </span>
                      <button
                        onClick={() => {
                          setLocation('');
                          setShowLocationDropdown(false);
                          setLocationSuggestions([]);
                        }}
                        className="ml-auto text-xs text-teal-600 hover:text-teal-800 underline"
                      >
                        Clear filter
                      </button>
                    </div>
                  </div>
                )}
                
                {servicesLoading ? (
                  <div className="flex justify-center items-center py-12">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600"></div>
                  </div>
                ) : filteredServices.length === 0 ? (
                  <div className="text-center py-12">
                    <FiMapPin className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">
                      {location ? `No services available in ${location}` : 'No services found'}
                    </h3>
                    <p className="text-gray-500 mb-4">
                      {location 
                        ? 'Try selecting a different location or contact us to request service in your area.'
                        : 'No services are currently available.'
                      }
                    </p>
                    {location && (
                      <button
                        onClick={() => {
                          setLocation('');
                        }}
                        className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-teal-600 hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-teal-500"
                      >
                        View all services
                      </button>
                    )}
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {filteredServices.map((service: Service, index: number) => (
                      <motion.div
                        key={service.service_id}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.3, delay: index * 0.1 }}
                        className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow cursor-pointer"
                        onClick={() => handleServiceClick(service.service_name)}
                      >
                        <div className="h-48 bg-gradient-to-br from-teal-400 to-blue-500 rounded-t-lg flex items-center justify-center overflow-hidden">
                          {service.image_path && getImageUrl(service.image_path) ? (
                            <img
                              src={getImageUrl(service.image_path)!}
                              alt={service.service_name}
                              className="w-full h-full object-cover"
                              onError={(e) => {
                                // Fallback to gradient background if image fails to load
                                e.currentTarget.style.display = 'none';
                                e.currentTarget.nextElementSibling?.classList.remove('hidden');
                              }}
                            />
                          ) : null}
                          <div className={`flex items-center justify-center ${service.image_path ? 'hidden' : ''}`}>
                            <FiShield className="w-16 h-16 text-white" />
                          </div>
                        </div>
                        <div className="p-6">
                          <h3 className="text-lg font-semibold text-gray-900 mb-2">
                            {service.service_name}
                          </h3>
                          <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                            {service.description}
                          </p>
                          <div className="flex items-center justify-end">
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
                    {filteredOffers.map((offer: Offer, index: number) => (
                      <motion.div
                        key={offer.offer_id}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.3, delay: index * 0.1 }}
                        className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow"
                      >
                        <div className="h-48 bg-gradient-to-br from-orange-400 to-red-500 rounded-t-lg flex items-center justify-center relative overflow-hidden">
                          {offer.offer_banner_location ? (
                            <img
                              src={getOfferImageUrl(offer.offer_banner_location)!}
                              alt={offer.offer_name}
                              className="w-full h-full object-cover"
                              onError={(e) => {
                                // Fallback to gradient background if image fails to load
                                e.currentTarget.style.display = 'none';
                                e.currentTarget.nextElementSibling?.classList.remove('hidden');
                              }}
                            />
                          ) : null}
                          <div className={`flex items-center justify-center ${offer.offer_banner_location ? 'hidden' : ''}`}>
                            <FiStar className="w-16 h-16 text-white" />
                          </div>
                          <div className="absolute top-4 right-4 bg-white text-orange-600 px-3 py-1 rounded-full text-sm font-semibold">
                            {Math.round(offer.offer_percentage)}% OFF
                          </div>
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

      {/* Share Modal */}
      {showShareModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="bg-white rounded-2xl max-w-md w-full max-h-[90vh] overflow-y-auto"
          >
            {/* Header */}
            <div className="relative p-6 border-b border-gray-100">
              <button
                onClick={() => setShowShareModal(false)}
                className="absolute top-4 right-4 p-2 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <FiX className="w-5 h-5" />
              </button>
              <div className="text-center">
                <div className="w-16 h-16 bg-gradient-to-br from-teal-500 to-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
                  <FiShield className="w-8 h-8 text-white" />
                </div>
                <h2 className="text-2xl font-bold text-gray-900 mb-2">Share NPC</h2>
                <p className="text-gray-600">Help your friends discover amazing home services</p>
              </div>
            </div>

            {/* App Preview */}
            <div className="p-6">
              <div className="bg-gradient-to-br from-teal-50 to-blue-50 rounded-xl p-4 mb-6">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-gradient-to-br from-teal-500 to-blue-600 rounded-xl flex items-center justify-center">
                    <FiShield className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <h3 className="font-bold text-gray-900">NPC Professional Services</h3>
                    <p className="text-sm text-gray-600">Professional Pest Control & Home Services</p>
                  </div>
                </div>
              </div>

              {/* Share Options */}
              <div className="space-y-4">
                <h3 className="font-semibold text-gray-900 mb-4">Share with Friends</h3>
                
                {/* Native Share */}
                <button
                  onClick={() => handleShare('native')}
                  className="w-full bg-gradient-to-r from-teal-500 to-blue-600 text-white py-4 px-6 rounded-xl font-semibold hover:from-teal-600 hover:to-blue-700 transition-all duration-200 transform hover:scale-105 shadow-lg"
                >
                  <div className="flex items-center justify-center space-x-3">
                    <FiShare2 className="w-5 h-5" />
                    <span>Share via System</span>
                  </div>
                </button>

                {/* WhatsApp Share */}
                <button
                  onClick={() => handleShare('whatsapp')}
                  className="w-full bg-green-500 text-white py-4 px-6 rounded-xl font-semibold hover:bg-green-600 transition-all duration-200 transform hover:scale-105 shadow-lg"
                >
                  <div className="flex items-center justify-center space-x-3">
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.885 3.488"/>
                    </svg>
                    <span>Share on WhatsApp</span>
                  </div>
                </button>

                {/* Copy Link */}
                <button
                  onClick={() => handleShare('copy')}
                  className="w-full bg-gray-100 text-gray-700 py-4 px-6 rounded-xl font-semibold hover:bg-gray-200 transition-all duration-200 transform hover:scale-105"
                >
                  <div className="flex items-center justify-center space-x-3">
                    <FiCopy className="w-5 h-5" />
                    <span>Copy to Clipboard</span>
                  </div>
                </button>
              </div>

              {/* Features */}
              <div className="mt-8 pt-6 border-t border-gray-100">
                <h3 className="font-semibold text-gray-900 mb-4">What we offer</h3>
                <div className="grid grid-cols-2 gap-3">
                  {[
                    { icon: '🐛', label: 'Pest Control' },
                    { icon: '🧹', label: 'Cleaning' },
                    { icon: '🔧', label: 'Repairs' },
                    { icon: '⚡', label: '24/7 Service' }
                  ].map((feature, index) => (
                    <div key={index} className="flex items-center space-x-2 p-3 bg-gray-50 rounded-lg">
                      <span className="text-lg">{feature.icon}</span>
                      <span className="text-sm font-medium text-gray-700">{feature.label}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
};

export default UserDashboard; 
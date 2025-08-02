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
  FiMessageSquare,
  FiShoppingCart
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

interface UserProfile {
  customer_name?: string;
  email_id?: string;
  mobile_number?: string;
  profile_pic?: string;
}

const UserDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<'services' | 'offers'>('services');
  const [searchQuery, setSearchQuery] = useState('');
  const [location, setLocation] = useState('');
  const [locationSuggestions, setLocationSuggestions] = useState<string[]>([]);
  const [showLocationDropdown, setShowLocationDropdown] = useState(false);
  const [isDetectingLocation, setIsDetectingLocation] = useState(false);
  const [showOfferModal, setShowOfferModal] = useState(false);
  const [selectedOffer, setSelectedOffer] = useState<Offer | null>(null);
  const [userProfile, setUserProfile] = useState<UserProfile>({});
  const [showProfileDropdown, setShowProfileDropdown] = useState(false);
  const locationInputRef = useRef<HTMLInputElement>(null);
  const locationDropdownRef = useRef<HTMLDivElement>(null);
  const profileDropdownRef = useRef<HTMLDivElement>(null);

  // Fetch user profile
  const fetchUserProfile = async () => {
    try {
      const response = await apiService.getProfile();
      if (response.status === 'success' && response.data) {
        setUserProfile(response.data);
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

  const handleOfferClick = (offer: Offer) => {
    setSelectedOffer(offer);
    setShowOfferModal(true);
  };

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const handleProfileClick = () => {
    setShowProfileDropdown(!showProfileDropdown);
  };

  const handleProfileNavigation = () => {
    setShowProfileDropdown(false);
    navigate('/profile');
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
    { icon: FiShoppingCart, label: 'Cart', onClick: () => navigate('/cart') },
    { icon: FiMessageSquare, label: 'Raise a Ticket', onClick: () => navigate('/raise-ticket') },
    { icon: FiShare2, label: 'Share', onClick: () => navigate('/share') },
    { icon: FiPrivacy, label: 'Privacy Policy', onClick: () => navigate('/privacy-policy') },
    { icon: FiUser, label: 'Profile', onClick: () => navigate('/profile') },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b fixed top-0 left-0 right-0 z-50">
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
                          <div className="absolute top-4 right-4 bg-gradient-to-r from-orange-500 to-red-500 text-white px-3 py-1 rounded-full text-xs font-bold shadow-lg border-2 border-white">
                            <div className="flex items-center space-x-0.5">
                              <div className="w-1 h-1 bg-white rounded-full opacity-90"></div>
                              <span>{Math.round(offer.offer_percentage)}% OFF</span>
                              <div className="w-1 h-1 bg-white rounded-full opacity-90"></div>
                            </div>
                          </div>
                        </div>
                        <div className="p-6">
                          <h3 className="text-lg font-semibold text-gray-900 mb-4">
                            {offer.offer_name}
                          </h3>
                          <div className="flex items-center justify-end">
                            <button 
                              onClick={(e) => {
                                e.stopPropagation();
                                handleOfferClick(offer);
                              }}
                              className="text-orange-600 hover:text-orange-700 font-medium text-sm flex items-center"
                            >
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



      {/* Offer Details Modal */}
      {showOfferModal && selectedOffer && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto overflow-x-hidden"
          >
            {/* Header */}
            <div className="relative p-6 border-b border-gray-100">
              <button
                onClick={() => setShowOfferModal(false)}
                className="absolute top-4 right-4 p-2 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <FiX className="w-5 h-5" />
              </button>
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  <div className="w-16 h-16 bg-gradient-to-br from-orange-500 to-red-600 rounded-2xl flex items-center justify-center">
                    <FiStar className="w-8 h-8 text-white" />
                  </div>
                  <div>
                    <h2 className="text-2xl font-bold text-gray-900">Offer Details</h2>
                    <p className="text-gray-600">Special discount for you</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Two Column Layout */}
            <div className="px-6 pb-6 min-w-0">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Left Column - Image */}
                <div className="min-w-0">
                  <div className="h-64 bg-gradient-to-br from-orange-400 to-red-500 rounded-xl flex items-center justify-center relative overflow-hidden">
                    {selectedOffer.offer_banner_location ? (
                      <img
                        src={getOfferImageUrl(selectedOffer.offer_banner_location)!}
                        alt={selectedOffer.offer_name}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          e.currentTarget.style.display = 'none';
                          e.currentTarget.nextElementSibling?.classList.remove('hidden');
                        }}
                      />
                    ) : null}
                    <div className={`flex items-center justify-center ${selectedOffer.offer_banner_location ? 'hidden' : ''}`}>
                      <FiStar className="w-16 h-16 text-white" />
                    </div>

                  </div>
                </div>

                {/* Right Column - Details */}
                <div className="min-w-0">
                  <div className="space-y-4">
                    <div>
                      <h3 className="text-xl font-bold text-gray-900 mb-2">{selectedOffer.offer_name}</h3>
                      <p className="text-gray-600">Get amazing discounts on our services</p>
                    </div>

                    <div className="bg-gray-50 rounded-lg p-4 space-y-3 min-w-0">
                      <div className="flex justify-between items-center flex-wrap gap-2 min-w-0">
                        <span className="text-gray-600 font-medium min-w-0">Coupon Code:</span>
                        <span className="font-bold text-orange-600 bg-orange-100 px-3 py-1 rounded-lg break-all min-w-0">
                          {selectedOffer.coupon_number}
                        </span>
                      </div>
                      
                      <div className="flex justify-between items-center flex-wrap gap-2 min-w-0">
                        <span className="text-gray-600 font-medium min-w-0">Discount:</span>
                        <span className="font-bold text-green-600 min-w-0">
                          {Math.round(selectedOffer.offer_percentage)}% OFF
                        </span>
                      </div>
                      
                      <div className="flex justify-between items-center flex-wrap gap-2 min-w-0">
                        <span className="text-gray-600 font-medium min-w-0">Start Date:</span>
                        <span className="font-medium text-gray-900 min-w-0">
                          {new Date(selectedOffer.offer_starts_on).toLocaleDateString()}
                        </span>
                      </div>
                      
                      <div className="flex justify-between items-center flex-wrap gap-2 min-w-0">
                        <span className="text-gray-600 font-medium min-w-0">Expires On:</span>
                        <span className="font-medium text-gray-900 min-w-0">
                          {new Date(selectedOffer.expires_on).toLocaleDateString()}
                        </span>
                      </div>
                      
                      <div className="flex justify-between items-center flex-wrap gap-2 min-w-0">
                        <span className="text-gray-600 font-medium min-w-0">Status:</span>
                        <span className={`font-medium px-2 py-1 rounded-lg min-w-0 ${
                          selectedOffer.status === 'Active' 
                            ? 'text-green-600 bg-green-100' 
                            : 'text-red-600 bg-red-100'
                        }`}>
                          {selectedOffer.status}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* How to use - Full Width */}
              <div className="bg-orange-50 border border-orange-200 rounded-lg p-4 mt-6">
                <h4 className="font-semibold text-orange-800 mb-2">How to use:</h4>
                <ol className="text-sm text-orange-700 space-y-1">
                  <li>1. Select your desired service</li>
                  <li>2. Add items to your cart</li>
                  <li>3. Enter coupon code: <strong>{selectedOffer.coupon_number}</strong></li>
                  <li>4. Enjoy your discount!</li>
                </ol>
              </div>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
};

export default UserDashboard; 
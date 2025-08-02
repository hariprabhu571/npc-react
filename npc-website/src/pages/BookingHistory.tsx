import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { 
  FiShield, 
  FiArrowLeft, 
  FiCalendar, 
  FiClock, 
  FiMapPin, 
  FiDollarSign,
  FiCheckCircle,
  FiXCircle,
  FiClock as FiPending,
  FiStar,
  FiSearch,
  FiTag,
  FiUser
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { Booking, BookingsResponse } from '../types';
import { apiService } from '../services/api';
import { API_ENDPOINTS, API_BASE_URL } from '../config/api';
import { useQuery } from 'react-query';
import toast from 'react-hot-toast';

interface UserProfile {
  customer_name?: string;
  email_id?: string;
  mobile_number?: string;
  profile_pic?: string;
}

const BookingHistory: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [activeFilter, setActiveFilter] = useState<'all' | 'pending' | 'confirmed' | 'completed' | 'cancelled'>('all');
  const [selectedBooking, setSelectedBooking] = useState<Booking | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<'date' | 'amount' | 'service'>('date');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  const [userProfile, setUserProfile] = useState<UserProfile>({});

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
  useEffect(() => {
    fetchUserProfile();
  }, []);

  // Fetch bookings
  const { data: bookingsData, isLoading, refetch } = useQuery(
    'bookings',
    () => apiService.getUserBookings(),
    {
      retry: 1,
      onError: (error) => {
        toast.error('Failed to load bookings');
      }
    }
  );

  // Combine all bookings from different categories
  const allBookings = [
    ...(bookingsData?.bookings?.active || []),
    ...(bookingsData?.bookings?.completed || []),
    ...(bookingsData?.bookings?.cancelled || [])
  ];

  // Filter bookings based on search query and status
  const filteredBookings = allBookings.filter(booking => {
    // Status filter
    if (activeFilter !== 'all' && booking.status !== activeFilter) return false;
    
    // Search filter
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      return (
        booking.service_name.toLowerCase().includes(query) ||
        booking.booking_id.toLowerCase().includes(query) ||
        booking.address.toLowerCase().includes(query) ||
        booking.service_time.toLowerCase().includes(query) ||
        booking.total_amount.toString().includes(query)
      );
    }
    
    return true;
  });

  // Sort bookings
  const sortedBookings = [...filteredBookings].sort((a, b) => {
    let comparison = 0;
    
    switch (sortBy) {
      case 'date':
        // Use created_at for date sorting to show latest bookings first
        comparison = new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
        break;
      case 'amount':
        comparison = a.total_amount - b.total_amount;
        break;
      case 'service':
        comparison = a.service_name.localeCompare(b.service_name);
        break;
    }
    
    return sortOrder === 'asc' ? comparison : -comparison;
  });

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <FiCheckCircle className="w-5 h-5 text-green-500" />;
      case 'accepted':
        return <FiClock className="w-5 h-5 text-blue-500" />;
      case 'pending':
        return <FiPending className="w-5 h-5 text-yellow-500" />;
      case 'cancelled':
        return <FiXCircle className="w-5 h-5 text-red-500" />;
      default:
        return <FiClock className="w-5 h-5 text-gray-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'accepted':
        return 'bg-blue-100 text-blue-800';
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      case 'cancelled':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getPaymentStatusColor = (paymentStatus: string) => {
    switch (paymentStatus) {
      case 'paid':
        return 'bg-green-100 text-green-700 border border-green-300';
      case 'pending':
        return 'bg-yellow-100 text-yellow-700 border border-yellow-300';
      case 'failed':
        return 'bg-red-100 text-red-700 border border-red-300';
      case 'refunded':
        return 'bg-purple-100 text-purple-700 border border-purple-300';
      default:
        return 'bg-gray-100 text-gray-700 border border-gray-300';
    }
  };

  const getStatusIndicatorColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-500';
      case 'confirmed':
        return 'bg-blue-500';
      case 'pending':
        return 'bg-yellow-500';
      case 'cancelled':
        return 'bg-red-500';
      default:
        return 'bg-gray-500';
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };



  const filterOptions = [
    { value: 'all', label: 'All Bookings', count: allBookings.length },
    { value: 'pending', label: 'Pending', count: allBookings.filter((b: Booking) => b.status === 'pending').length },
    { value: 'confirmed', label: 'Confirmed', count: allBookings.filter((b: Booking) => b.status === 'confirmed').length },
    { value: 'completed', label: 'Completed', count: allBookings.filter((b: Booking) => b.status === 'completed').length },
    { value: 'cancelled', label: 'Cancelled', count: allBookings.filter((b: Booking) => b.status === 'cancelled').length },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b fixed top-0 left-0 right-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => window.history.back()}
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
                <p className="text-sm font-medium text-gray-900">Welcome,</p>
                <p className="text-sm text-gray-500">{userProfile.customer_name || user?.name || 'User'}</p>
              </div>
              <div className="w-8 h-8 bg-gradient-to-br from-teal-400 to-blue-500 rounded-full flex items-center justify-center overflow-hidden">
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
              </div>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pt-24">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          {/* Page Header */}
          <div className="mb-8">
            <h2 className="text-3xl font-bold text-gray-900 mb-2">Booking History</h2>
            <p className="text-gray-600">Manage and track your service bookings</p>
          </div>

          {/* Search and Filters */}
          <div className="mb-6 space-y-4">
            {/* Search Bar */}
            <div className="relative">
              <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="Search by service name, booking ID, address, time, or amount..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-colors"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              )}
            </div>

            {/* Filters Row */}
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
              {/* Status Filter Tabs */}
              <div className="border-b border-gray-200">
                <nav className="-mb-px flex space-x-8 overflow-x-auto">
                  {filterOptions.map((option) => (
                    <button
                      key={option.value}
                      onClick={() => setActiveFilter(option.value as any)}
                      className={`py-2 px-1 border-b-2 font-medium text-sm whitespace-nowrap transition-colors ${
                        activeFilter === option.value
                          ? 'border-teal-500 text-teal-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }`}
                    >
                      {option.label} ({option.count})
                    </button>
                  ))}
                </nav>
              </div>

              {/* Sort Controls */}
              <div className="flex items-center space-x-3">
                <label className="text-sm font-medium text-gray-700">Sort by:</label>
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value as 'date' | 'amount' | 'service')}
                  className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                >
                  <option value="date">Booking Date</option>
                  <option value="amount">Amount</option>
                  <option value="service">Service</option>
                </select>
              </div>
            </div>

            {/* Results Summary */}
            <div className="text-sm text-gray-600">
              Showing {sortedBookings.length} of {allBookings.length} bookings
              {searchQuery && ` for "${searchQuery}"`}
            </div>
          </div>



          {/* Bookings List */}
          {isLoading ? (
            <div className="flex justify-center items-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
            </div>
          ) : sortedBookings.length === 0 ? (
            <div className="text-center py-12">
              <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <FiCalendar className="w-12 h-12 text-gray-400" />
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No bookings found</h3>
              <p className="text-gray-600 mb-6">
                {activeFilter === 'all' 
                  ? "You haven't made any bookings yet."
                  : `No ${activeFilter} bookings found.`
                }
              </p>
              {activeFilter === 'all' && (
                <button
                  onClick={() => navigate('/dashboard')}
                  className="btn btn-primary"
                >
                  Browse Services
                </button>
              )}
            </div>
          ) : (
            <div className="space-y-4">
              {sortedBookings.map((booking, index) => (
                <motion.div
                  key={booking.booking_id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.3, delay: index * 0.1 }}
                  className="relative bg-gradient-to-br from-white to-gray-50 rounded-2xl shadow-xl border border-gray-100 overflow-hidden hover:shadow-2xl hover:scale-[1.02] transition-all duration-300"
                >
                  {/* Background Pattern */}
                  <div className="absolute top-0 right-0 w-40 h-40 bg-gradient-to-bl from-teal-100/40 to-transparent rounded-full -translate-y-20 translate-x-20"></div>
                  <div className="absolute bottom-0 left-0 w-32 h-32 bg-gradient-to-tr from-orange-100/30 to-transparent rounded-full translate-y-16 -translate-x-16"></div>
                  
                  <div className="relative z-10 p-6">
                    {/* Header Section */}
                    <div className="flex items-start justify-between mb-6">
                      <div className="flex items-center space-x-4">
                        <div className="relative">
                          <div className="w-16 h-16 bg-gradient-to-br from-teal-500 via-teal-600 to-teal-700 rounded-2xl flex items-center justify-center shadow-lg">
                            <span className="text-white font-bold text-xl">
                              {booking.service_name.charAt(0)}
                            </span>
                          </div>
                          <div className={`absolute -top-2 -right-2 w-6 h-6 rounded-full flex items-center justify-center shadow-md ${getStatusIndicatorColor(booking.status)}`}>
                          </div>
                        </div>
                                                <div className="flex-1">
                          <div className="flex items-center space-x-4 mb-3">
                            <h3 className="text-2xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 bg-clip-text text-transparent">
                              {booking.service_name}
                            </h3>
                          </div>
                          <div className="flex items-center space-x-2">
                            <span className={`px-3 py-1.5 rounded-full text-xs font-semibold ${getPaymentStatusColor(booking.payment_status)}`}>
                              Payment: {booking.payment_status}
                            </span>
                            <span className={`px-3 py-1.5 rounded-full text-xs font-semibold ${getStatusColor(booking.status)}`}>
                              Booking Status: {booking.status.charAt(0).toUpperCase() + booking.status.slice(1)}
                            </span>
                          </div>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-3xl font-bold bg-gradient-to-r from-teal-600 to-teal-800 bg-clip-text text-transparent">
                          ₹{booking.total_amount}
                        </div>
                        <div className="text-sm text-gray-500 font-medium">Total Amount</div>
                      </div>
                    </div>

                    {/* Details Grid */}
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
                      {/* Service Date Card */}
                      <div className="group relative bg-gradient-to-br from-blue-50/60 via-blue-100/40 to-indigo-50/60 rounded-xl p-3 border border-blue-200/60 shadow-sm hover:shadow-lg transition-all duration-300 overflow-hidden">
                        <div className="absolute top-0 right-0 w-12 h-12 bg-gradient-to-bl from-blue-200/20 to-transparent rounded-full -translate-y-6 translate-x-6"></div>
                        <div className="relative z-10">
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center space-x-2">
                              <div className="w-8 h-8 bg-gradient-to-br from-blue-500/80 to-blue-600/80 rounded-lg flex items-center justify-center shadow-sm">
                                <FiCalendar className="w-4 h-4 text-white" />
                              </div>
                              <span className="text-xs font-bold text-blue-600/80 uppercase tracking-wide">Date</span>
                            </div>
                            <div className="w-2 h-2 bg-blue-400/60 rounded-full group-hover:animate-pulse"></div>
                          </div>
                          <div className="text-sm font-bold text-gray-900 font-mono">{formatDate(booking.service_date)}</div>
                        </div>
                      </div>
                      
                      {/* Time Slot Card */}
                      <div className="group relative bg-gradient-to-br from-emerald-50/60 via-emerald-100/40 to-green-50/60 rounded-xl p-3 border border-emerald-200/60 shadow-sm hover:shadow-lg transition-all duration-300 overflow-hidden">
                        <div className="absolute top-0 right-0 w-12 h-12 bg-gradient-to-bl from-emerald-200/20 to-transparent rounded-full -translate-y-6 translate-x-6"></div>
                        <div className="relative z-10">
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center space-x-2">
                              <div className="w-8 h-8 bg-gradient-to-br from-emerald-500/80 to-emerald-600/80 rounded-lg flex items-center justify-center shadow-sm">
                                <FiClock className="w-4 h-4 text-white" />
                              </div>
                              <span className="text-xs font-bold text-emerald-600/80 uppercase tracking-wide">Time</span>
                            </div>
                            <div className="w-2 h-2 bg-emerald-400/60 rounded-full group-hover:animate-ping"></div>
                          </div>
                          <div className="text-sm font-bold text-gray-900 font-mono">{booking.service_time}</div>
                        </div>
                      </div>
                      
                      {/* Location Card */}
                      <div className="group relative bg-gradient-to-br from-purple-50/60 via-purple-100/40 to-violet-50/60 rounded-xl p-3 border border-purple-200/60 shadow-sm hover:shadow-lg transition-all duration-300 overflow-hidden">
                        <div className="absolute top-0 right-0 w-12 h-12 bg-gradient-to-bl from-purple-200/20 to-transparent rounded-full -translate-y-6 translate-x-6"></div>
                        <div className="relative z-10">
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center space-x-2">
                              <div className="w-8 h-8 bg-gradient-to-br from-purple-500/80 to-purple-600/80 rounded-lg flex items-center justify-center shadow-sm">
                                <FiMapPin className="w-4 h-4 text-white" />
                              </div>
                              <span className="text-xs font-bold text-purple-600/80 uppercase tracking-wide">Location</span>
                            </div>
                            <div className="w-2 h-2 bg-purple-400/60 rounded-full group-hover:animate-bounce"></div>
                          </div>
                          <div className="text-sm font-bold text-gray-900 truncate">{booking.address}</div>
                        </div>
                      </div>
                      
                      {/* Booking ID Card */}
                      <div className="group relative bg-gradient-to-br from-slate-50/60 via-slate-100/40 to-gray-50/60 rounded-xl p-3 border border-slate-200/60 shadow-sm hover:shadow-lg transition-all duration-300 overflow-hidden">
                        <div className="absolute top-0 right-0 w-12 h-12 bg-gradient-to-bl from-slate-200/20 to-transparent rounded-full -translate-y-6 translate-x-6"></div>
                        <div className="relative z-10">
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center space-x-2">
                              <div className="w-8 h-8 bg-gradient-to-br from-slate-600/80 to-slate-700/80 rounded-lg flex items-center justify-center shadow-sm">
                                <FiShield className="w-4 h-4 text-white" />
                              </div>
                              <span className="text-xs font-bold text-slate-600/80 uppercase tracking-wide">Booking ID</span>
                            </div>
                            <div className="w-2 h-2 bg-slate-400/60 rounded-full group-hover:animate-pulse"></div>
                          </div>
                          <div className="text-sm font-bold text-slate-800 font-mono bg-white/40 px-2 py-1 rounded border border-slate-300/60">
                            {booking.booking_id}
                          </div>
                        </div>
                      </div>
                    </div>

                    {booking.special_notes && (
                      <div className="mb-6 bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-4 border border-blue-100">
                        <p className="text-sm text-gray-700">
                          <strong className="text-blue-600">Special Notes:</strong> {booking.special_notes}
                        </p>
                      </div>
                    )}

                    {/* Action Buttons */}
                    <div className="flex justify-between items-center pt-4 border-t border-gray-100">
                      <div className="flex space-x-3">
                        <button
                          onClick={() => navigate(`/service/${encodeURIComponent(booking.service_name)}`)}
                          className="px-4 py-2 text-sm font-semibold text-teal-600 border-2 border-teal-300 rounded-xl hover:bg-teal-50 hover:border-teal-400 transition-all duration-200 shadow-sm"
                        >
                          Book Again
                        </button>
                        {(booking.status === 'confirmed' || booking.status === 'completed') && (
                          <button
                            onClick={() => {
                              const invoiceData = {
                                booking: booking,
                                user: {
                                  name: user?.name || 'Customer',
                                  email: user?.email || '',
                                  phone: user?.mobile || '',
                                  address: booking.address
                                }
                              };
                              navigate('/invoice', { state: { invoiceData } });
                            }}
                            className="px-4 py-2 text-sm font-semibold text-green-600 border-2 border-green-300 rounded-xl hover:bg-green-50 hover:border-green-400 transition-all duration-200 shadow-sm"
                          >
                            Invoice
                          </button>
                        )}
                      </div>
                      <button
                        onClick={() => {
                          setSelectedBooking(booking);
                          setShowDetailsModal(true);
                        }}
                        className="px-6 py-2 text-sm font-semibold bg-gradient-to-r from-teal-600 to-teal-700 text-white rounded-xl hover:from-teal-700 hover:to-teal-800 transition-all duration-200 shadow-lg hover:shadow-xl"
                      >
                        View Details
                      </button>
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </motion.div>
      </div>

      {/* Booking Details Modal */}
      {showDetailsModal && selectedBooking && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-bold text-gray-900">Booking Details</h2>
                <button
                  onClick={() => setShowDetailsModal(false)}
                  className="text-gray-400 hover:text-gray-600 transition-colors"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <div className="space-y-6">
                {/* Service Information */}
                <div className="bg-gray-50 rounded-lg p-4">
                  <h3 className="text-lg font-semibold text-gray-900 mb-3">Service Information</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Service Name</label>
                      <p className="text-sm text-gray-900">{selectedBooking.service_name}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Category</label>
                      <p className="text-sm text-gray-900">{selectedBooking.category || 'Home Service'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Space Type</label>
                      <p className="text-sm text-gray-900">{selectedBooking.space_type || 'Standard'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Status</label>
                      <div className="flex items-center space-x-2">
                        {getStatusIcon(selectedBooking.status)}
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(selectedBooking.status)}`}>
                          {selectedBooking.status.charAt(0).toUpperCase() + selectedBooking.status.slice(1)}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Schedule Information */}
                <div className="bg-gray-50 rounded-lg p-4">
                  <h3 className="text-lg font-semibold text-gray-900 mb-3">Schedule</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Service Date</label>
                      <p className="text-sm text-gray-900">{formatDate(selectedBooking.service_date)}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Time Slot</label>
                      <p className="text-sm text-gray-900">{selectedBooking.service_time}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Booking Date</label>
                      <p className="text-sm text-gray-900">{formatDate(selectedBooking.booking_date)}</p>
                    </div>
                  </div>
                </div>

                {/* Location Information */}
                <div className="bg-gray-50 rounded-lg p-4">
                  <h3 className="text-lg font-semibold text-gray-900 mb-3">Location</h3>
                                       <div>
                       <label className="block text-sm font-medium text-gray-700">Service Address</label>
                       <p className="text-sm text-gray-900">{selectedBooking.address}</p>
                     </div>
                  {selectedBooking.special_notes && (
                    <div className="mt-3">
                      <label className="block text-sm font-medium text-gray-700">Special Instructions</label>
                      <p className="text-sm text-gray-900">{selectedBooking.special_notes}</p>
                    </div>
                  )}
                </div>

                {/* Payment Information */}
                <div className="bg-gray-50 rounded-lg p-4">
                  <h3 className="text-lg font-semibold text-gray-900 mb-3">Payment Details</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Item Total</label>
                      <p className="text-sm text-gray-900">₹{selectedBooking.item_total}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Taxes</label>
                      <p className="text-sm text-gray-900">₹{selectedBooking.taxes}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Total Amount</label>
                      <p className="text-lg font-semibold text-gray-900">₹{selectedBooking.total_amount}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Payment Status</label>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                        selectedBooking.payment_status === 'paid' 
                          ? 'bg-green-100 text-green-800' 
                          : 'bg-yellow-100 text-yellow-800'
                      }`}>
                        {selectedBooking.payment_status.charAt(0).toUpperCase() + selectedBooking.payment_status.slice(1)}
                      </span>
                    </div>
                    {selectedBooking.payment_mode && (
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Payment Mode</label>
                        <p className="text-sm text-gray-900">{selectedBooking.payment_mode}</p>
                      </div>
                    )}
                    {selectedBooking.payment_id && (
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Payment ID</label>
                        <p className="text-sm text-gray-900 font-mono">{selectedBooking.payment_id}</p>
                      </div>
                    )}
                  </div>
                </div>

                {/* Booking Information */}
                <div className="bg-gray-50 rounded-lg p-4">
                  <h3 className="text-lg font-semibold text-gray-900 mb-3">Booking Information</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Booking ID</label>
                      <p className="text-sm text-gray-900 font-mono">{selectedBooking.booking_id}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Can Cancel</label>
                      <p className="text-sm text-gray-900">{selectedBooking.can_cancel ? 'Yes' : 'No'}</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Modal Actions */}
              <div className="mt-6 flex justify-end space-x-3">
                {(selectedBooking.status === 'confirmed' || selectedBooking.status === 'completed') && (
                  <button
                    onClick={() => {
                      const invoiceData = {
                        booking: selectedBooking,
                        user: {
                          name: user?.name || 'Customer',
                          email: user?.email || '',
                          phone: user?.mobile || '',
                          address: selectedBooking.address
                        }
                      };
                      setShowDetailsModal(false);
                      navigate('/invoice', { state: { invoiceData } });
                    }}
                    className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                  >
                    Download Invoice
                  </button>
                )}
                <button
                  onClick={() => setShowDetailsModal(false)}
                  className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default BookingHistory; 
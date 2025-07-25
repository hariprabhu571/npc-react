import React, { useState } from 'react';
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
  FiStar
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { Booking } from '../types';
import { apiService } from '../services/api';
import { API_ENDPOINTS } from '../config/api';
import { useQuery } from 'react-query';
import toast from 'react-hot-toast';

const BookingHistory: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [activeFilter, setActiveFilter] = useState<'all' | 'pending' | 'accepted' | 'completed' | 'cancelled'>('all');

  // Fetch bookings
  const { data: bookingsData, isLoading, refetch } = useQuery(
    'bookings',
    () => apiService.get<Booking[]>(API_ENDPOINTS.USER_BOOKINGS),
    {
      retry: 1,
      onError: (error) => {
        toast.error('Failed to load bookings');
      }
    }
  );

  const bookings = bookingsData?.data || [];

  const filteredBookings = bookings.filter(booking => {
    if (activeFilter === 'all') return true;
    return booking.status === activeFilter;
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

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  const handleCancelBooking = async (bookingId: string) => {
    try {
      const response = await apiService.post(API_ENDPOINTS.CANCEL_BOOKING, {
        booking_id: bookingId
      });

      if (response.status === 'success') {
        toast.success('Booking cancelled successfully');
        refetch();
      } else {
        toast.error(response.message || 'Failed to cancel booking');
      }
    } catch (error) {
      toast.error('Failed to cancel booking');
    }
  };

  const filterOptions = [
    { value: 'all', label: 'All Bookings', count: bookings.length },
    { value: 'pending', label: 'Pending', count: bookings.filter(b => b.status === 'pending').length },
    { value: 'accepted', label: 'Accepted', count: bookings.filter(b => b.status === 'accepted').length },
    { value: 'completed', label: 'Completed', count: bookings.filter(b => b.status === 'completed').length },
    { value: 'cancelled', label: 'Cancelled', count: bookings.filter(b => b.status === 'cancelled').length },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => window.history.back()}
                className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <FiArrowLeft className="w-5 h-5" />
              </button>
              <div className="w-10 h-10 bg-teal-600 rounded-lg flex items-center justify-center">
                <FiShield className="w-6 h-6 text-white" />
              </div>
              <div>
                <h1 className="text-xl font-semibold text-gray-900">NPC</h1>
                <p className="text-sm text-gray-500">Professional Services</p>
              </div>
            </div>
            
            <div className="text-right">
              <p className="text-sm font-medium text-gray-900">Welcome,</p>
              <p className="text-sm text-gray-500">{user?.name || 'User'}</p>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
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

          {/* Filter Tabs */}
          <div className="mb-6">
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
          </div>

          {/* Bookings List */}
          {isLoading ? (
            <div className="flex justify-center items-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
            </div>
          ) : filteredBookings.length === 0 ? (
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
              {filteredBookings.map((booking, index) => (
                <motion.div
                  key={booking.booking_id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.3, delay: index * 0.1 }}
                  className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden"
                >
                  <div className="p-6">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center justify-between mb-4">
                          <h3 className="text-lg font-semibold text-gray-900">
                            {booking.service_name}
                          </h3>
                          <div className="flex items-center space-x-2">
                            {getStatusIcon(booking.status)}
                            <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(booking.status)}`}>
                              {booking.status.charAt(0).toUpperCase() + booking.status.slice(1)}
                            </span>
                          </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
                          <div className="flex items-center text-sm text-gray-600">
                            <FiCalendar className="w-4 h-4 mr-2" />
                            {formatDate(booking.service_date)}
                          </div>
                          <div className="flex items-center text-sm text-gray-600">
                            <FiClock className="w-4 h-4 mr-2" />
                            {booking.time_slot}
                          </div>
                          <div className="flex items-center text-sm text-gray-600">
                            <FiMapPin className="w-4 h-4 mr-2" />
                            <span className="truncate">{booking.service_address}</span>
                          </div>
                          <div className="flex items-center text-sm text-gray-600">
                            <FiDollarSign className="w-4 h-4 mr-2" />
                            ₹{booking.total_amount}
                          </div>
                        </div>

                        {booking.special_notes && (
                          <div className="mb-4">
                            <p className="text-sm text-gray-600">
                              <strong>Notes:</strong> {booking.special_notes}
                            </p>
                          </div>
                        )}

                        <div className="flex items-center justify-between text-sm text-gray-500">
                          <span>Booking ID: {booking.booking_id}</span>
                          <span>Created: {formatDate(booking.created_at)}</span>
                        </div>
                      </div>
                    </div>

                    {/* Action Buttons */}
                    {booking.status === 'pending' && (
                      <div className="mt-4 pt-4 border-t border-gray-200 flex space-x-3">
                        <button
                          onClick={() => handleCancelBooking(booking.booking_id)}
                          className="btn btn-secondary text-sm"
                        >
                          Cancel Booking
                        </button>
                        <button
                          onClick={() => navigate(`/service/${encodeURIComponent(booking.service_name)}`)}
                          className="btn btn-outline text-sm"
                        >
                          Book Again
                        </button>
                      </div>
                    )}

                    {booking.status === 'completed' && (
                      <div className="mt-4 pt-4 border-t border-gray-200">
                        <button
                          onClick={() => navigate(`/service/${encodeURIComponent(booking.service_name)}`)}
                          className="btn btn-primary text-sm"
                        >
                          Book Again
                        </button>
                      </div>
                    )}
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </motion.div>
      </div>
    </div>
  );
};

export default BookingHistory; 
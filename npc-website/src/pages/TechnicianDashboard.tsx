import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { 
  FiShield, 
  FiArrowLeft, 
  FiCalendar, 
  FiClock, 
  FiMapPin,
  FiUser,
  FiCheckCircle,
  FiXCircle,
  FiLogOut,
  FiList,
  FiCheck,
  FiX
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { Booking } from '../types';
import { apiService } from '../services/api';
import { API_ENDPOINTS } from '../config/api';
import { useQuery } from 'react-query';
import toast from 'react-hot-toast';

const TechnicianDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<'assigned' | 'completed'>('assigned');

  // Fetch technician orders
  const { data: ordersData, isLoading, refetch } = useQuery(
    'technician-orders',
    () => apiService.get<Booking[]>(API_ENDPOINTS.TECHNICIAN_ORDERS),
    {
      retry: 1,
      onError: (error) => {
        toast.error('Failed to load orders');
      }
    }
  );

  const orders = ordersData?.data || [];

  const assignedOrders = orders.filter(order => 
    order.technician_status === 'assigned' || 
    order.technician_status === 'reached' || 
    order.technician_status === 'started'
  );

  const completedOrders = orders.filter(order => 
    order.technician_status === 'completed'
  );

  const handleUpdateStatus = async (bookingId: string, status: string) => {
    try {
      const response = await apiService.post(API_ENDPOINTS.UPDATE_ORDER_STATUS, {
        booking_id: bookingId,
        technician_status: status
      });

      if (response.status === 'success') {
        toast.success(`Order status updated to ${status}`);
        refetch();
      } else {
        toast.error(response.message || 'Failed to update status');
      }
    } catch (error) {
      toast.error('Failed to update order status');
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'started':
        return 'bg-blue-100 text-blue-800';
      case 'reached':
        return 'bg-yellow-100 text-yellow-800';
      case 'assigned':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <FiCheckCircle className="w-5 h-5 text-green-500" />;
      case 'started':
        return <FiClock className="w-5 h-5 text-blue-500" />;
      case 'reached':
        return <FiMapPin className="w-5 h-5 text-yellow-500" />;
      case 'assigned':
        return <FiList className="w-5 h-5 text-gray-500" />;
      default:
        return <FiList className="w-5 h-5 text-gray-500" />;
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

  const statsCards = [
    {
      title: 'Assigned Orders',
      value: assignedOrders.length,
      icon: FiList,
      color: 'bg-blue-500'
    },
    {
      title: 'Completed Today',
      value: completedOrders.filter(order => {
        const today = new Date().toDateString();
        return new Date(order.service_date).toDateString() === today;
      }).length,
      icon: FiCheckCircle,
      color: 'bg-green-500'
    },
    {
      title: 'Total Completed',
      value: completedOrders.length,
      icon: FiCheckCircle,
      color: 'bg-purple-500'
    }
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
                <h1 className="text-xl font-semibold text-gray-900">NPC Technician</h1>
                <p className="text-sm text-gray-500">Order Management</p>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              <div className="text-right">
                <p className="text-sm font-medium text-gray-900">Welcome,</p>
                <p className="text-sm text-gray-500">{user?.name || 'Technician'}</p>
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
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          {/* Page Header */}
          <div className="mb-8">
            <h2 className="text-3xl font-bold text-gray-900 mb-2">Technician Dashboard</h2>
            <p className="text-gray-600">Manage your assigned orders and track progress</p>
          </div>

          {/* Statistics Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            {statsCards.map((stat, index) => (
              <motion.div
                key={stat.title}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.3, delay: index * 0.1 }}
                className="bg-white rounded-lg shadow-sm p-6"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600">{stat.title}</p>
                    <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                  </div>
                  <div className={`w-12 h-12 ${stat.color} rounded-lg flex items-center justify-center`}>
                    <stat.icon className="w-6 h-6 text-white" />
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          {/* Tab Navigation */}
          <div className="mb-6">
            <div className="border-b border-gray-200">
              <nav className="-mb-px flex space-x-8">
                <button
                  onClick={() => setActiveTab('assigned')}
                  className={`py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                    activeTab === 'assigned'
                      ? 'border-teal-500 text-teal-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  <FiList className="inline w-4 h-4 mr-1" />
                  Assigned Orders ({assignedOrders.length})
                </button>
                <button
                  onClick={() => setActiveTab('completed')}
                  className={`py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                    activeTab === 'completed'
                      ? 'border-teal-500 text-teal-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  <FiCheckCircle className="inline w-4 h-4 mr-1" />
                  Completed Orders ({completedOrders.length})
                </button>
              </nav>
            </div>
          </div>

          {/* Orders List */}
          {isLoading ? (
            <div className="flex justify-center items-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
            </div>
          ) : (
            <div className="space-y-4">
              {(activeTab === 'assigned' ? assignedOrders : completedOrders).map((order, index) => (
                <motion.div
                  key={order.booking_id}
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
                            {order.service_name}
                          </h3>
                          <div className="flex items-center space-x-2">
                            {getStatusIcon(order.technician_status || 'assigned')}
                            <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(order.technician_status || 'assigned')}`}>
                              {order.technician_status || 'assigned'}
                            </span>
                          </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
                          <div className="flex items-center text-sm text-gray-600">
                            <FiCalendar className="w-4 h-4 mr-2" />
                            {formatDate(order.service_date)}
                          </div>
                          <div className="flex items-center text-sm text-gray-600">
                            <FiClock className="w-4 h-4 mr-2" />
                            {order.service_time}
                          </div>
                          <div className="flex items-center text-sm text-gray-600">
                            <FiMapPin className="w-4 h-4 mr-2" />
                            <span className="truncate">{order.address}</span>
                          </div>
                          <div className="flex items-center text-sm text-gray-600">
                            <FiUser className="w-4 h-4 mr-2" />
                            Booking ID: {order.booking_id}
                          </div>
                        </div>

                        {order.special_notes && (
                          <div className="mb-4">
                            <p className="text-sm text-gray-600">
                              <strong>Notes:</strong> {order.special_notes}
                            </p>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Action Buttons for Assigned Orders */}
                    {activeTab === 'assigned' && (
                      <div className="mt-4 pt-4 border-t border-gray-200">
                        <div className="flex flex-wrap gap-3">
                          {order.technician_status === 'assigned' && (
                            <button
                              onClick={() => handleUpdateStatus(order.booking_id, 'reached')}
                              className="btn btn-outline text-sm"
                            >
                              <FiMapPin className="w-4 h-4 mr-2" />
                              Mark as Reached
                            </button>
                          )}
                          
                          {order.technician_status === 'reached' && (
                            <button
                              onClick={() => handleUpdateStatus(order.booking_id, 'started')}
                              className="btn btn-outline text-sm"
                            >
                              <FiClock className="w-4 h-4 mr-2" />
                              Start Service
                            </button>
                          )}
                          
                          {order.technician_status === 'started' && (
                            <button
                              onClick={() => handleUpdateStatus(order.booking_id, 'completed')}
                              className="btn btn-primary text-sm"
                            >
                              <FiCheck className="w-4 h-4 mr-2" />
                              Complete Service
                            </button>
                          )}
                          
                          <button
                            onClick={() => handleUpdateStatus(order.booking_id, 'cancelled')}
                            className="btn btn-secondary text-sm"
                          >
                            <FiX className="w-4 h-4 mr-2" />
                            Cancel Order
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                </motion.div>
              ))}

              {(activeTab === 'assigned' ? assignedOrders : completedOrders).length === 0 && (
                <div className="text-center py-12">
                  <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    {activeTab === 'assigned' ? (
                      <FiList className="w-12 h-12 text-gray-400" />
                    ) : (
                      <FiCheckCircle className="w-12 h-12 text-gray-400" />
                    )}
                  </div>
                  <h3 className="text-lg font-medium text-gray-900 mb-2">
                    No {activeTab} orders found
                  </h3>
                  <p className="text-gray-600">
                    {activeTab === 'assigned' 
                      ? "You don't have any assigned orders at the moment."
                      : "You haven't completed any orders yet."
                    }
                  </p>
                </div>
              )}
            </div>
          )}
        </motion.div>
      </div>
    </div>
  );
};

export default TechnicianDashboard; 
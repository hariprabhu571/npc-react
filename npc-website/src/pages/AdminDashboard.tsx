import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  FiCalendar,
  FiUsers,
  FiSettings,
  FiLogOut,
  FiBarChart,
  FiSearch,
  FiList,
  FiGrid,
  FiTable
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { Booking, Employee, ContactQuery as BaseContactQuery } from '../types';
import { apiService } from '../services/api';
import api from '../services/api';
import { API_ENDPOINTS, getApiUrl, API_BASE_URL } from '../config/api';
import { useQuery } from 'react-query';
import toast from 'react-hot-toast';

type ContactQuery = BaseContactQuery & {
  id?: string;
  admin_response?: string;
  response_date?: string;
  user_id?: string | number;
  customer_name?: string;
  mobile_number?: string;
  created_at_formatted?: string;
  updated_at?: string;
  has_response?: boolean;
  response_date_formatted?: string;
};

// Minimal Modal component for local use
const Modal: React.FC<{ onClose: () => void; children: React.ReactNode; size?: 'small' | 'large' }> = ({ onClose, children, size = 'large' }) => {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkMobile = () => setIsMobile(window.innerWidth < 640);
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const modalStyle: React.CSSProperties = isMobile
    ? {
        background: 'white',
        borderRadius: 8,
        padding: 12,
        position: 'relative',
        width: '95vw',
        maxWidth: '95vw',
        minWidth: 0,
        boxSizing: 'border-box',
        maxHeight: '95vh',
        overflowY: 'auto',
      }
    : size === 'small'
    ? {
        background: 'white',
        borderRadius: 8,
        padding: 24,
        position: 'relative',
        minWidth: 400,
        maxWidth: 500,
        width: '100%',
        boxSizing: 'border-box',
        maxHeight: '95vh',
        overflowY: 'auto',
      }
    : {
        background: 'white',
        borderRadius: 8,
        padding: 24,
        position: 'relative',
        minWidth: 1000,
        maxWidth: 1200,
        width: '90%',
        boxSizing: 'border-box',
        maxHeight: '95vh',
        overflowY: 'auto',
      };
  const containerStyle: React.CSSProperties = {
    position: 'fixed',
    top: 0,
    left: 0,
    width: '100vw',
    height: '100vh',
    background: 'rgba(0,0,0,0.3)',
    zIndex: 1000,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  };
  return (
    <div style={containerStyle}>
      <div style={modalStyle}>
        <button onClick={onClose} style={{ position: 'absolute', top: 8, right: 12, fontSize: 20, background: 'none', border: 'none', cursor: 'pointer' }}>&times;</button>
        {children}
      </div>
    </div>
  );
};

// Add Service Modal component
const ServiceModal: React.FC<{
  onClose: () => void;
  onSave: (service: any, imageFile?: File | null) => void;
  initialData?: any;
}> = ({ onClose, onSave, initialData }) => {
  // Service meta fields
  const [serviceName, setServiceName] = useState(initialData?.service_name || '');
  const [description, setDescription] = useState(initialData?.description || '');
  const [locations, setLocations] = useState(initialData?.locations || []);
  const [editImage, setEditImage] = useState<File | null>(null);
  const [editImagePreview, setEditImagePreview] = useState<string | null>(null);
  const isAddMode = !initialData;

  useEffect(() => {
    setServiceName(initialData?.service_name || '');
    setDescription(initialData?.description || '');
    let locationsData = [];
    if (initialData?.locations) {
      try {
        const parsed = typeof initialData.locations === 'string' ? JSON.parse(initialData.locations) : initialData.locations;
        locationsData = Array.isArray(parsed) ? parsed : [];
      } catch {
        locationsData = [];
      }
    }
    setLocations(locationsData);
    if (initialData?.image_path) {
      setEditImagePreview(`${API_BASE_URL}${initialData.image_path}`);
    } else {
      setEditImagePreview(null);
    }
    setEditImage(null);
  }, [initialData]);

  // Save handler for both add and edit
  const handleSave = async () => {
    try {
      // Prepare FormData for image upload
      const formData = new FormData();
      if (editImage) {
        formData.append('service_image', editImage);
      }
      if (!isAddMode) {
        formData.append('service_id', initialData?.service_id || '');
      }
      formData.append('service_name', serviceName);
      formData.append('description', description);
      formData.append('locations', Array.isArray(locations) ? JSON.stringify(locations) : locations);
      formData.append('action', isAddMode ? 'add_service' : 'update_service');

      // Use the same endpoint as the app - services_manager.php
      const response = await api.post(API_ENDPOINTS.UPDATE_SERVICE_DETAILS, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      if (response.data.status === 'success') {
        alert(isAddMode ? 'Service added successfully!' : 'Service details updated successfully!');
        onSave({
          service_name: serviceName,
          description,
          locations: Array.isArray(locations) ? JSON.stringify(locations) : locations,
          image_path: response.data.image_path || (editImage ? `ServiceImages/${editImage.name}` : initialData?.image_path)
        }, editImage);
      } else {
        alert('Failed to save service. Please try again.');
      }
    } catch (error) {
      alert('Failed to save service. Please try again.');
    }
  };

  // Render only the Edit Service Details dialog for add mode, or as a dialog in edit mode
  return (
    <div className="p-6 w-full">
      <h3 className="text-lg font-semibold mb-4">{isAddMode ? 'Add Service' : 'Edit Service Details'}</h3>
      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-1">Service Name</label>
        <input
          type="text"
          className="w-full border border-gray-300 rounded px-3 py-2"
          value={serviceName}
          onChange={e => setServiceName(e.target.value)}
        />
      </div>
      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
        <textarea
          className="w-full border border-gray-300 rounded px-3 py-2"
          value={description}
          onChange={e => setDescription(e.target.value)}
        />
      </div>
      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-1">Locations (comma separated)</label>
        <input
          type="text"
          className="w-full border border-gray-300 rounded px-3 py-2"
          value={Array.isArray(locations) ? locations.join(', ') : locations}
          onChange={e => setLocations(e.target.value.split(',').map(s => s.trim()))}
        />
      </div>
      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-1">Service Image</label>
        <div className="flex items-center space-x-4">
          <div className="flex-1">
            <input
              type="file"
              accept="image/*"
              className="w-full border border-gray-300 rounded px-3 py-2"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) {
                  setEditImage(file);
                  const reader = new FileReader();
                  reader.onload = (e) => {
                    setEditImagePreview(e.target?.result as string);
                  };
                  reader.readAsDataURL(file);
                }
              }}
            />
          </div>
          {editImagePreview && (
            <div className="relative w-16 h-16 border border-gray-300 rounded overflow-hidden">
              <img 
                src={editImagePreview} 
                alt="Preview" 
                className="w-full h-full object-cover"
              />
              <button
                type="button"
                className="absolute -top-1 -right-1 bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center text-xs hover:bg-red-600"
                onClick={() => {
                  setEditImagePreview(null);
                  setEditImage(null);
                }}
              >
                ×
              </button>
            </div>
          )}
        </div>
        <p className="text-xs text-gray-500 mt-1">Upload an image for this service (JPG, PNG, GIF)</p>
      </div>
      <div className="flex justify-end gap-2">
        <button
          className="px-4 py-2 rounded bg-gray-200 text-gray-700"
          onClick={onClose}
        >
          Cancel
        </button>
        <button
          className="px-4 py-2 rounded bg-blue-500 text-white"
          onClick={handleSave}
        >
          Save
        </button>
      </div>
    </div>
  );
};

const AdminDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('overview');

  // Modal state for viewing and replying to queries
  const [viewedQuery, setViewedQuery] = useState<ContactQuery | null>(null);
  const [replyingQuery, setReplyingQuery] = useState<ContactQuery | null>(null);
  const [replyText, setReplyText] = useState('');
  const [isReplying, setIsReplying] = useState(false);

  // Modal state for viewing a booking and technician assignment
  const [viewedBooking, setViewedBooking] = useState<any | null>(null);
  const [selectedTechnician, setSelectedTechnician] = useState<string>('');
  const [isAssigning, setIsAssigning] = useState(false);

  // Search and filter state for Contact Queries
  const [querySearch, setQuerySearch] = useState('');
  const [queryStatus, setQueryStatus] = useState('all');

  // View mode for Contact Queries
  const [queryView, setQueryView] = useState<'table' | 'card' | 'list'>('table');

  // Search, filter, and view state for Bookings
  const [bookingSearch, setBookingSearch] = useState('');
  const [bookingStatus, setBookingStatus] = useState('all');
  const [bookingView, setBookingView] = useState<'table' | 'card' | 'list'>('table');

  // Services tab state
  const [activeServiceModal, setActiveServiceModal] = useState<'add' | 'edit' | null>(null);
  const [editingService, setEditingService] = useState<any>(null);
  const [serviceToDelete, setServiceToDelete] = useState<any>(null);
  const [services, setServices] = useState<any[]>([]);
  const [servicesLoading, setServicesLoading] = useState(false);
  const fetchServices = async () => {
    setServicesLoading(true);
    try {
      const res = await apiService.get<any>(API_ENDPOINTS.GET_SERVICE_TYPES);
      if (res.status === 'success' && (res as any).services) {
        setServices(Array.isArray((res as any).services) ? (res as any).services : []);
      } else {
        setServices([]);
        toast.error((res as any).message || 'Failed to load services');
      }
    } catch (error: any) {
      console.error('Services fetch error:', error);
      setServices([]);
      toast.error('Failed to load services');
    } finally {
      setServicesLoading(false);
    }
  };
  useEffect(() => { if (activeTab === 'services') fetchServices(); }, [activeTab]);
  const handleAddService = async (service: any) => {
    try {
      await apiService.post(API_ENDPOINTS.UPDATE_SERVICE_DETAILS, {
        action: 'add_service',
        service_name: service.service_name,
        description: service.description,
        locations: service.locations
      });
      toast.success('Service added');
      setActiveServiceModal(null);
      fetchServices();
    } catch (error: any) {
      console.error('Add service error:', error);
      toast.error('Failed to add service');
    }
  };
  const handleEditService = async (service: any) => {
    try {
      await apiService.post(API_ENDPOINTS.UPDATE_SERVICE_DETAILS, {
        action: 'update_service',
        service_id: editingService.service_id,
        service_name: service.service_name,
        description: service.description,
        locations: service.locations
      });
      toast.success('Service updated');
      setActiveServiceModal(null);
      setEditingService(null);
      fetchServices();
    } catch (error: any) {
      console.error('Edit service error:', error);
      toast.error('Failed to update service');
    }
  };
  const handleDeleteService = async () => {
    try {
      await apiService.post(API_ENDPOINTS.UPDATE_SERVICE_DETAILS, { 
        action: 'delete_service',
        service_id: serviceToDelete.service_id 
      });
      toast.success('Service deleted');
      setServiceToDelete(null);
      fetchServices();
    } catch (error: any) {
      console.error('Delete error:', error);
      toast.error('Failed to delete service');
    }
  };

  const handleViewQuery = (query: ContactQuery) => {
    setViewedQuery(query);
  };

  const handleReplyQuery = (query: ContactQuery) => {
    setReplyingQuery(query);
    setReplyText('');
  };

  const handleViewBooking = (booking: any) => {
    setViewedBooking(booking);
    setSelectedTechnician(booking.technician_id || '');
  };

  const handleAssignTechnician = async () => {
    if (!viewedBooking || !selectedTechnician) {
      toast.error('Please select a technician');
      return;
    }
    setIsAssigning(true);
    try {
      const res = await apiService.post(getApiUrl(API_ENDPOINTS.ASSIGN_TECHNICIAN), {
        booking_id: viewedBooking.booking_id,
        technician_id: selectedTechnician
      });
      if (res.status === 'success') {
        toast.success('Technician assigned successfully!');
        setViewedBooking(null); // Close the modal
        refetchBookings && refetchBookings(); // Refresh bookings list
      } else {
        toast.error(res.message || 'Failed to assign technician');
      }
    } catch (e: any) {
      toast.error(e.message || 'Network error');
    } finally {
      setIsAssigning(false);
    }
  };

  // Fetch data
  const { data: queriesData, isLoading: queriesLoading, refetch: refetchQueries } = useQuery(
    'contact-queries',
    () => apiService.get<ContactQuery[]>(API_ENDPOINTS.ADMIN_CONTACT_QUERIES),
    {
      retry: 1,
      onError: (error) => {
        toast.error('Failed to load contact queries');
      },
    }
  );

  const handleSubmitReply = async () => {
    if (!replyText.trim() || !replyingQuery) {
      toast.error('Response cannot be empty');
      return;
    }
    setIsReplying(true);
    try {
      const data = await apiService.post(
        getApiUrl(API_ENDPOINTS.ADMIN_CONTACT_QUERIES),
        {
          query_id: replyingQuery.id,
          response: replyText,
          status: 'responded',
        }
      );
      if (data.status === 'success') {
        toast.success('Response submitted successfully!');
        setReplyingQuery(null);
        setReplyText('');
        refetchQueries();
      } else {
        toast.error(data.message || 'Failed to submit response');
      }
    } catch (e: any) {
      toast.error(e.message || 'Network error. Please try again.');
    } finally {
      setIsReplying(false);
    }
  };

  // Fetch data
  const { data: bookingsData, isLoading: bookingsLoading, refetch: refetchBookings } = useQuery(
    'admin-bookings',
    () => apiService.get<Booking[]>(API_ENDPOINTS.ADMIN_ORDERS),
    {
      retry: 1,
      onError: (error) => {
        toast.error('Failed to load bookings');
      },
    }
  );
  const { data: employeesData, isLoading: employeesLoading } = useQuery(
    'employees',
    () => apiService.get<Employee[]>(API_ENDPOINTS.GET_TECHNICIANS),
    {
      retry: 1,
      onError: (error) => {
        toast.error('Failed to load employees');
      },
    }
  );
  const { data: offersData, isLoading: offersLoading } = useQuery(
    'offers',
    () => apiService.get<any>(API_ENDPOINTS.FETCH_OFFERS),
    {
      retry: 1,
      onError: (error) => {
        toast.error('Failed to load offers');
      },
    }
  );

  // Bookings and employees data processing
  const bookingsDataAny = bookingsData as any;
  const bookings = [
    ...(bookingsDataAny?.orders?.pending || []),
    ...(bookingsDataAny?.orders?.completed || []),
    ...(bookingsDataAny?.orders?.accepted || []),
  ].sort((a, b) => new Date(b.service_date).getTime() - new Date(a.service_date).getTime());
  const employeesDataAny = employeesData as any;
  const employees = (employeesDataAny?.data || []).map((emp: any) => ({
    id: emp.technician_id,
    name: emp.employee_name,
    email: emp.email,
    mobile: emp.phone_number,
    serviceType: emp.service_type,
    address: emp.address,
    idProof: emp.id_proof,
  }));
  const queriesDataAny = queriesData as any;
  const queries = queriesDataAny?.queries || queriesDataAny?.data?.queries || [];

  // Stats
  const totalBookings = bookings.length;
  const pendingBookings = bookings.filter(b => b.booking_status === 'pending').length;
  const completedBookings = bookings.filter(b => b.booking_status === 'completed').length;
  const totalRevenue = bookings.reduce((sum, b) => sum + b.total_amount, 0);
  const pendingQueries = queries.filter((q: any) => q.status === 'pending').length;

  const statsCards = [
    {
      title: 'Total Bookings',
      value: totalBookings,
      icon: FiCalendar,
      color: 'bg-blue-500',
    },
    {
      title: 'Pending Bookings',
      value: pendingBookings,
      icon: FiCalendar,
      color: 'bg-yellow-500',
    },
    {
      title: 'Total Revenue',
      value: `₹${totalRevenue.toLocaleString()}`,
      icon: FiCalendar,
      color: 'bg-green-500',
    },
    {
      title: 'Active Employees',
      value: employees.length,
      icon: FiUsers,
      color: 'bg-purple-500',
    },
  ];

  // Navigation items for sidebar
  const navigationItems = [
    { id: 'overview', label: 'Overview', icon: FiBarChart },
    { id: 'bookings', label: 'Bookings', icon: FiCalendar },
    { id: 'employees', label: 'Employees', icon: FiUsers },
    { id: 'services', label: 'Services', icon: FiSettings },
    { id: 'queries', label: 'Contact Queries', icon: FiSettings },
  ];

  // Helper functions
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
      case 'responded':
        return 'bg-green-100 text-green-800';
      case 'accepted':
      case 'confirmed':
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
    return date.toLocaleDateString('en-GB', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
  };

  // Main render
  return (
    <div className="min-h-screen bg-gray-50 font-sans flex">
      {/* Sidebar Navigation */}
      <aside className="h-screen w-64 bg-white shadow-lg flex flex-col fixed left-0 top-0 z-30 border-r">
        <div className="h-20 flex items-center px-8 border-b">
          <div className="w-12 h-12 bg-teal-600 rounded-xl flex items-center justify-center mr-4">
            <FiBarChart className="w-7 h-7 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-semibold text-gray-900 tracking-tight">NPC Admin</h1>
            <p className="text-xs text-gray-500 font-medium">Administration Panel</p>
          </div>
        </div>
        <nav className="flex-1 py-8 px-4 space-y-2">
          {[
            { id: 'overview', label: 'Overview', icon: FiBarChart },
            { id: 'bookings', label: 'Bookings', icon: FiCalendar },
            { id: 'employees', label: 'Employees', icon: FiUsers },
            { id: 'services', label: 'Services', icon: FiSettings },
            { id: 'queries', label: 'Contact Queries', icon: FiSettings }
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`w-full flex items-center gap-3 px-5 py-3 rounded-xl text-base font-medium transition-colors duration-200
                ${activeTab === tab.id
                  ? 'bg-teal-100 text-teal-700 shadow border-l-4 border-teal-500'
                  : 'text-gray-700 hover:bg-gray-100'}
              `}
            >
              <tab.icon className="w-5 h-5" />
              <span>{tab.label}</span>
            </button>
          ))}
        </nav>
        <div className="px-8 py-6 border-t mt-auto bg-white">
          <div className="mb-2">
            <span className="text-sm text-gray-700">Welcome, <span className="font-semibold">{user?.name || 'Admin'}</span></span>
          </div>
          <button
            onClick={logout}
            className="w-full flex items-center justify-center gap-2 py-2 rounded-lg border border-gray-200 text-gray-500 hover:text-red-600 hover:border-red-200 transition-colors font-semibold"
          >
            <FiLogOut className="w-4 h-4" /> Logout
          </button>
        </div>
      </aside>
      {/* Main Content */}
      <main className="flex-1 ml-64">
        <motion.div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
          {/* Page Title for all tabs */}
          <div className="mb-10">
            {activeTab === 'overview' && <>
              <h2 className="text-3xl font-semibold text-gray-900 mb-1 tracking-tight">Admin Dashboard</h2>
              <p className="text-lg text-gray-500">Manage your business operations</p>
            </>}
            {activeTab === 'bookings' && (
              <h2 className="text-3xl font-semibold text-gray-900 mb-1 tracking-tight">All Bookings</h2>
            )}
            {activeTab === 'employees' && (
              <h2 className="text-3xl font-semibold text-gray-900 mb-1 tracking-tight">Employees</h2>
            )}
            {activeTab === 'queries' && (
              <h2 className="text-3xl font-semibold text-gray-900 mb-1 tracking-tight">Contact Queries</h2>
            )}
            {activeTab === 'services' && (
              <h2 className="text-3xl font-semibold text-gray-900 mb-1 tracking-tight">Services</h2>
            )}
          </div>
          {/* Stats Cards - only on Overview */}
          {activeTab === 'overview' && (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
              {statsCards.map((stat, index) => (
                <div
                  key={stat.title}
                  className="bg-white rounded-2xl shadow flex items-center gap-4 p-6 min-h-[110px]"
                >
                  <div className={`w-14 h-14 flex items-center justify-center rounded-xl ${stat.color} bg-opacity-20`}> 
                    <stat.icon className={`w-7 h-7 ${stat.color.replace('bg-', 'text-')}`} />
                  </div>
                  <div>
                    <p className="text-base font-medium text-gray-500 mb-1">{stat.title}</p>
                    <p className="text-2xl font-semibold text-gray-900">{stat.value}</p>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Overview Content */}
          {activeTab === 'overview' && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              {/* Recent Bookings */}
              <div className="bg-white rounded-2xl shadow p-8">
                <h3 className="text-xl font-semibold text-gray-900 mb-6">Recent Bookings</h3>
                {bookingsLoading ? (
                  <div className="flex justify-center py-8">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600"></div>
                  </div>
                ) : bookings.length === 0 ? (
                  <p className="text-gray-500 text-center py-8">No bookings found</p>
                ) : (
                  <div className="space-y-4">
                    {bookings.slice(0, 5).map((booking) => (
                      <div key={booking.booking_id} className="flex items-center justify-between bg-gray-50 rounded-xl px-5 py-4 hover:bg-gray-100 transition">
                        <div>
                          <p className="font-medium text-base text-gray-900">{booking.service_name}</p>
                          <p className="text-gray-500 text-sm">{formatDate(booking.service_date)}</p>
                        </div>
                        <span className={`px-4 py-1 rounded-full text-xs font-semibold ${getStatusColor(booking.booking_status)} capitalize`}>
                          {booking.booking_status}
                        </span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
              {/* Pending Queries */}
              <div className="bg-white rounded-2xl shadow p-8">
                <h3 className="text-xl font-semibold text-gray-900 mb-6">Pending Contact Queries</h3>
                {queriesLoading ? (
                  <div className="flex justify-center py-8">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600"></div>
                  </div>
                ) : pendingQueries === 0 ? (
                  <p className="text-gray-500 text-center py-8">No pending queries</p>
                ) : (
                  <div className="space-y-4">
                    {queries.filter((q: any) => q.status === 'pending').slice(0, 5).map((query: any) => (
                      <div key={query.query_id} className="bg-gray-50 rounded-xl px-5 py-4 hover:bg-gray-100 transition">
                        <p className="font-medium text-base text-gray-900 mb-1">{query.subject}</p>
                        <p className="text-gray-500 text-sm mb-1">{query.message}</p>
                        <p className="text-xs text-gray-400">{formatDate(query.created_at)}</p>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}

            {activeTab === 'bookings' && (
              <div className="bg-white rounded-lg shadow-sm overflow-hidden">
                {/* Bookings Controls: Search, Filter, View Toggle */}
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 px-6 py-4 border-b border-gray-100 bg-gray-50 mb-2">
                  {/* Left: Search Bar */}
                  <div className="relative w-full sm:w-[32rem] mb-2 sm:mb-0">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
                      <FiSearch className="w-5 h-5" />
                    </span>
                    <input
                      type="text"
                      className="w-full pl-10 pr-3 py-2 border border-gray-200 rounded-lg shadow-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 text-sm placeholder-gray-400"
                      placeholder="Search bookings..."
                      value={bookingSearch}
                      onChange={e => setBookingSearch(e.target.value)}
                    />
                  </div>
                  {/* Right: Filter and View Toggle */}
                  <div className="flex items-center gap-3 w-full sm:w-auto justify-end">
                    <div className="flex items-center gap-2">
                      <label htmlFor="bookingStatus" className="text-sm text-gray-500 font-medium hidden sm:block">Status:</label>
                      <select
                        id="bookingStatus"
                        className="w-full sm:w-44 px-3 py-2 border border-gray-200 rounded-lg shadow-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 text-sm bg-white"
                        value={bookingStatus}
                        onChange={e => setBookingStatus(e.target.value)}
                      >
                        <option value="all">All Statuses</option>
                        <option value="pending">Pending</option>
                        <option value="confirmed">Confirmed</option>
                        <option value="completed">Completed</option>
                      </select>
                    </div>
                    <div className="flex gap-2">
                      <button
                        className={`p-2 rounded-lg border ${bookingView === 'table' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="Table View"
                        onClick={() => setBookingView('table')}
                      >
                        <FiTable className="w-5 h-5" />
                      </button>
                      <button
                        className={`p-2 rounded-lg border ${bookingView === 'card' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="Card View"
                        onClick={() => setBookingView('card')}
                      >
                        <FiGrid className="w-5 h-5" />
                      </button>
                      <button
                        className={`p-2 rounded-lg border ${bookingView === 'list' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="List View"
                        onClick={() => setBookingView('list')}
                      >
                        <FiList className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </div>
                {/* Filtered and Searched Bookings */}
                {bookingsLoading ? (
                  <div className="flex justify-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
                  </div>
                ) : (
                  <>
                    {/* Table View */}
                    {bookingView === 'table' && (
                      <div className="overflow-x-auto">
                        <table className="min-w-full divide-y divide-gray-200">
                          <thead className="bg-gray-50">
                            <tr>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Service</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">VIEW DETAILS</th>
                            </tr>
                          </thead>
                          <tbody className="bg-white divide-y divide-gray-200">
                            {bookings
                              .filter((booking: any) => {
                                if (bookingStatus !== 'all' && booking.booking_status !== bookingStatus) return false;
                                const search = bookingSearch.toLowerCase();
                                return (
                                  booking.service_name?.toLowerCase().includes(search) ||
                                  booking.booking_id?.toLowerCase().includes(search) ||
                                  booking.customer_name?.toLowerCase().includes(search)
                                );
                              })
                              .map((booking) => (
                                <tr key={booking.booking_id}>
                                  <td className="px-6 py-4 whitespace-nowrap">
                                    <div className="text-sm font-medium text-gray-900">{booking.service_name}</div>
                                    <div className="text-sm text-gray-500">{booking.booking_id}</div>
                                  </td>
                                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                    {formatDate(booking.service_date)}
                                  </td>
                                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                    ₹{booking.total_amount}
                                  </td>
                                  <td className="px-6 py-4 whitespace-nowrap">
                                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(booking.booking_status)}`}>
                                      {booking.booking_status}
                                    </span>
                                  </td>
                                  <td className="px-6 py-4 whitespace-nowrap">
                                    <button
                                      className="bg-teal-500 hover:bg-teal-600 text-white px-4 py-2 rounded font-semibold text-xs transition"
                                      onClick={() => handleViewBooking(booking)}
                                    >
                                      View
                                    </button>
                                  </td>
                                </tr>
                              ))}
                          </tbody>
                        </table>
                      </div>
                    )}
                    {/* Card View */}
                    {bookingView === 'card' && (
                      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 p-4">
                        {bookings
                          .filter((booking: any) => {
                            if (bookingStatus !== 'all' && booking.booking_status !== bookingStatus) return false;
                            const search = bookingSearch.toLowerCase();
                            return (
                              booking.service_name?.toLowerCase().includes(search) ||
                              booking.booking_id?.toLowerCase().includes(search) ||
                              booking.customer_name?.toLowerCase().includes(search)
                            );
                          })
                          .map((booking: any) => (
                            <div key={booking.booking_id} className="bg-white rounded-xl shadow p-5 flex flex-col gap-2 border border-gray-100">
                              <div className="flex items-center justify-between mb-2">
                                <span className="font-semibold text-gray-900 text-base">{booking.service_name}</span>
                                <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(booking.booking_status)} capitalize`}>
                                  {booking.booking_status}
                                </span>
                              </div>
                              <div className="text-xs text-gray-500 mb-1">{booking.booking_id}</div>
                              <div className="font-medium text-gray-700">{booking.customer_name}</div>
                              <div className="text-gray-500 text-sm">{formatDate(booking.service_date)}</div>
                              <div className="text-xs text-gray-400 mt-1">₹{booking.total_amount}</div>
                              <div className="flex gap-2 mt-3">
                                <button
                                  className="bg-teal-500 hover:bg-teal-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                  onClick={() => handleViewBooking(booking)}
                                >
                                  View
                                </button>
                              </div>
                            </div>
                          ))}
                      </div>
                    )}
                    {/* List View */}
                    {bookingView === 'list' && (
                      <div className="divide-y divide-gray-100 bg-white rounded-xl shadow p-2">
                        {bookings
                          .filter((booking: any) => {
                            if (bookingStatus !== 'all' && booking.booking_status !== bookingStatus) return false;
                            const search = bookingSearch.toLowerCase();
                            return (
                              booking.service_name?.toLowerCase().includes(search) ||
                              booking.booking_id?.toLowerCase().includes(search) ||
                              booking.customer_name?.toLowerCase().includes(search)
                            );
                          })
                          .map((booking: any) => (
                            <div key={booking.booking_id} className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 py-3 px-2">
                              <div className="flex-1 min-w-0">
                                <div className="font-semibold text-gray-900 text-sm truncate">{booking.service_name}</div>
                                <div className="text-xs text-gray-500 truncate">{booking.booking_id}</div>
                                <div className="text-xs text-gray-700 truncate">{booking.customer_name}</div>
                                <div className="text-xs text-gray-400">{formatDate(booking.service_date)}</div>
                                <div className="text-xs text-gray-900">₹{booking.total_amount}</div>
                              </div>
                              <div className="flex gap-2 mt-2 sm:mt-0">
                                <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(booking.booking_status)} capitalize`}>
                                  {booking.booking_status}
                                </span>
                                <button
                                  className="bg-teal-500 hover:bg-teal-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                  onClick={() => handleViewBooking(booking)}
                                >
                                  View
                                </button>
                              </div>
                            </div>
                          ))}
                      </div>
                    )}
                  </>
                )}
              </div>
            )}

            {activeTab === 'employees' && (
              <div className="bg-white rounded-lg shadow-sm overflow-hidden">
                <div className="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
                  <h3 className="text-base font-semibold text-gray-900">Employees</h3>
                  <button className="btn btn-primary text-sm">
                    Add Employee
                  </button>
                </div>
                {employeesLoading ? (
                  <div className="flex justify-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Employee
                          </th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Contact
                          </th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Service Type
                          </th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Status
                          </th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-gray-200">
                        {employees.map((employee: any) => (
                          <tr key={employee.id}>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <div className="text-sm font-medium text-gray-900">{employee.name}</div>
                              <div className="text-sm text-gray-500">{employee.email}</div>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              {employee.mobile}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              {employee.serviceType}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <span className="px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                                Active
                              </span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}

            {activeTab === 'queries' && (
              <div className="bg-white rounded-lg shadow-sm overflow-hidden">
                {/* View Toggle, Search, and Filter Controls */}
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 px-6 py-4 border-b border-gray-100 bg-gray-50 mb-2">
                  {/* Left: Search Bar */}
                  <div className="relative w-full sm:w-[32rem] mb-2 sm:mb-0">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
                      <FiSearch className="w-5 h-5" />
                    </span>
                    <input
                      type="text"
                      className="w-full pl-10 pr-3 py-2 border border-gray-200 rounded-lg shadow-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 text-sm placeholder-gray-400"
                      placeholder="Search queries..."
                      value={querySearch}
                      onChange={e => setQuerySearch(e.target.value)}
                    />
                  </div>
                  {/* Right: Filter and View Toggle */}
                  <div className="flex items-center gap-3 w-full sm:w-auto justify-end">
                    <div className="flex items-center gap-2">
                      <label htmlFor="queryStatus" className="text-sm text-gray-500 font-medium hidden sm:block">Status:</label>
                      <select
                        id="queryStatus"
                        className="w-full sm:w-44 px-3 py-2 border border-gray-200 rounded-lg shadow-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 text-sm bg-white"
                        value={queryStatus}
                        onChange={e => setQueryStatus(e.target.value)}
                      >
                        <option value="all">All Statuses</option>
                        <option value="pending">Pending</option>
                        <option value="responded">Responded</option>
                      </select>
                    </div>
                    <div className="flex gap-2">
                      <button
                        className={`p-2 rounded-lg border ${queryView === 'table' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="Table View"
                        onClick={() => setQueryView('table')}
                      >
                        <FiTable className="w-5 h-5" />
                      </button>
                      <button
                        className={`p-2 rounded-lg border ${queryView === 'card' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="Card View"
                        onClick={() => setQueryView('card')}
                      >
                        <FiGrid className="w-5 h-5" />
                      </button>
                      <button
                        className={`p-2 rounded-lg border ${queryView === 'list' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="List View"
                        onClick={() => setQueryView('list')}
                      >
                        <FiList className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </div>
                {queriesLoading ? (
                  <div className="flex justify-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
                  </div>
                ) : (
                  <>
                    {/* Table View */}
                    {queryView === 'table' && (
                      <div className="overflow-x-auto">
                        <table className="min-w-full divide-y divide-gray-200">
                          <thead className="bg-gray-50">
                            <tr>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Customer</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Phone</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Subject</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                            </tr>
                          </thead>
                          <tbody className="bg-white divide-y divide-gray-200">
                            {queries
                              .filter((query: any) => {
                                if (queryStatus !== 'all' && query.status !== queryStatus) return false;
                                const search = querySearch.toLowerCase();
                                return (
                                  query.customer_name?.toLowerCase().includes(search) ||
                                  query.email?.toLowerCase().includes(search) ||
                                  query.subject?.toLowerCase().includes(search) ||
                                  query.message?.toLowerCase().includes(search)
                                );
                              })
                              .map((query: any) => (
                                <tr key={query.query_id}>
                                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{query.customer_name}</td>
                                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{query.email}</td>
                                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{query.phone}</td>
                                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{query.subject}</td>
                                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{formatDate(query.created_at)}</td>
                                  <td className="px-6 py-4 whitespace-nowrap">
                                    <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(query.status)} capitalize`}>
                                      {query.status}
                                    </span>
                                  </td>
                                  <td className="px-6 py-4 whitespace-nowrap flex gap-2">
                                    <button
                                      className="bg-teal-500 hover:bg-teal-600 text-white px-4 py-2 rounded font-semibold text-xs transition"
                                      onClick={() => handleViewQuery(query)}
                                    >
                                      View Details
                                    </button>
                                    {query.status === 'pending' && (
                                      <button
                                        className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded font-semibold text-xs transition"
                                        onClick={() => handleReplyQuery(query)}
                                      >
                                        Reply
                                      </button>
                                    )}
                                  </td>
                                </tr>
                              ))}
                          </tbody>
                        </table>
                      </div>
                    )}
                    {/* Card View */}
                    {queryView === 'card' && (
                      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 p-4">
                        {queries
                          .filter((query: any) => {
                            if (queryStatus !== 'all' && query.status !== queryStatus) return false;
                            const search = querySearch.toLowerCase();
                            return (
                              query.customer_name?.toLowerCase().includes(search) ||
                              query.email?.toLowerCase().includes(search) ||
                              query.subject?.toLowerCase().includes(search) ||
                              query.message?.toLowerCase().includes(search)
                            );
                          })
                          .map((query: any) => (
                            <div key={query.query_id} className="bg-white rounded-xl shadow p-5 flex flex-col gap-2 border border-gray-100">
                              <div className="flex items-center justify-between mb-2">
                                <span className="font-semibold text-gray-900 text-base">{query.customer_name}</span>
                                <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(query.status)} capitalize`}>
                                  {query.status}
                                </span>
                              </div>
                              <div className="text-xs text-gray-500 mb-1">{query.email} &bull; {query.phone}</div>
                              <div className="font-medium text-gray-700">{query.subject}</div>
                              <div className="text-gray-500 text-sm line-clamp-2">{query.message}</div>
                              <div className="text-xs text-gray-400 mt-1">{formatDate(query.created_at)}</div>
                              <div className="flex gap-2 mt-3">
                                <button
                                  className="bg-teal-500 hover:bg-teal-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                  onClick={() => handleViewQuery(query)}
                                >
                                  View Details
                                </button>
                                {query.status === 'pending' && (
                                  <button
                                    className="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                    onClick={() => handleReplyQuery(query)}
                                  >
                                    Reply
                                  </button>
                                )}
                              </div>
                            </div>
                          ))}
                      </div>
                    )}
                    {/* List View */}
                    {queryView === 'list' && (
                      <div className="divide-y divide-gray-100 bg-white rounded-xl shadow p-2">
                        {queries
                          .filter((query: any) => {
                            if (queryStatus !== 'all' && query.status !== queryStatus) return false;
                            const search = querySearch.toLowerCase();
                            return (
                              query.customer_name?.toLowerCase().includes(search) ||
                              query.email?.toLowerCase().includes(search) ||
                              query.subject?.toLowerCase().includes(search) ||
                              query.message?.toLowerCase().includes(search)
                            );
                          })
                          .map((query: any) => (
                            <div key={query.query_id} className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 py-3 px-2">
                              <div className="flex-1 min-w-0">
                                <div className="font-semibold text-gray-900 text-sm truncate">{query.customer_name}</div>
                                <div className="text-xs text-gray-500 truncate">{query.email} &bull; {query.phone}</div>
                                <div className="text-xs text-gray-700 truncate">{query.subject}</div>
                                <div className="text-xs text-gray-400">{formatDate(query.created_at)}</div>
                              </div>
                              <div className="flex gap-2 mt-2 sm:mt-0">
                                <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(query.status)} capitalize`}>
                                  {query.status}
                                </span>
                                <button
                                  className="bg-teal-500 hover:bg-teal-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                  onClick={() => handleViewQuery(query)}
                                >
                                  View
                                </button>
                                {query.status === 'pending' && (
                                  <button
                                    className="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                    onClick={() => handleReplyQuery(query)}
                                  >
                                    Reply
                                  </button>
                                )}
                              </div>
                            </div>
                          ))}
                      </div>
                    )}
                  </>
                )}
              </div>
            )}

            {activeTab === 'services' && (
              <div className="bg-white rounded-lg shadow-sm overflow-hidden">
                <div className="flex justify-between items-center px-6 py-4 border-b border-gray-200">
                  <div>
                    <h3 className="text-base font-semibold text-gray-900">Services</h3>
                    <p className="text-sm text-gray-500">
                      {services.length} services • {services.filter((service: any) => {
                        try {
                          const parsed = typeof service.locations === 'string' ? JSON.parse(service.locations) : service.locations;
                          return parsed && (Array.isArray(parsed) ? parsed.length > 0 : true);
                        } catch {
                          return false;
                        }
                      }).length} with locations • {services.filter((service: any) => service.image_path).length} with images
                    </p>
                  </div>
                  <button className="btn btn-primary text-sm" onClick={() => setActiveServiceModal('add')}>Add Service</button>
                </div>
                {servicesLoading ? (
                  <div className="flex justify-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Service</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created in (Date)</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-gray-200">
                        {services.map((service: any) => (
                          <tr key={service.service_id}>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              <div className="font-medium">{service.service_name}</div>
                              <div className="text-xs text-gray-500">{service.description}</div>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              <div className="text-xs text-gray-500">{service.created_at ? new Date(service.created_at).toLocaleDateString() : 'N/A'}</div>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              <span className="inline-block px-2 py-1 text-xs font-semibold rounded bg-green-100 text-green-800">Active</span>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap flex gap-2">
                              <button className="bg-teal-500 hover:bg-teal-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition" onClick={() => { setEditingService(service); setActiveServiceModal('edit'); }}>View</button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
                            {/* Add/Edit Modal */}
            {activeServiceModal === 'add' && (
              <Modal onClose={() => setActiveServiceModal(null)}>
                <ServiceModal onClose={() => setActiveServiceModal(null)} onSave={handleAddService} />
              </Modal>
            )}
            {activeServiceModal === 'edit' && (
              <Modal onClose={() => { setActiveServiceModal(null); setEditingService(null); }}>
                <ServiceModal onClose={() => { setActiveServiceModal(null); setEditingService(null); }} onSave={handleEditService} initialData={editingService} />
              </Modal>
            )}
                {/* Delete Confirmation */}
                {serviceToDelete && (
                  <Modal onClose={() => setServiceToDelete(null)}>
                    <h2 className="text-lg font-semibold mb-4">Delete Service</h2>
                    <p>Are you sure you want to delete the service:</p>
                    <div className="bg-gray-50 p-3 rounded mt-2">
                      <p><b>Service Name:</b> {serviceToDelete.service_name}</p>
                      <p><b>Service ID:</b> {serviceToDelete.service_id}</p>
                      <p><b>Description:</b> {serviceToDelete.description}</p>
                    </div>
                    <div className="flex justify-end gap-2 mt-4">
                      <button className="btn btn-secondary" onClick={() => setServiceToDelete(null)}>Cancel</button>
                      <button className="btn btn-danger" onClick={handleDeleteService}>Delete</button>
                    </div>
                  </Modal>
                )}
              </div>
            )}

            {/* View Query Modal */}
            {viewedQuery && (
              <Modal onClose={() => setViewedQuery(null)}>
                <h2 className="text-lg font-semibold mb-2">Query Details</h2>
                <div className="mb-4">
                  <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(viewedQuery.status)} capitalize`}>
                    {viewedQuery.status}
                  </span>
                </div>
                <div className="mb-2"><b>Customer Name:</b> {viewedQuery.customer_name}</div>
                <div className="mb-2"><b>First Name:</b> {viewedQuery.first_name}</div>
                <div className="mb-2"><b>Last Name:</b> {viewedQuery.last_name}</div>
                <div className="mb-2"><b>Email:</b> {viewedQuery.email}</div>
                <div className="mb-2"><b>Phone:</b> {viewedQuery.phone}</div>
                <div className="mb-2"><b>Mobile Number:</b> {viewedQuery.mobile_number}</div>
                <div className="mb-2"><b>Subject:</b> {viewedQuery.subject}</div>
                <div className="mb-2"><b>Message:</b> {viewedQuery.message}</div>
                {viewedQuery.admin_response && (
                  <div className="mt-4 p-2 bg-green-50 rounded">
                    <b>Admin Response:</b> {viewedQuery.admin_response}
                  </div>
                )}
                <div className="mt-4 flex justify-end gap-2">
                  <button className="btn btn-secondary" onClick={() => setViewedQuery(null)}>Close</button>
                  {viewedQuery.status === 'pending' && (
                    <button
                      className="btn btn-primary"
                      onClick={() => {
                        setViewedQuery(null);
                        setReplyingQuery(viewedQuery);
                        setReplyText('');
                      }}
                    >
                      Reply
                    </button>
                  )}
                </div>
              </Modal>
            )}

            {/* Reply Query Modal */}
            {replyingQuery && (
              <Modal onClose={() => setReplyingQuery(null)}>
                <h2 className="text-lg font-semibold mb-2">Reply to Query</h2>
                <div className="mb-2"><b>Customer:</b> {replyingQuery.customer_name}</div>
                <div className="mb-2"><b>Email:</b> {replyingQuery.email}</div>
                <div className="mb-2"><b>Phone:</b> {replyingQuery.phone}</div>
                <div className="mb-2"><b>Subject:</b> {replyingQuery.subject}</div>
                <div className="mb-2"><b>Date:</b> {formatDate(replyingQuery.created_at)}</div>
                <div className="mb-2"><b>Message:</b> {replyingQuery.message}</div>
                <textarea
                  className="w-full border rounded p-2 mt-4"
                  rows={5}
                  placeholder="Type your response here..."
                  value={replyText}
                  onChange={e => setReplyText(e.target.value)}
                  disabled={isReplying}
                />
                <div className="mt-4 flex justify-end gap-2">
                  <button className="btn btn-secondary" onClick={() => setReplyingQuery(null)} disabled={isReplying}>Cancel</button>
                  <button className="btn btn-primary" onClick={handleSubmitReply} disabled={isReplying}>
                    {isReplying ? 'Sending...' : 'Send Reply'}
                  </button>
                </div>
              </Modal>
            )}

            {/* View Booking Modal */}
            {viewedBooking && (
              <Modal onClose={() => setViewedBooking(null)}>
                <h2 className="text-lg font-semibold mb-2">Booking Details</h2>
                <div className="mb-2"><b>Service:</b> {viewedBooking.service_name}</div>
                <div className="mb-2"><b>Booking ID:</b> {viewedBooking.booking_id}</div>
                <div className="mb-2"><b>Date:</b> {formatDate(viewedBooking.service_date)}</div>
                <div className="mb-2"><b>Time Slot:</b> {viewedBooking.time_slot}</div>
                <div className="mb-2"><b>Address:</b> {viewedBooking.service_address}</div>
                <div className="mb-2"><b>Customer:</b> {viewedBooking.customer_name || viewedBooking.user_name}</div>
                <div className="mb-2"><b>Phone:</b> {viewedBooking.phone_number || viewedBooking.mobile_number}</div>
                <div className="mb-2"><b>Status:</b> <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(viewedBooking.booking_status)}`}>{viewedBooking.booking_status}</span></div>
                <div className="mb-2"><b>Total Amount:</b> ₹{viewedBooking.total_amount}</div>
                <div className="mb-2"><b>Technician:</b> {viewedBooking.assigned_technician_name
                  ? `${viewedBooking.assigned_technician_name}${viewedBooking.technician_phone ? ` (${viewedBooking.technician_phone})` : ''}`
                  : 'Not assigned'}
                </div>
                {viewedBooking.booking_status === 'pending' && (
                  <>
                    <div className="mt-2 mb-1 font-medium">Assign Technician</div>
                    <select
                      className="w-full border border-gray-300 rounded px-3 py-2 mb-3 mt-1"
                      value={selectedTechnician}
                      onChange={e => setSelectedTechnician(e.target.value)}
                      disabled={isAssigning}
                    >
                      <option value="">Select Technician</option>
                      {employees.map((emp: any) => (
                        <option key={emp.id} value={emp.id}>
                          {emp.name} ({emp.mobile})
                        </option>
                      ))}
                    </select>
                    <button
                      className="bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded font-semibold"
                      onClick={handleAssignTechnician}
                      disabled={!selectedTechnician || isAssigning}
                    >
                      {isAssigning ? 'Assigning...' : 'Assign Technician'}
                    </button>
                  </>
                )}
                <div className="mt-4 flex justify-end gap-2">
                  <button className="btn btn-secondary" onClick={() => setViewedBooking(null)}>Close</button>
                </div>
              </Modal>
            )}
        </motion.div>
      </main>
    </div>
  );
};

export default AdminDashboard; 
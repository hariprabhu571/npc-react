import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { 
  FiShield, 
  FiArrowLeft, 
  FiPlus, 
  FiEdit, 
  FiTrash2, 
  FiCalendar,
  FiPercent,
  FiTag,
  FiImage,
  FiCheckCircle,
  FiXCircle,
  FiClock,
  FiSearch,
  FiFilter
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { Offer } from '../types';
import { apiService } from '../services/api';
import { API_ENDPOINTS } from '../config/api';
import { useQuery, useMutation, useQueryClient } from 'react-query';
import toast from 'react-hot-toast';

// Modal for adding/editing offers
const OfferModal: React.FC<{
  onClose: () => void;
  onSave: (offer: any) => void;
  initialData?: Offer;
  isEdit?: boolean;
}> = ({ onClose, onSave, initialData, isEdit = false }) => {
  const [formData, setFormData] = useState({
    offer_name: initialData?.offer_name || '',
    coupon_number: initialData?.coupon_number || '',
    offer_starts_on: initialData?.offer_starts_on || '',
    expires_on: initialData?.expires_on || '',
    offer_percentage: initialData?.offer_percentage || 0,
    offer_banner: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        const base64 = e.target?.result as string;
        setFormData(prev => ({
          ...prev,
          offer_banner: base64.split(',')[1] // Remove data:image/jpeg;base64, prefix
        }));
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.offer_name.trim() || !formData.coupon_number.trim() || 
        !formData.offer_starts_on || !formData.expires_on || 
        formData.offer_percentage <= 0) {
      toast.error('Please fill in all required fields');
      return;
    }

    if (new Date(formData.expires_on) <= new Date(formData.offer_starts_on)) {
      toast.error('Expiry date must be after start date');
      return;
    }

    setIsSubmitting(true);
    try {
      await onSave(formData);
      onClose();
    } catch (error) {
      console.error('Error saving offer:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.9 }}
        className="bg-white rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto"
      >
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold text-gray-900">
              {isEdit ? 'Edit Offer' : 'Add New Offer'}
            </h3>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 transition-colors"
            >
              <FiXCircle className="w-5 h-5" />
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Offer Name *
              </label>
              <input
                type="text"
                name="offer_name"
                value={formData.offer_name}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent"
                placeholder="Enter offer name"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Coupon Number *
              </label>
              <input
                type="text"
                name="coupon_number"
                value={formData.coupon_number}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent"
                placeholder="Enter coupon number"
                required
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Start Date *
                </label>
                <input
                  type="date"
                  name="offer_starts_on"
                  value={formData.offer_starts_on}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Expiry Date *
                </label>
                <input
                  type="date"
                  name="expires_on"
                  value={formData.expires_on}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Discount Percentage *
              </label>
              <input
                type="number"
                name="offer_percentage"
                value={formData.offer_percentage}
                onChange={handleInputChange}
                min="1"
                max="100"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent"
                placeholder="Enter discount percentage"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Offer Banner
              </label>
              <input
                type="file"
                accept="image/*"
                onChange={handleFileChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent"
              />
              <p className="text-xs text-gray-500 mt-1">
                Upload an image for the offer banner (optional)
              </p>
            </div>

            <div className="flex space-x-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="flex-1 px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting}
                className="flex-1 px-4 py-2 bg-teal-600 text-white rounded-md hover:bg-teal-700 transition-colors disabled:opacity-50"
              >
                {isSubmitting ? 'Saving...' : (isEdit ? 'Update Offer' : 'Add Offer')}
              </button>
            </div>
          </form>
        </div>
      </motion.div>
    </div>
  );
};

const OffersManagement: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'expired'>('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingOffer, setEditingOffer] = useState<Offer | null>(null);

  // Fetch offers
  const { data: offersData, isLoading, refetch } = useQuery(
    'offers',
    () => apiService.get<Offer[]>(API_ENDPOINTS.FETCH_OFFERS),
    {
      retry: 1,
      onError: (error) => {
        toast.error('Failed to load offers');
      }
    }
  );

  const offers = (offersData as any)?.offers || [];

  // Filter offers based on search and status
  const filteredOffers = offers.filter((offer: Offer) => {
    const matchesSearch = offer.offer_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         offer.coupon_number?.toLowerCase().includes(searchTerm.toLowerCase());
    
    const currentDate = new Date();
    const expiryDate = new Date(offer.expires_on);
    const isActive = expiryDate >= currentDate;
    
    const matchesStatus = statusFilter === 'all' || 
                         (statusFilter === 'active' && isActive) ||
                         (statusFilter === 'expired' && !isActive);
    
    return matchesSearch && matchesStatus;
  });

  // Add offer mutation
  const addOfferMutation = useMutation(
    (offerData: any) => apiService.post(API_ENDPOINTS.ADD_OFFER, offerData),
    {
      onSuccess: () => {
        toast.success('Offer added successfully');
        queryClient.invalidateQueries('offers');
        setShowAddModal(false);
      },
      onError: (error) => {
        toast.error('Failed to add offer');
      }
    }
  );

  // Delete offer mutation
  const deleteOfferMutation = useMutation(
    (offerId: string) => apiService.delete(`${API_ENDPOINTS.DELETE_OFFER}?offer_id=${offerId}`),
    {
      onSuccess: () => {
        toast.success('Offer deleted successfully');
        queryClient.invalidateQueries('offers');
      },
      onError: (error) => {
        toast.error('Failed to delete offer');
      }
    }
  );

  const handleAddOffer = async (offerData: any) => {
    await addOfferMutation.mutateAsync(offerData);
  };

  const handleDeleteOffer = async (offerId: string) => {
    if (window.confirm('Are you sure you want to delete this offer?')) {
      await deleteOfferMutation.mutateAsync(offerId);
    }
  };

  const getStatusIcon = (offer: Offer) => {
    const currentDate = new Date();
    const expiryDate = new Date(offer.expires_on);
    const isActive = expiryDate >= currentDate;
    
    return isActive ? (
      <FiCheckCircle className="w-5 h-5 text-green-500" />
    ) : (
      <FiXCircle className="w-5 h-5 text-red-500" />
    );
  };

  const getStatusColor = (offer: Offer) => {
    const currentDate = new Date();
    const expiryDate = new Date(offer.expires_on);
    const isActive = expiryDate >= currentDate;
    
    return isActive ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800';
  };

  const getStatusText = (offer: Offer) => {
    const currentDate = new Date();
    const expiryDate = new Date(offer.expires_on);
    const isActive = expiryDate >= currentDate;
    
    return isActive ? 'Active' : 'Expired';
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
    { value: 'all', label: 'All Offers', count: offers.length },
    { value: 'active', label: 'Active', count: offers.filter((o: Offer) => new Date(o.expires_on) >= new Date()).length },
    { value: 'expired', label: 'Expired', count: offers.filter((o: Offer) => new Date(o.expires_on) < new Date()).length },
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
              <p className="text-sm text-gray-500">{user?.name || 'Admin'}</p>
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
            <div className="flex justify-between items-center">
              <div>
                <h2 className="text-3xl font-bold text-gray-900 mb-2">Offers Management</h2>
                <p className="text-gray-600">Manage promotional offers and discounts</p>
              </div>
              <button
                onClick={() => setShowAddModal(true)}
                className="btn btn-primary flex items-center space-x-2"
              >
                <FiPlus className="w-4 h-4" />
                <span>Add Offer</span>
              </button>
            </div>
          </div>

          {/* Search and Filter */}
          <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="flex flex-col sm:flex-row gap-4">
              <div className="flex-1">
                <div className="relative">
                  <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <input
                    type="text"
                    placeholder="Search offers by name or coupon number..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent"
                  />
                </div>
              </div>
              <div className="flex items-center space-x-2">
                <FiFilter className="w-4 h-4 text-gray-400" />
                <select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value as any)}
                  className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent"
                >
                  {filterOptions.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label} ({option.count})
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          {/* Filter Tabs */}
          <div className="mb-6">
            <div className="border-b border-gray-200">
              <nav className="-mb-px flex space-x-8 overflow-x-auto">
                {filterOptions.map((option) => (
                  <button
                    key={option.value}
                    onClick={() => setStatusFilter(option.value as any)}
                    className={`py-2 px-1 border-b-2 font-medium text-sm whitespace-nowrap transition-colors ${
                      statusFilter === option.value
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

          {/* Offers List */}
          {isLoading ? (
            <div className="flex justify-center items-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
            </div>
          ) : filteredOffers.length === 0 ? (
            <div className="text-center py-12">
              <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <FiTag className="w-12 h-12 text-gray-400" />
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No offers found</h3>
              <p className="text-gray-600 mb-6">
                {searchTerm || statusFilter !== 'all' 
                  ? "No offers match your current filters."
                  : "You haven't created any offers yet."
                }
              </p>
              {!searchTerm && statusFilter === 'all' && (
                <button
                  onClick={() => setShowAddModal(true)}
                  className="btn btn-primary"
                >
                  Create Your First Offer
                </button>
              )}
            </div>
          ) : (
            <div className="space-y-4">
              {filteredOffers.map((offer: Offer, index: number) => (
                <motion.div
                  key={offer.offer_id}
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
                            {offer.offer_name}
                          </h3>
                          <div className="flex items-center space-x-2">
                            {getStatusIcon(offer)}
                            <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(offer)}`}>
                              {getStatusText(offer)}
                            </span>
                          </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
                          <div className="flex items-center text-sm text-gray-600">
                            <FiTag className="w-4 h-4 mr-2" />
                            {offer.coupon_number}
                          </div>
                          <div className="flex items-center text-sm text-gray-600">
                            <FiPercent className="w-4 h-4 mr-2" />
                            {offer.offer_percentage}% off
                          </div>
                          <div className="flex items-center text-sm text-gray-600">
                            <FiCalendar className="w-4 h-4 mr-2" />
                            {formatDate(offer.offer_starts_on)}
                          </div>
                          <div className="flex items-center text-sm text-gray-600">
                            <FiClock className="w-4 h-4 mr-2" />
                            {formatDate(offer.expires_on)}
                          </div>
                        </div>

                        {offer.offer_banner_location && (
                          <div className="mb-4">
                            <div className="flex items-center text-sm text-gray-600">
                              <FiImage className="w-4 h-4 mr-2" />
                              <span>Banner: {offer.offer_banner_location.split('/').pop()}</span>
                            </div>
                          </div>
                        )}

                        <div className="flex items-center justify-between text-sm text-gray-500">
                          <span>Offer ID: {offer.offer_id}</span>
                        </div>
                      </div>
                    </div>

                    {/* Action Buttons */}
                    <div className="mt-4 pt-4 border-t border-gray-200 flex space-x-3">
                      <button
                        onClick={() => setEditingOffer(offer)}
                        className="btn btn-outline text-sm flex items-center space-x-1"
                      >
                        <FiEdit className="w-4 h-4" />
                        <span>Edit</span>
                      </button>
                      <button
                        onClick={() => handleDeleteOffer(offer.offer_id)}
                        className="btn btn-secondary text-sm flex items-center space-x-1"
                      >
                        <FiTrash2 className="w-4 h-4" />
                        <span>Delete</span>
                      </button>
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </motion.div>
      </div>

      {/* Add/Edit Modal */}
      {showAddModal && (
        <OfferModal
          onClose={() => setShowAddModal(false)}
          onSave={handleAddOffer}
          isEdit={false}
        />
      )}

      {editingOffer && (
        <OfferModal
          onClose={() => setEditingOffer(null)}
          onSave={handleAddOffer}
          initialData={editingOffer}
          isEdit={true}
        />
      )}
    </div>
  );
};

export default OffersManagement; 
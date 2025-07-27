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
  FiTable,
  FiTag,
  FiImage
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
  onSave: (service: any) => void;
  initialData?: any;
}> = ({ onClose, onSave, initialData }) => {
  // Helper to get full image URL
  function getImageUrl(imagePath?: string | null): string | undefined {
    if (!imagePath) return undefined;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('data:')) return imagePath;
    return `${API_BASE_URL.replace(/\/$/, '')}/${imagePath.replace(/^\/+/, '')}`;
  }
  // Service meta fields
  const [serviceName, setServiceName] = useState(initialData?.service_name || '');
  const [description, setDescription] = useState(initialData?.description || '');
  const [locations, setLocations] = useState(initialData?.locations || []);
  
  // Service types and pricing
  const [serviceTypes, setServiceTypes] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [expandedTypes, setExpandedTypes] = useState<Set<string>>(new Set());

  const [showEditDetails, setShowEditDetails] = useState(false);
  const [showAddService, setShowAddService] = useState(false);

  // For editing details
  const [editName, setEditName] = useState(serviceName);
  const [editDescription, setEditDescription] = useState(description);
  const [editLocations, setEditLocations] = useState(locations);
  const [editImage, setEditImage] = useState<File | null>(null);
  const [editImagePreview, setEditImagePreview] = useState<string | null>(null);

  // For adding new service
  const [addName, setAddName] = useState('');
  const [addDescription, setAddDescription] = useState('');
  const [addLocations, setAddLocations] = useState('');
  const [addImage, setAddImage] = useState<File | null>(null);
  const [addImagePreview, setAddImagePreview] = useState<string | null>(null);

  // For employee details and reset password
  const [showEmployeeDetails, setShowEmployeeDetails] = useState(false);
  const [selectedEmployee, setSelectedEmployee] = useState<any>(null);
  const [showResetPasswordConfirm, setShowResetPasswordConfirm] = useState(false);
  const [resetPasswordLoading, setResetPasswordLoading] = useState(false);

  useEffect(() => {
    setServiceName(initialData?.service_name || '');
    setDescription(initialData?.description || '');
    
    // Handle locations - could be JSON string or array
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

      // Load service types if editing
  if (initialData) {
    loadServiceTypes();
  }
  }, [initialData]);

  const loadServiceTypes = async () => {
    if (!initialData?.service_name) return;
    
    setIsLoading(true);
    try {
      const res = await apiService.get(`${API_ENDPOINTS.GET_SERVICE_DETAILS}?service_name=${encodeURIComponent(initialData.service_name)}`);
      if (res.status === 'success' && res.data && Array.isArray(res.data)) {
        // Mark existing service types and fields as not new
        const processedData = res.data.map((type: any) => ({
          ...type,
          isNew: false,
          pricing_fields: type.pricing_fields.map((field: any) => ({
            ...field,
            isNew: false,
            isModified: false
          }))
        }));
        setServiceTypes(processedData);
        // Expand all types by default
        const typeNames = processedData.map((type: any) => type.service_type_name).filter(Boolean);
        setExpandedTypes(new Set(typeNames));
      } else {
        setServiceTypes([]);
      }
    } catch (error) {
      console.error('Failed to load service types:', error);
      setServiceTypes([]);
    } finally {
      setIsLoading(false);
    }
  };

  const addServiceType = () => {
    const newType = {
      service_type_name: '',
      pricing_fields: [{ room_size: '', price: '', isNew: true }],
      isNew: true
    };
    setServiceTypes([...serviceTypes, newType]);
    setExpandedTypes(prev => new Set(Array.from(prev).concat('new')));
  };

  const updateServiceType = (index: number, field: string, value: any) => {
    const updated = [...serviceTypes];
    updated[index] = { ...updated[index], [field]: value };
    setServiceTypes(updated);
  };

  const addPricingField = (typeIndex: number) => {
    const updated = [...serviceTypes];
    updated[typeIndex].pricing_fields.push({ room_size: '', price: '', isNew: true });
    setServiceTypes(updated);
  };

  const updatePricingField = (typeIndex: number, fieldIndex: number, field: string, value: string) => {
    const updated = [...serviceTypes];
    const currentField = updated[typeIndex].pricing_fields[fieldIndex];
    updated[typeIndex].pricing_fields[fieldIndex] = {
      ...currentField,
      [field]: value,
      isModified: !currentField.isNew // Mark as modified if it's not a new field
    };
    setServiceTypes(updated);
  };

  const removePricingField = (typeIndex: number, fieldIndex: number) => {
    const updated = [...serviceTypes];
    if (updated[typeIndex].pricing_fields.length > 1) {
      updated[typeIndex].pricing_fields.splice(fieldIndex, 1);
      setServiceTypes(updated);
    }
  };

  const removeServiceType = async (typeIndex: number) => {
    const serviceType = serviceTypes[typeIndex];
    
    // If it's an existing service type (not new), delete it from backend
    if (!serviceType.isNew && serviceType.service_type_id) {
      try {
        await apiService.post(API_ENDPOINTS.DELETE_SERVICE_TYPE, {
          service_type_id: serviceType.service_type_id
        });
      } catch (error) {
        console.error('Failed to delete service type:', error);
        // Still remove from UI even if backend delete fails
      }
    }
    
    // Remove from UI
    const updated = serviceTypes.filter((_, index) => index !== typeIndex);
    setServiceTypes(updated);
  };

  const toggleTypeExpansion = (typeName: string) => {
    const updated = new Set(expandedTypes);
    if (updated.has(typeName)) {
      updated.delete(typeName);
    } else {
      updated.add(typeName);
    }
    setExpandedTypes(updated);
  };

  // Calculate summary statistics
  const totalFields = serviceTypes.reduce((sum: number, type: any) => sum + type.pricing_fields.length, 0);
  const avgPrice = totalFields > 0 
    ? serviceTypes.reduce((sum: number, type: any) => 
        sum + type.pricing_fields.reduce((typeSum: number, field: any) => 
          typeSum + (parseFloat(field.price) || 0), 0), 0) / totalFields
    : 0;

  // Save handler
  const handleSave = async () => {
    try {
      // Save the service details with service types using the mobile app's approach
      await onSave({
        service_name: serviceName,
        description,
        locations: Array.isArray(locations) ? JSON.stringify(locations) : locations,
        serviceTypes: serviceTypes // Pass the service types data
      });
      
    } catch (error) {
      console.error('Save error:', error);
      alert('Failed to save service. Please try again.');
    }
  };

  return (
    <div className="max-w-7xl mx-auto bg-white rounded-lg shadow-xl">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 bg-teal-100 rounded-lg flex items-center justify-center">
              <svg className="w-5 h-5 text-teal-600" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z" clipRule="evenodd" />
              </svg>
            </div>
            <div>
              <h2 className="text-xl font-semibold text-gray-900">
                Edit Service: {serviceName}
              </h2>
              <p className="text-sm text-gray-500">Manage service types and pricing structure</p>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <button
              className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center transition-colors"
              onClick={() => {
                setEditName(serviceName);
                setEditDescription(description);
                setEditLocations(locations);
                // Initialize image preview if there's an existing image
                if (initialData?.image_path) {
                  const imageUrl = getImageUrl(initialData.image_path);
                  setEditImagePreview(imageUrl || null);
                } else {
                  setEditImagePreview(null);
                }
                setEditImage(null);
                setShowEditDetails(true);
              }}
            >
              <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
              Edit Details
            </button>
            <button className="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center transition-colors">
              <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
              Delete
            </button>
          </div>
        </div>

                 {/* Edit Details Modal */}
         {showEditDetails && (
           <Modal onClose={() => setShowEditDetails(false)} size="small">
             <div className="p-6 w-full">
              <h3 className="text-lg font-semibold mb-4">Edit Service Details</h3>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-1">Service Name</label>
                <input
                  type="text"
                  className="w-full border border-gray-300 rounded px-3 py-2"
                  value={editName}
                  onChange={e => setEditName(e.target.value)}
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  className="w-full border border-gray-300 rounded px-3 py-2"
                  value={editDescription}
                  onChange={e => setEditDescription(e.target.value)}
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-1">Locations (comma separated)</label>
                <input
                  type="text"
                  className="w-full border border-gray-300 rounded px-3 py-2"
                  value={Array.isArray(editLocations) ? editLocations.join(', ') : editLocations}
                  onChange={e => setEditLocations(e.target.value.split(',').map(s => s.trim()))}
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
                  onClick={() => setShowEditDetails(false)}
                >
                  Cancel
                </button>
                <button
                  className="px-4 py-2 rounded bg-blue-500 text-white"
                  onClick={async () => {
                    // Handle image upload if a new image is selected
                    let imagePath = null;
                    if (editImage) {
                      try {
                        const formData = new FormData();
                        formData.append('service_image', editImage); // Use 'service_image' field name like the app
                        formData.append('service_id', initialData?.service_id || '');
                        formData.append('service_name', editName);
                        formData.append('description', editDescription);
                        formData.append('locations', Array.isArray(editLocations) ? JSON.stringify(editLocations) : editLocations);
                        formData.append('action', 'update_service');
                        
                        // Use the same endpoint as the app - services_manager.php
                        const response = await api.post(API_ENDPOINTS.UPDATE_SERVICE_DETAILS, formData, {
                          headers: {
                            'Content-Type': 'multipart/form-data',
                          },
                        });
                        
                        if (response.data.status === 'success') {
                          console.log('Service updated successfully with image');
                          // The image path will be returned in the response or we can construct it
                          imagePath = response.data.image_path || `/ServiceImages/${editImage.name}`;
                        } else {
                          console.error('Failed to update service:', response.data.message);
                          alert('Failed to update service. Please try again.');
                          return;
                        }
                      } catch (error) {
                        console.error('Failed to update service:', error);
                        alert('Failed to update service. Please try again.');
                        return;
                      }
                    }
                    
                    // If no image was selected, still update the service details
                    if (!editImage) {
                      try {
                        const formData = new FormData();
                        formData.append('action', 'update_service');
                        formData.append('service_id', initialData?.service_id || '');
                        formData.append('service_name', editName);
                        formData.append('description', editDescription);
                        formData.append('locations', Array.isArray(editLocations) ? JSON.stringify(editLocations) : editLocations);
                        
                        const response = await apiService.postFormData(API_ENDPOINTS.UPDATE_SERVICE_DETAILS, formData);
                        
                        if (response.status === 'success') {
                          console.log('Service details updated successfully');
                        } else {
                          console.error('Failed to update service details:', response.message);
                          alert('Failed to update service details. Please try again.');
                          return;
                        }
                      } catch (error) {
                        console.error('Failed to update service details:', error);
                        alert('Failed to update service details. Please try again.');
                        return;
                      }
                    }
                    
                    setServiceName(editName);
                    setDescription(editDescription);
                    setLocations(editLocations);
                    setShowEditDetails(false);
                    
                    // Update the service with image path if uploaded
                    if (imagePath) {
                      console.log('Service image updated:', imagePath);
                    }
                    
                    // Clear image states
                    setEditImage(null);
                    setEditImagePreview(null);
                    
                    // Show success message
                    alert('Service details updated successfully!');
                  }}
                >
                  Save
                </button>
              </div>
            </div>
          </Modal>
        )}

        {/* Add Service Modal */}
        {showAddService && (
          <Modal onClose={() => setShowAddService(false)} size="small">
            <div className="p-6 w-full">
              <h3 className="text-lg font-semibold mb-4">Add New Service</h3>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-1">Service Name</label>
                <input
                  type="text"
                  className="w-full border border-gray-300 rounded px-3 py-2"
                  value={addName}
                  onChange={e => setAddName(e.target.value)}
                  placeholder="Enter service name"
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  className="w-full border border-gray-300 rounded px-3 py-2"
                  value={addDescription}
                  onChange={e => setAddDescription(e.target.value)}
                  placeholder="Enter service description"
                  rows={3}
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-1">Locations (comma separated)</label>
                <input
                  type="text"
                  className="w-full border border-gray-300 rounded px-3 py-2"
                  value={addLocations}
                  onChange={e => setAddLocations(e.target.value)}
                  placeholder="e.g., Chennai, Coimbatore, Erode"
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
                          setAddImage(file);
                          const reader = new FileReader();
                          reader.onload = (e) => {
                            setAddImagePreview(e.target?.result as string);
                          };
                          reader.readAsDataURL(file);
                        }
                      }}
                    />
                  </div>
                  {addImagePreview && (
                    <div className="relative w-16 h-16 border border-gray-300 rounded overflow-hidden">
                      <img 
                        src={addImagePreview} 
                        alt="Preview" 
                        className="w-full h-full object-cover"
                      />
                      <button
                        type="button"
                        className="absolute -top-1 -right-1 bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center text-xs hover:bg-red-600"
                        onClick={() => {
                          setAddImagePreview(null);
                          setAddImage(null);
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
                  onClick={() => setShowAddService(false)}
                >
                  Cancel
                </button>
                <button
                  className="px-4 py-2 rounded bg-blue-500 text-white"
                  onClick={async () => {
                    if (!addName.trim()) {
                      alert('Please enter a service name');
                      return;
                    }

                    try {
                      const formData = new FormData();
                      formData.append('action', 'add_service');
                      formData.append('service_name', addName);
                      formData.append('description', addDescription);
                      formData.append('locations', addLocations ? JSON.stringify(addLocations.split(',').map(s => s.trim())) : '[]');
                      
                      if (addImage) {
                        formData.append('service_image', addImage);
                      }

                      const response = await apiService.postFormData(API_ENDPOINTS.UPDATE_SERVICE_DETAILS, formData);
                      
                      if (response.status === 'success') {
                        alert('Service added successfully!');
                        setShowAddService(false);
                        // Reset form
                        setAddName('');
                        setAddDescription('');
                        setAddLocations('');
                        setAddImage(null);
                        setAddImagePreview(null);
                        // Refresh services list
                        if (onSave) {
                          onSave({
                            service_name: addName,
                            description: addDescription,
                            locations: addLocations.split(',').map(s => s.trim()),
                            service_image: addImage
                          });
                        }
                      } else {
                        alert('Failed to add service. Please try again.');
                      }
                    } catch (error) {
                      console.error('Failed to add service:', error);
                      alert('Failed to add service. Please try again.');
                    }
                  }}
                >
                  Save
                </button>
              </div>
            </div>
          </Modal>
        )}

        <div className="flex">
          {/* Main Content */}
          <div className="flex-1 p-6">
            {/* Service Overview */}
            <div className="mb-6">
              <div className="flex items-center mb-3">
                <svg className="w-5 h-5 text-gray-400 mr-2" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                </svg>
                <h3 className="text-lg font-medium text-gray-900">Service Overview</h3>
                <span className="ml-auto bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full">
                  {serviceTypes.length} Service Types
                </span>
              </div>
              <div className="grid grid-cols-4 gap-4">
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <div className="text-sm text-gray-500">Service Name</div>
                  <div className="font-medium text-gray-900">{serviceName || 'Not set'}</div>
                </div>
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <div className="text-sm text-gray-500">Total Pricing Fields</div>
                  <div className="font-medium text-gray-900">{totalFields}</div>
                </div>
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <div className="text-sm text-gray-500">Image</div>
                  <div className="flex items-center">
                    {initialData?.image_path ? (
                      <div className="flex items-center">
                        <div className="w-8 h-8 border border-gray-300 rounded overflow-hidden mr-2">
                          <img 
                            src={getImageUrl(initialData.image_path)} 
                            alt="Service" 
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <span className="font-medium text-gray-900">Uploaded</span>
                      </div>
                    ) : (
                      <div className="flex items-center">
                        <div className="w-8 h-8 bg-gray-100 rounded flex items-center justify-center mr-2">
                          <svg className="w-4 h-4 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z" clipRule="evenodd" />
                          </svg>
                        </div>
                        <span className="font-medium text-gray-500">No image</span>
                      </div>
                    )}
                  </div>
                </div>
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <div className="text-sm text-gray-500">Status</div>
                  <div className="flex items-center">
                    <div className="w-2 h-2 bg-green-400 rounded-full mr-2"></div>
                    <span className="font-medium text-gray-900">Active</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Service Types & Pricing */}
            <div>
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center">
                  <svg className="w-5 h-5 text-gray-400 mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z" />
                  </svg>
                  <h3 className="text-lg font-medium text-gray-900">Service Types & Pricing</h3>
                </div>
                <button 
                  onClick={addServiceType}
                  className="btn btn-primary text-sm"
                >
                  <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                  Add Service Type
                </button>
              </div>

              {isLoading ? (
                <div className="flex justify-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600"></div>
                </div>
              ) : (
                <div className="space-y-4">
                  {serviceTypes.map((type, typeIndex) => (
                    <div key={typeIndex} className="bg-white border border-gray-200 rounded-lg shadow-sm">
                      {/* Service Type Header */}
                      <div 
                        className="flex items-center justify-between p-4 cursor-pointer hover:bg-gray-50 transition-colors"
                        onClick={() => toggleTypeExpansion(type.service_type_name)}
                      >
                        <div className="flex items-center space-x-3">
                          {/* Drag Handle */}
                          <div className="w-5 h-5 text-gray-400 cursor-move">
                            <svg fill="currentColor" viewBox="0 0 20 20">
                              <path d="M7 2a2 2 0 1 1 .001 4.001A2 2 0 0 1 7 2zm0 6a2 2 0 1 1 .001 4.001A2 2 0 0 1 7 8zm0 6a2 2 0 1 1 .001 4.001A2 2 0 0 1 7 14zm6-8a2 2 0 1 1-.001-4.001A2 2 0 0 1 13 6zm0 2a2 2 0 1 1 .001 4.001A2 2 0 0 1 13 8zm0 6a2 2 0 1 1 .001 4.001A2 2 0 0 1 13 14z" />
                            </svg>
                          </div>
                          
                          {/* Service Type Icon */}
                          <div className="w-6 h-6 bg-teal-100 rounded-lg flex items-center justify-center">
                            <svg className="w-4 h-4 text-teal-600" fill="currentColor" viewBox="0 0 20 20">
                              <path d="M10 2L3 7v11h14V7l-7-5zM10 4.5L15 8v9H5V8l5-3.5z"/>
                            </svg>
                          </div>
                          
                          <div className="flex-1">
                            <input 
                              type="text"
                              value={type.service_type_name}
                              onChange={(e) => updateServiceType(typeIndex, 'service_type_name', e.target.value)}
                              className="font-semibold text-gray-900 bg-transparent border-none focus:ring-0 p-0"
                              placeholder="Enter service type name"
                              onClick={(e) => e.stopPropagation()}
                            />
                            <div className="text-sm text-gray-500">
                              {type.pricing_fields.length} pricing fields
                            </div>
                          </div>
                        </div>
                        
                        <div className="flex items-center space-x-2">
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              addPricingField(typeIndex);
                            }}
                            className="text-teal-600 hover:text-teal-700"
                          >
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                            </svg>
                          </button>
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              removeServiceType(typeIndex);
                            }}
                            className="text-red-500 hover:text-red-700"
                          >
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                          </button>
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              toggleTypeExpansion(type.service_type_name);
                            }}
                            className="text-gray-400 hover:text-gray-600"
                          >
                            <svg className={`w-5 h-5 transform transition-transform ${expandedTypes.has(type.service_type_name) ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                            </svg>
                          </button>
                        </div>
                      </div>

                      {/* Pricing Structure */}
                      {expandedTypes.has(type.service_type_name) && (
                        <div className="border-t border-gray-200 bg-gray-50">
                          <div className="p-4">
                            <div className="flex items-center mb-3">
                              <svg className="w-4 h-4 text-gray-400 mr-2" fill="currentColor" viewBox="0 0 20 20">
                                <path d="M8.433 7.418c.155-.103.346-.196.567-.267v1.698a2.305 2.305 0 01-.567-.267C8.07 8.34 8 8.114 8 8c0-.114.07-.34.433-.582zM11 12.849v-1.698c.22.071.412.164.567.267.364.243.433.468.433.582 0 .114-.07.34-.433.582a2.305 2.305 0 01-.567.267z" />
                                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-13a1 1 0 10-2 0v.092a4.535 4.535 0 00-1.676.662C6.602 6.234 6 7.009 6 8c0 .99.602 1.765 1.324 2.246.48.32 1.054.545 1.676.662v1.941c-.391-.127-.68-.317-.843-.504a1 1 0 10-1.51 1.31c.562.649 1.413 1.076 2.353 1.253V15a1 1 0 102 0v-.092a4.535 4.535 0 001.676-.662C13.398 13.766 14 12.991 14 12c0-.99-.602-1.765-1.324-2.246A4.535 4.535 0 0011 9.092V7.151c.391.127.68.317.843.504a1 1 0 101.511-1.31c-.563-.649-1.413-1.076-2.354-1.253V5z" clipRule="evenodd" />
                              </svg>
                              <h4 className="font-medium text-gray-900">Pricing Structure</h4>
                            </div>
                            
                            <div className="space-y-3">
                              {type.pricing_fields.map((field: any, fieldIndex: number) => (
                                <div key={fieldIndex} className="bg-white border border-gray-200 rounded-lg p-4">
                                  <div className="flex items-center space-x-4">
                                    <div className="flex-1">
                                      <label className="block text-sm font-medium text-gray-700 mb-1">Room Size</label>
                                      <input
                                        type="text"
                                        value={field.room_size}
                                        onChange={(e) => updatePricingField(typeIndex, fieldIndex, 'room_size', e.target.value)}
                                        className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
                                        placeholder="e.g., 1 BHK"
                                      />
                                    </div>
                                    <div className="flex-1">
                                      <label className="block text-sm font-medium text-gray-700 mb-1">Price (₹)</label>
                                      <input
                                        type="number"
                                        value={field.price}
                                        onChange={(e) => updatePricingField(typeIndex, fieldIndex, 'price', e.target.value)}
                                        className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
                                        placeholder="0.00"
                                      />
                                    </div>
                                    <div className="flex items-end">
                                      <button
                                        onClick={() => removePricingField(typeIndex, fieldIndex)}
                                        className="text-red-500 hover:text-red-700 p-2 rounded-full hover:bg-red-50"
                                        disabled={type.pricing_fields.length <= 1}
                                      >
                                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                        </svg>
                                      </button>
                                    </div>
                                  </div>
                                </div>
                              ))}
                            </div>

                            <button
                              onClick={() => addPricingField(typeIndex)}
                              className="mt-4 w-full border-2 border-dashed border-gray-300 rounded-lg p-4 text-gray-500 hover:text-gray-700 hover:border-gray-400 transition-colors bg-white"
                            >
                              <div className="flex items-center justify-center">
                                <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                                </svg>
                                <span className="font-medium">Add Pricing Field</span>
                              </div>
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Actions & Summary Sidebar */}
          <div className="w-96 bg-gray-50 border-l border-gray-200 p-6">
            <div className="space-y-6">
              {/* Summary */}
              <div>
                <div className="flex items-center mb-3">
                  <svg className="w-5 h-5 text-gray-400 mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z" clipRule="evenodd" />
                  </svg>
                  <h3 className="font-medium text-gray-900">Actions & Summary</h3>
                </div>
                
                <div className="bg-white rounded-lg p-4 space-y-3">
                  <h4 className="font-semibold text-gray-900">Summary</h4>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-500">Service Types:</span>
                      <span className="font-medium">{serviceTypes.length}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Total Fields:</span>
                      <span className="font-medium">{totalFields}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Avg Price:</span>
                      <span className="font-medium">₹{avgPrice.toFixed(0)}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Quick Actions */}
              <div>
                <h4 className="font-semibold text-gray-900 mb-3">Quick Actions</h4>
                <div className="space-y-2">
                  <button 
                    onClick={addServiceType}
                    className="w-full text-left text-teal-600 hover:text-teal-700 text-sm flex items-center"
                  >
                    <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                    </svg>
                    Add Service Type
                  </button>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="space-y-3">
                <button 
                  onClick={handleSave}
                  className="w-full btn btn-primary flex items-center justify-center"
                >
                  <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
                  </svg>
                  Save Changes
                </button>
                <button 
                  onClick={onClose}
                  className="w-full text-gray-600 hover:text-gray-800 text-sm"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
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
  const [showAddService, setShowAddService] = useState(false);
  
  // Services search, filter, and view state
  const [serviceSearch, setServiceSearch] = useState('');
  const [serviceStatus, setServiceStatus] = useState('all');
  const [serviceView, setServiceView] = useState<'table' | 'card' | 'list'>('table');

  // Employee state
  const [showEmployeeDetails, setShowEmployeeDetails] = useState(false);
  const [selectedEmployee, setSelectedEmployee] = useState<any>(null);
  const [showResetPasswordConfirm, setShowResetPasswordConfirm] = useState(false);
  const [resetPasswordLoading, setResetPasswordLoading] = useState(false);
  
  // Employee search, filter, and view state
  const [employeeSearch, setEmployeeSearch] = useState('');
  const [employeeStatus, setEmployeeStatus] = useState('all');
  const [employeeView, setEmployeeView] = useState<'table' | 'card' | 'list'>('table');

  // Offers search, filter, and view state
  const [offerSearch, setOfferSearch] = useState('');
  const [offerStatus, setOfferStatus] = useState('all');
  const [offerView, setOfferView] = useState<'table' | 'card' | 'list'>('table');
  const [showAddOffer, setShowAddOffer] = useState(false);
  const [editingOffer, setEditingOffer] = useState<any>(null);
  const [selectedBannerPreview, setSelectedBannerPreview] = useState<string | null>(null);
  const [selectedBannerBase64, setSelectedBannerBase64] = useState<string>('');
  
  // Add Employee state
  const [showAddEmployee, setShowAddEmployee] = useState(false);
  const [addEmployeeLoading, setAddEmployeeLoading] = useState(false);
  const [addEmployeeForm, setAddEmployeeForm] = useState({
    employee_name: '',
    phone_number: '',
    service_type: '',
    address: '',
    email: '',
    password: ''
  });
  const [addEmployeeIdProof, setAddEmployeeIdProof] = useState<File | null>(null);
  const [addEmployeeIdProofPreview, setAddEmployeeIdProofPreview] = useState<string | null>(null);
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

  // Filter services based on search and status
  const filteredServices = services.filter((service: any) => {
    const matchesSearch = service.service_name?.toLowerCase().includes(serviceSearch.toLowerCase()) ||
                         service.description?.toLowerCase().includes(serviceSearch.toLowerCase());
    
    const matchesStatus = serviceStatus === 'all' || 
                         (serviceStatus === 'active' && service.status !== 'inactive') ||
                         (serviceStatus === 'inactive' && service.status === 'inactive');
    
    return matchesSearch && matchesStatus;
  });
  const handleAddService = async (service: any) => {
    try {
      // Create FormData for multipart/form-data request
      const formData = new FormData();
      formData.append('service_name', service.service_name);
      formData.append('description', service.description);
      formData.append('locations', JSON.stringify(service.locations || []));

      // Add image file if provided
      if (service.service_image) {
        formData.append('service_image', service.service_image);
      }

      // Send request to add_service.php using FormData
      await apiService.postFormData(API_ENDPOINTS.ADD_SERVICE, formData);
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
      // Transform the service data to match the mobile app's expected format
      const serviceTypes = service.serviceTypes?.map((type: any) => ({
        typeName: type.service_type_name,
        pricingFields: type.pricing_fields?.map((field: any) => ({
          roomSize: field.room_size,
          price: parseFloat(field.price)
        })) || []
      })) || [];

      await apiService.post(API_ENDPOINTS.UPDATE_SERVICE_TYPES, {
        service_name: service.service_name,
        service_types: serviceTypes
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
      const formData = new FormData();
      formData.append('action', 'delete_service');
      formData.append('service_id', serviceToDelete.service_id);
      
      await apiService.postFormData(API_ENDPOINTS.UPDATE_SERVICE_DETAILS, formData);
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

  // Employee functions
  const handleViewEmployee = (employee: any) => {
    setSelectedEmployee(employee);
    setShowEmployeeDetails(true);
  };

  const handleResetPassword = (employee: any) => {
    setSelectedEmployee(employee);
    setShowResetPasswordConfirm(true);
  };

  const confirmResetPassword = async () => {
    if (!selectedEmployee) return;

    setResetPasswordLoading(true);
    try {
      const response = await apiService.post(API_ENDPOINTS.RESET_PASSWORD, {
        technician_id: selectedEmployee.id,
        newpassword: '12345'
      });

      if (response.status === 'success') {
        toast.success('Password reset successfully. New password is: 12345');
        setShowResetPasswordConfirm(false);
        setSelectedEmployee(null);
      } else {
        toast.error(response.message || 'Failed to reset password');
      }
    } catch (error) {
      console.error('Error resetting password:', error);
      toast.error('Failed to reset password. Please try again.');
    } finally {
      setResetPasswordLoading(false);
    }
  };

  // Add Employee handlers
  const handleAddEmployee = () => {
    setShowAddEmployee(true);
    // Reset form
    setAddEmployeeForm({
      employee_name: '',
      phone_number: '',
      service_type: '',
      address: '',
      email: '',
      password: ''
    });
    setAddEmployeeIdProof(null);
    setAddEmployeeIdProofPreview(null);
  };

  const handleIdProofChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setAddEmployeeIdProof(file);
      const reader = new FileReader();
      reader.onload = (e) => {
        setAddEmployeeIdProofPreview(e.target?.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleAddEmployeeSubmit = async () => {
    // Validate form
    if (!addEmployeeForm.employee_name || !addEmployeeForm.phone_number || 
        !addEmployeeForm.service_type || !addEmployeeForm.address || 
        !addEmployeeForm.email || !addEmployeeForm.password || !addEmployeeIdProof) {
      toast.error('Please fill all fields and upload ID proof');
      return;
    }

    setAddEmployeeLoading(true);
    try {
      // Convert file to base64
      const reader = new FileReader();
      reader.onload = async (e) => {
        const base64 = (e.target?.result as string).split(',')[1]; // Remove data:image/...;base64, prefix
        
        const formData = {
          employee_name: addEmployeeForm.employee_name,
          phone_number: addEmployeeForm.phone_number,
          service_type: addEmployeeForm.service_type,
          address: addEmployeeForm.address,
          id_proof: base64,
          email: addEmployeeForm.email,
          password: addEmployeeForm.password
        };

        const response = await apiService.post(API_ENDPOINTS.ADD_TECHNICIAN, formData);
        if (response.status === 'success') {
          toast.success('Employee added successfully');
          setShowAddEmployee(false);
          // Refresh employees list
          if (activeTab === 'employees') {
            // Refetch employees data
            window.location.reload(); // Simple refresh for now
          }
        } else {
          toast.error(response.message || 'Failed to add employee');
        }
      };
      reader.readAsDataURL(addEmployeeIdProof);
    } catch (error: any) {
      console.error('Add employee error:', error);
      toast.error('Failed to add employee');
    } finally {
      setAddEmployeeLoading(false);
    }
  };

  // Offer-related functions
  const handleAddOffer = async (offerData: any) => {
    try {
      const response = await apiService.post(API_ENDPOINTS.ADD_OFFER, offerData);
      if (response.status === 'success') {
        const isUpdate = !!offerData.offer_id;
        toast.success(isUpdate ? 'Offer updated successfully' : 'Offer added successfully');
        setShowAddOffer(false);
        setEditingOffer(null);
        setSelectedBannerPreview(null);
        setSelectedBannerBase64('');
        // Refetch offers data
        window.location.reload();
      } else {
        toast.error(response.message || 'Failed to add offer');
      }
    } catch (error: any) {
      console.error('Add offer error:', error);
      toast.error('Failed to add offer');
    }
  };

  const handleDeleteOffer = async (offerId: string) => {
    if (window.confirm('Are you sure you want to delete this offer?')) {
      try {
        const response = await apiService.delete(`${API_ENDPOINTS.DELETE_OFFER}?offer_id=${offerId}`);
        if (response.status === 'success') {
          toast.success('Offer deleted successfully');
          // Refetch offers data
          window.location.reload();
        } else {
          toast.error(response.message || 'Failed to delete offer');
        }
      } catch (error: any) {
        console.error('Delete offer error:', error);
        toast.error('Failed to delete offer');
      }
    }
  };

  const getOfferStatus = (offer: any) => {
    const currentDate = new Date();
    const expiryDate = new Date(offer.expires_on);
    return expiryDate >= currentDate ? 'Active' : 'Expired';
  };

  const getOfferStatusColor = (offer: any) => {
    const status = getOfferStatus(offer);
    return status === 'Active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800';
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

  // Filter employees based on search and status
  const filteredEmployees = employees.filter((employee: any) => {
    const matchesSearch = employee.name?.toLowerCase().includes(employeeSearch.toLowerCase()) ||
                         employee.email?.toLowerCase().includes(employeeSearch.toLowerCase()) ||
                         employee.mobile?.toLowerCase().includes(employeeSearch.toLowerCase()) ||
                         employee.serviceType?.toLowerCase().includes(employeeSearch.toLowerCase());
    
    const matchesStatus = employeeStatus === 'all' || 
                         (employeeStatus === 'active' && employee.status !== 'inactive') ||
                         (employeeStatus === 'inactive' && employee.status === 'inactive');
    
    return matchesSearch && matchesStatus;
  });
  const queriesDataAny = queriesData as any;
  const queries = queriesDataAny?.queries || queriesDataAny?.data?.queries || [];

  // Offers data processing
  const offersDataAny = offersData as any;
  const offers = offersDataAny?.offers || [];

  // Filter offers based on search and status
  const filteredOffers = offers.filter((offer: any) => {
    const matchesSearch = offer.offer_name?.toLowerCase().includes(offerSearch.toLowerCase()) ||
                         offer.coupon_number?.toLowerCase().includes(offerSearch.toLowerCase());
    
    const currentDate = new Date();
    const expiryDate = new Date(offer.expires_on);
    const isActive = expiryDate >= currentDate;
    
    const matchesStatus = offerStatus === 'all' || 
                         (offerStatus === 'active' && isActive) ||
                         (offerStatus === 'expired' && !isActive);
    
    return matchesSearch && matchesStatus;
  });

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
    { id: 'offers', label: 'Offers', icon: FiTag },
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

  // Helper to get full image URL for offers
  const getOfferImageUrl = (imagePath?: string | null): string | undefined => {
    if (!imagePath || imagePath === 'no-banner') return undefined;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('data:')) return imagePath;
    return `${API_BASE_URL.replace(/\/$/, '')}/${imagePath.replace(/^\/+/, '')}`;
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
            { id: 'offers', label: 'Offers', icon: FiTag },
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
            {activeTab === 'offers' && (
              <h2 className="text-3xl font-semibold text-gray-900 mb-1 tracking-tight">Offers</h2>
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
                      placeholder="Search employees..."
                      value={employeeSearch}
                      onChange={e => setEmployeeSearch(e.target.value)}
                    />
                  </div>
                  {/* Right: Filter and View Toggle */}
                  <div className="flex items-center gap-3 w-full sm:w-auto justify-end">
                    <div className="flex items-center gap-2">
                      <label htmlFor="employeeStatus" className="text-sm text-gray-500 font-medium hidden sm:block">Status:</label>
                      <select
                        id="employeeStatus"
                        className="w-full sm:w-44 px-3 py-2 border border-gray-200 rounded-lg shadow-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 text-sm bg-white"
                        value={employeeStatus}
                        onChange={e => setEmployeeStatus(e.target.value)}
                      >
                        <option value="all">All Statuses</option>
                        <option value="active">Active</option>
                        <option value="inactive">Inactive</option>
                      </select>
                    </div>
                                         <div className="flex gap-2">
                       <button
                         className={`p-2 rounded-lg border ${employeeView === 'table' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                         title="Table View"
                         onClick={() => setEmployeeView('table')}
                       >
                         <FiTable className="w-4 h-4" />
                       </button>
                       <button
                         className={`p-2 rounded-lg border ${employeeView === 'card' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                         title="Card View"
                         onClick={() => setEmployeeView('card')}
                       >
                         <FiGrid className="w-4 h-4" />
                       </button>
                       <button
                         className={`p-2 rounded-lg border ${employeeView === 'list' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                         title="List View"
                         onClick={() => setEmployeeView('list')}
                       >
                         <FiList className="w-4 h-4" />
                       </button>
                       <button 
                         className="btn btn-primary text-sm ml-2"
                         onClick={handleAddEmployee}
                       >
                         Add Employee
                       </button>
                     </div>
                  </div>
                </div>

                                 {/* Add Employee Button - moved to view controls line */}

                {employeesLoading ? (
                  <div className="flex justify-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
                  </div>
                ) : (
                  <>
                    {/* Table View */}
                    {employeeView === 'table' && (
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
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Actions
                              </th>
                            </tr>
                          </thead>
                          <tbody className="bg-white divide-y divide-gray-200">
                            {filteredEmployees.map((employee: any) => (
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
                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                  <div className="flex space-x-2">
                                    <button
                                      onClick={() => handleViewEmployee(employee)}
                                      className="text-blue-600 hover:text-blue-900 bg-blue-50 hover:bg-blue-100 px-3 py-1 rounded-md text-xs font-medium transition-colors"
                                    >
                                      View
                                    </button>
                                    <button
                                      onClick={() => handleResetPassword(employee)}
                                      className="text-orange-600 hover:text-orange-900 bg-orange-50 hover:bg-orange-100 px-3 py-1 rounded-md text-xs font-medium transition-colors"
                                    >
                                      Reset Password
                                    </button>
                                  </div>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    )}

                    {/* Card View */}
                    {employeeView === 'card' && (
                      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 p-6">
                        {filteredEmployees.map((employee: any) => (
                          <div key={employee.id} className="bg-white rounded-xl shadow p-5 flex flex-col gap-2 border border-gray-100">
                            <div className="flex items-center justify-between mb-2">
                              <span className="font-semibold text-gray-900 text-base">{employee.name}</span>
                              <span className="px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                                Active
                              </span>
                            </div>
                            <div className="text-xs text-gray-500 mb-1">{employee.email}</div>
                            <div className="text-sm text-gray-700 mb-1">{employee.mobile}</div>
                            <div className="font-medium text-gray-700">{employee.serviceType}</div>
                            <div className="flex gap-2 mt-3">
                              <button
                                className="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                onClick={() => handleViewEmployee(employee)}
                              >
                                View Details
                              </button>
                              <button
                                className="bg-orange-500 hover:bg-orange-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                onClick={() => handleResetPassword(employee)}
                              >
                                Reset Password
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}

                    {/* List View */}
                    {employeeView === 'list' && (
                      <div className="divide-y divide-gray-100 bg-white rounded-xl shadow p-2">
                        {filteredEmployees.map((employee: any) => (
                          <div key={employee.id} className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 py-3 px-2">
                            <div className="flex-1 min-w-0">
                              <div className="font-semibold text-gray-900 text-sm truncate">{employee.name}</div>
                              <div className="text-xs text-gray-500 truncate">{employee.email}</div>
                              <div className="text-xs text-gray-700 truncate">{employee.mobile}</div>
                              <div className="text-xs text-gray-400">{employee.serviceType}</div>
                            </div>
                            <div className="flex gap-2 mt-2 sm:mt-0">
                              <span className="px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                                Active
                              </span>
                              <button
                                className="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                onClick={() => handleViewEmployee(employee)}
                              >
                                View
                              </button>
                              <button
                                className="bg-orange-500 hover:bg-orange-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                onClick={() => handleResetPassword(employee)}
                              >
                                Reset Password
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

            {activeTab === 'offers' && (
              <div className="bg-white rounded-lg shadow-sm overflow-hidden">
                {/* Offers Controls: Search, Filter, View Toggle */}
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 px-6 py-4 border-b border-gray-100 bg-gray-50 mb-2">
                  {/* Left: Search Bar */}
                  <div className="relative w-full sm:w-[32rem] mb-2 sm:mb-0">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
                      <FiSearch className="w-5 h-5" />
                    </span>
                    <input
                      type="text"
                      className="w-full pl-10 pr-3 py-2 border border-gray-200 rounded-lg shadow-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 text-sm placeholder-gray-400"
                      placeholder="Search offers..."
                      value={offerSearch}
                      onChange={e => setOfferSearch(e.target.value)}
                    />
                  </div>
                  {/* Right: Filter, View Toggle, and Add Offer Button */}
                  <div className="flex items-center gap-3 w-full sm:w-auto justify-end">
                    <div className="flex items-center gap-2">
                      <label htmlFor="offerStatus" className="text-sm text-gray-500 font-medium hidden sm:block">Status:</label>
                      <select
                        id="offerStatus"
                        className="w-full sm:w-44 px-3 py-2 border border-gray-200 rounded-lg shadow-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 text-sm bg-white"
                        value={offerStatus}
                        onChange={e => setOfferStatus(e.target.value)}
                      >
                        <option value="all">All Statuses</option>
                        <option value="active">Active</option>
                        <option value="expired">Expired</option>
                      </select>
                    </div>
                    <div className="flex gap-2">
                      <button
                        className={`p-2 rounded-lg border ${offerView === 'table' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="Table View"
                        onClick={() => setOfferView('table')}
                      >
                        <FiTable className="w-5 h-5" />
                      </button>
                      <button
                        className={`p-2 rounded-lg border ${offerView === 'card' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="Card View"
                        onClick={() => setOfferView('card')}
                      >
                        <FiGrid className="w-5 h-5" />
                      </button>
                      <button
                        className={`p-2 rounded-lg border ${offerView === 'list' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="List View"
                        onClick={() => setOfferView('list')}
                      >
                        <FiList className="w-5 h-5" />
                      </button>
                    </div>
                    <button className="bg-teal-500 hover:bg-teal-600 text-white px-4 py-2 rounded-lg font-semibold text-sm transition-colors" onClick={() => setShowAddOffer(true)}>
                      Add Offer
                    </button>
                  </div>
                </div>
                {offersLoading ? (
                  <div className="flex justify-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
                  </div>
                ) : (
                  <>
                    {/* Table View */}
                    {offerView === 'table' && (
                      <div className="overflow-x-auto">
                        <table className="min-w-full divide-y divide-gray-200">
                          <thead className="bg-gray-50">
                            <tr>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Banner</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Offer Name</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Coupon</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Discount</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Expires</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                            </tr>
                          </thead>
                          <tbody className="bg-white divide-y divide-gray-200">
                            {filteredOffers.map((offer: any) => (
                              <tr key={offer.offer_id}>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  {offer.offer_banner_location ? (
                                    <img 
                                      src={getOfferImageUrl(offer.offer_banner_location)} 
                                      alt={`${offer.offer_name} banner`}
                                      className="w-16 h-12 object-cover rounded-lg border border-gray-200"
                                      onError={(e) => {
                                        e.currentTarget.style.display = 'none';
                                      }}
                                    />
                                  ) : (
                                    <div className="w-16 h-12 bg-gray-100 rounded-lg border border-gray-200 flex items-center justify-center">
                                      <FiImage className="w-6 h-6 text-gray-400" />
                                    </div>
                                  )}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  <div className="text-sm font-medium text-gray-900">{offer.offer_name}</div>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                  {offer.coupon_number}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                  {Math.round(offer.offer_percentage)}%
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                  {formatDate(offer.expires_on)}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${getOfferStatusColor(offer)}`}>
                                    {getOfferStatus(offer)}
                                  </span>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  <div className="flex space-x-2">
                                    <button
                                      className="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1 rounded font-semibold text-xs transition"
                                      onClick={() => setEditingOffer(offer)}
                                    >
                                      Edit
                                    </button>
                                    <button
                                      className="bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded font-semibold text-xs transition"
                                      onClick={() => handleDeleteOffer(offer.offer_id)}
                                    >
                                      Delete
                                    </button>
                                  </div>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    )}
                    {/* Card View */}
                    {offerView === 'card' && (
                      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 p-4">
                        {filteredOffers.map((offer: any) => (
                          <div key={offer.offer_id} className="bg-white rounded-xl shadow p-5 flex flex-col gap-2 border border-gray-100">
                            {/* Banner Image */}
                            {offer.offer_banner_location && (
                              <div className="mb-3">
                                <img 
                                  src={getOfferImageUrl(offer.offer_banner_location)} 
                                  alt={`${offer.offer_name} banner`}
                                  className="w-full h-32 object-cover rounded-lg border border-gray-200"
                                  onError={(e) => {
                                    e.currentTarget.style.display = 'none';
                                  }}
                                />
                              </div>
                            )}
                            <div className="flex items-center justify-between mb-2">
                              <span className="font-semibold text-gray-900 text-base">{offer.offer_name}</span>
                              <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getOfferStatusColor(offer)}`}>
                                {getOfferStatus(offer)}
                              </span>
                            </div>

                            <div className="font-medium text-gray-700">{offer.coupon_number}</div>
                            <div className="text-gray-500 text-sm">{Math.round(offer.offer_percentage)}% off</div>
                            <div className="text-xs text-gray-400 mt-1">Expires: {formatDate(offer.expires_on)}</div>
                            <div className="flex gap-2 mt-3">
                              <button
                                className="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                onClick={() => setEditingOffer(offer)}
                              >
                                Edit
                              </button>
                              <button
                                className="bg-red-500 hover:bg-red-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                onClick={() => handleDeleteOffer(offer.offer_id)}
                              >
                                Delete
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                    {/* List View */}
                    {offerView === 'list' && (
                      <div className="divide-y divide-gray-100 bg-white rounded-xl shadow p-2">
                        {filteredOffers.map((offer: any) => (
                          <div key={offer.offer_id} className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 py-3 px-2">
                            {/* Banner Image */}
                            {offer.offer_banner_location && (
                              <div className="flex-shrink-0 mr-3">
                                <img 
                                  src={getOfferImageUrl(offer.offer_banner_location)} 
                                  alt={`${offer.offer_name} banner`}
                                  className="w-12 h-12 object-cover rounded-lg border border-gray-200"
                                  onError={(e) => {
                                    e.currentTarget.style.display = 'none';
                                  }}
                                />
                              </div>
                            )}
                            <div className="flex-1 min-w-0">
                              <div className="font-semibold text-gray-900 text-sm truncate">{offer.offer_name}</div>

                              <div className="text-xs text-gray-700 truncate">{offer.coupon_number}</div>
                              <div className="text-xs text-gray-400">{Math.round(offer.offer_percentage)}% off</div>
                              <div className="text-xs text-gray-900">Expires: {formatDate(offer.expires_on)}</div>
                            </div>
                            <div className="flex gap-2 mt-2 sm:mt-0">
                              <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getOfferStatusColor(offer)}`}>
                                {getOfferStatus(offer)}
                              </span>
                              <button
                                className="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                onClick={() => setEditingOffer(offer)}
                              >
                                Edit
                              </button>
                              <button
                                className="bg-red-500 hover:bg-red-600 text-white px-3 py-1.5 rounded font-semibold text-xs transition"
                                onClick={() => handleDeleteOffer(offer.offer_id)}
                              >
                                Delete
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
                      placeholder="Search services..."
                      value={serviceSearch}
                      onChange={e => setServiceSearch(e.target.value)}
                    />
                  </div>
                  {/* Right: Filter, View Toggle, and Add Service Button */}
                  <div className="flex items-center gap-3 w-full sm:w-auto justify-end">
                    <div className="flex items-center gap-2">
                      <label htmlFor="serviceStatus" className="text-sm text-gray-500 font-medium hidden sm:block">Status:</label>
                      <select
                        id="serviceStatus"
                        className="w-full sm:w-44 px-3 py-2 border border-gray-200 rounded-lg shadow-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 text-sm bg-white"
                        value={serviceStatus}
                        onChange={e => setServiceStatus(e.target.value)}
                      >
                        <option value="all">All Statuses</option>
                        <option value="active">Active</option>
                        <option value="inactive">Inactive</option>
                      </select>
                    </div>
                    <div className="flex gap-2">
                      <button
                        className={`p-2 rounded-lg border ${serviceView === 'table' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="Table View"
                        onClick={() => setServiceView('table')}
                      >
                        <FiTable className="w-5 h-5" />
                      </button>
                      <button
                        className={`p-2 rounded-lg border ${serviceView === 'card' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="Card View"
                        onClick={() => setServiceView('card')}
                      >
                        <FiGrid className="w-5 h-5" />
                      </button>
                      <button
                        className={`p-2 rounded-lg border ${serviceView === 'list' ? 'bg-teal-50 border-teal-500 text-teal-700' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-100'}`}
                        title="List View"
                        onClick={() => setServiceView('list')}
                      >
                        <FiList className="w-5 h-5" />
                      </button>
                    </div>
                    <button className="bg-teal-500 hover:bg-teal-600 text-white px-4 py-2 rounded-lg font-semibold text-sm transition-colors" onClick={() => setShowAddService(true)}>
                      Add Service
                    </button>
                  </div>
                </div>
                {servicesLoading ? (
                  <div className="flex justify-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
                  </div>
                ) : (
                  <div className="p-6">
                    {filteredServices.length === 0 ? (
                      <div className="text-center py-12">
                        <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                        <h3 className="mt-2 text-sm font-medium text-gray-900">No services found</h3>
                        <p className="mt-1 text-sm text-gray-500">Try adjusting your search or filter criteria.</p>
                      </div>
                    ) : (
                      <>
                        {/* Table View */}
                        {serviceView === 'table' && (
                          <div className="overflow-x-auto">
                            <table className="min-w-full divide-y divide-gray-200">
                              <thead className="bg-gray-50">
                                <tr>
                                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Service</th>
                                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created Date</th>
                                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                                </tr>
                              </thead>
                              <tbody className="bg-white divide-y divide-gray-200">
                                {filteredServices.map((service: any) => (
                                  <tr key={service.service_id}>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                      <div className="font-medium">{service.service_name}</div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                      <div className="text-sm text-gray-500">{service.description}</div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                      {service.created_at ? new Date(service.created_at).toLocaleDateString() : 'N/A'}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                      <span className="inline-block px-2 py-1 text-xs font-semibold rounded bg-green-100 text-green-800">Active</span>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                      <button className="bg-teal-500 hover:bg-teal-600 text-white px-4 py-2 rounded font-semibold text-xs transition" onClick={() => { setEditingService(service); setActiveServiceModal('edit'); }}>
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
                        {serviceView === 'card' && (
                          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                            {filteredServices.map((service: any) => (
                              <div key={service.service_id} className="bg-white border border-gray-200 rounded-lg shadow-sm hover:shadow-md transition-shadow">
                                <div className="p-6">
                                  <div className="flex items-start justify-between mb-4">
                                    <div className="flex-1">
                                      <h3 className="text-lg font-semibold text-gray-900 mb-2">{service.service_name}</h3>
                                      <p className="text-sm text-gray-600 line-clamp-3">{service.description}</p>
                                    </div>
                                  </div>
                                  <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                                    <span>Created: {service.created_at ? new Date(service.created_at).toLocaleDateString() : 'N/A'}</span>
                                    <span className="inline-block px-2 py-1 text-xs font-semibold rounded bg-green-100 text-green-800">Active</span>
                                  </div>
                                  <div className="flex justify-end">
                                    <button 
                                      className="bg-teal-500 hover:bg-teal-600 text-white px-4 py-2 rounded font-semibold text-sm transition"
                                      onClick={() => { setEditingService(service); setActiveServiceModal('edit'); }}
                                    >
                                      View Details
                                    </button>
                                  </div>
                                </div>
                              </div>
                            ))}
                          </div>
                        )}

                        {/* List View */}
                        {serviceView === 'list' && (
                          <div className="space-y-4">
                            {filteredServices.map((service: any) => (
                              <div key={service.service_id} className="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow">
                                <div className="flex items-center justify-between">
                                  <div className="flex-1">
                                    <h3 className="text-lg font-semibold text-gray-900">{service.service_name}</h3>
                                    <p className="text-sm text-gray-600 mt-1">{service.description}</p>
                                    <div className="flex items-center gap-4 mt-2 text-sm text-gray-500">
                                      <span>Created: {service.created_at ? new Date(service.created_at).toLocaleDateString() : 'N/A'}</span>
                                      <span className="inline-block px-2 py-1 text-xs font-semibold rounded bg-green-100 text-green-800">Active</span>
                                    </div>
                                  </div>
                                  <button 
                                    className="bg-teal-500 hover:bg-teal-600 text-white px-4 py-2 rounded font-semibold text-sm transition"
                                    onClick={() => { setEditingService(service); setActiveServiceModal('edit'); }}
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

            {/* Add Service Modal */}
            {showAddService && (
              <Modal onClose={() => setShowAddService(false)} size="small">
                <div className="p-6 w-full">
                  <h3 className="text-lg font-semibold mb-4">Add New Service</h3>
                  <form onSubmit={async (e) => {
                    e.preventDefault();
                    const formData = new FormData(e.currentTarget);
                    
                    // Get the image file directly
                    const imageFile = formData.get('service_image') as File;
                    
                    const serviceData = {
                      service_name: formData.get('service_name') as string,
                      description: formData.get('description') as string,
                      locations: (formData.get('locations') as string)?.split(',').map(s => s.trim()).filter(Boolean) || [],
                      service_image: imageFile && imageFile.size > 0 ? imageFile : null
                    };
                    
                    try {
                      await handleAddService(serviceData);
                      setShowAddService(false);
                    } catch (error) {
                      console.error('Error adding service:', error);
                      toast.error('Failed to add service. Please try again.');
                    }
                  }}>
                    <div className="mb-4">
                      <label className="block text-sm font-medium text-gray-700 mb-1">Service Name *</label>
                      <input
                        type="text"
                        name="service_name"
                        required
                        className="w-full border border-gray-300 rounded px-3 py-2"
                        placeholder="Enter service name"
                      />
                    </div>
                    <div className="mb-4">
                      <label className="block text-sm font-medium text-gray-700 mb-1">Description *</label>
                      <textarea
                        name="description"
                        required
                        className="w-full border border-gray-300 rounded px-3 py-2"
                        placeholder="Enter service description"
                        rows={3}
                      />
                    </div>
                    <div className="mb-4">
                      <label className="block text-sm font-medium text-gray-700 mb-1">Locations (comma separated)</label>
                      <input
                        type="text"
                        name="locations"
                        className="w-full border border-gray-300 rounded px-3 py-2"
                        placeholder="e.g., Chennai, Coimbatore, Erode"
                      />
                    </div>
                    <div className="mb-4">
                      <label className="block text-sm font-medium text-gray-700 mb-1">Service Image</label>
                      <div className="flex items-center space-x-4">
                        <div className="flex-1">
                          <input
                            type="file"
                            name="service_image"
                            accept="image/*"
                            className="w-full border border-gray-300 rounded px-3 py-2"
                          />
                        </div>
                      </div>
                      <p className="text-xs text-gray-500 mt-1">Upload an image for this service (JPG, PNG, GIF)</p>
                    </div>
                    <div className="flex justify-end gap-2">
                      <button
                        type="button"
                        className="px-4 py-2 rounded bg-gray-200 text-gray-700"
                        onClick={() => setShowAddService(false)}
                      >
                        Cancel
                      </button>
                      <button
                        type="submit"
                        className="px-4 py-2 rounded bg-blue-500 text-white"
                      >
                        Save
                      </button>
                    </div>
                  </form>
                </div>
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

            {/* Employee Details Modal */}
            {showEmployeeDetails && selectedEmployee && (
              <Modal onClose={() => setShowEmployeeDetails(false)} size="small">
                <h2 className="text-lg font-semibold mb-4">Employee Details</h2>
                <div className="space-y-3">
                  <div className="flex justify-between">
                    <span className="font-medium text-gray-600">Name:</span>
                    <span className="text-gray-900">{selectedEmployee.name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-medium text-gray-600">Email:</span>
                    <span className="text-gray-900">{selectedEmployee.email || 'N/A'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-medium text-gray-600">Mobile:</span>
                    <span className="text-gray-900">{selectedEmployee.mobile}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-medium text-gray-600">Service Type:</span>
                    <span className="text-gray-900">{selectedEmployee.serviceType || 'General Service'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-medium text-gray-600">Address:</span>
                    <span className="text-gray-900">{selectedEmployee.address || 'N/A'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-medium text-gray-600">Status:</span>
                    <span className="px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      Active
                    </span>
                  </div>
                </div>
                <div className="mt-6 flex justify-end">
                  <button 
                    className="btn btn-secondary" 
                    onClick={() => setShowEmployeeDetails(false)}
                  >
                    Close
                  </button>
                </div>
              </Modal>
            )}

            {/* Reset Password Confirmation Modal */}
            {showResetPasswordConfirm && selectedEmployee && (
              <Modal onClose={() => setShowResetPasswordConfirm(false)} size="small">
                <h2 className="text-lg font-semibold mb-4">Reset Password</h2>
                <div className="text-center mb-6">
                  <div className="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <svg className="w-8 h-8 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                    </svg>
                  </div>
                  <p className="text-gray-700 mb-2">
                    Are you sure you want to reset the password for <strong>{selectedEmployee.name}</strong>?
                  </p>
                  <p className="text-sm text-gray-500">
                    The new password will be set to <strong>"12345"</strong>
                  </p>
                </div>
                <div className="flex justify-end gap-3">
                  <button 
                    className="btn btn-secondary" 
                    onClick={() => setShowResetPasswordConfirm(false)}
                    disabled={resetPasswordLoading}
                  >
                    Cancel
                  </button>
                  <button 
                    className="btn btn-primary bg-orange-600 hover:bg-orange-700" 
                    onClick={confirmResetPassword}
                    disabled={resetPasswordLoading}
                  >
                    {resetPasswordLoading ? 'Resetting...' : 'Reset Password'}
                  </button>
                </div>
              </Modal>
            )}

            {/* Add Employee Modal */}
            {showAddEmployee && (
              <Modal onClose={() => setShowAddEmployee(false)} size="large">
                <div className="max-w-2xl mx-auto">
                  <div className="mb-6">
                    <h2 className="text-2xl font-bold text-gray-900">Add New Employee</h2>
                  </div>

                  <form onSubmit={(e) => { e.preventDefault(); handleAddEmployeeSubmit(); }} className="space-y-6">
                    {/* Personal Information Section */}
                    <div className="bg-gray-50 rounded-lg p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                        <svg className="w-5 h-5 mr-2 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                        Personal Information
                      </h3>
                      
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Employee Name *
                          </label>
                          <input
                            type="text"
                            required
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                            value={addEmployeeForm.employee_name}
                            onChange={(e) => setAddEmployeeForm({...addEmployeeForm, employee_name: e.target.value})}
                            placeholder="Enter employee name"
                          />
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Phone Number *
                          </label>
                          <input
                            type="tel"
                            required
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                            value={addEmployeeForm.phone_number}
                            onChange={(e) => setAddEmployeeForm({...addEmployeeForm, phone_number: e.target.value})}
                            placeholder="Enter phone number"
                          />
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Email Address *
                          </label>
                          <input
                            type="email"
                            required
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                            value={addEmployeeForm.email}
                            onChange={(e) => setAddEmployeeForm({...addEmployeeForm, email: e.target.value})}
                            placeholder="Enter email address"
                          />
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Password *
                          </label>
                          <input
                            type="password"
                            required
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                            value={addEmployeeForm.password}
                            onChange={(e) => setAddEmployeeForm({...addEmployeeForm, password: e.target.value})}
                            placeholder="Enter password"
                          />
                        </div>
                      </div>
                    </div>

                    {/* Service Information Section */}
                    <div className="bg-gray-50 rounded-lg p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                        <svg className="w-5 h-5 mr-2 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2-2v2m8 0V6a2 2 0 012 2v6a2 2 0 01-2 2H6a2 2 0 01-2-2V8a2 2 0 012-2V6" />
                        </svg>
                        Service Information
                      </h3>
                      
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Service Type *
                          </label>
                          <input
                            type="text"
                            required
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                            value={addEmployeeForm.service_type}
                            onChange={(e) => setAddEmployeeForm({...addEmployeeForm, service_type: e.target.value})}
                            placeholder="e.g., Pest Control, General Service"
                          />
                        </div>
                        
                        <div className="md:col-span-2">
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Address *
                          </label>
                          <textarea
                            required
                            rows={3}
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                            value={addEmployeeForm.address}
                            onChange={(e) => setAddEmployeeForm({...addEmployeeForm, address: e.target.value})}
                            placeholder="Enter complete address"
                          />
                        </div>
                      </div>
                    </div>

                    {/* ID Proof Upload Section */}
                    <div className="bg-gray-50 rounded-lg p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                        <svg className="w-5 h-5 mr-2 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                        Identity Proof *
                      </h3>
                      
                      <div className="space-y-4">
                        <div className="flex items-center justify-center w-full">
                          <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100 transition-colors">
                            <div className="flex flex-col items-center justify-center pt-5 pb-6">
                              {addEmployeeIdProofPreview ? (
                                <div className="relative">
                                  <img 
                                    src={addEmployeeIdProofPreview} 
                                    alt="ID Proof Preview" 
                                    className="max-h-20 max-w-full rounded"
                                  />
                                  <button
                                    type="button"
                                    onClick={() => {
                                      setAddEmployeeIdProof(null);
                                      setAddEmployeeIdProofPreview(null);
                                    }}
                                    className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-600"
                                  >
                                    ×
                                  </button>
                                </div>
                              ) : (
                                <>
                                  <svg className="w-8 h-8 mb-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                                  </svg>
                                  <p className="mb-2 text-sm text-gray-500">
                                    <span className="font-semibold">Click to upload</span> or drag and drop
                                  </p>
                                  <p className="text-xs text-gray-500">PNG, JPG, PDF up to 10MB</p>
                                </>
                              )}
                            </div>
                            <input 
                              type="file" 
                              className="hidden" 
                              accept="image/*,.pdf"
                              onChange={handleIdProofChange}
                              required={!addEmployeeIdProof}
                            />
                          </label>
                        </div>
                        
                        {addEmployeeIdProof && (
                          <div className="text-sm text-gray-600">
                            <p><strong>Selected file:</strong> {addEmployeeIdProof.name}</p>
                            <p><strong>Size:</strong> {(addEmployeeIdProof.size / 1024 / 1024).toFixed(2)} MB</p>
                          </div>
                        )}
                      </div>
                    </div>



                    {/* Action Buttons */}
                    <div className="flex justify-end gap-3 pt-6 border-t border-gray-200">
                      <button
                        type="button"
                        onClick={() => setShowAddEmployee(false)}
                        className="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
                        disabled={addEmployeeLoading}
                      >
                        Cancel
                      </button>
                      <button
                        type="submit"
                        className="px-6 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                        disabled={addEmployeeLoading}
                      >
                        {addEmployeeLoading ? (
                          <>
                            <svg className="animate-spin -ml-1 mr-3 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                            Adding Employee...
                          </>
                        ) : (
                          'Add Employee'
                        )}
                      </button>
                    </div>
                  </form>
                </div>
              </Modal>
            )}

            {/* Add/Edit Offer Modal */}
            {(showAddOffer || editingOffer) && (
              <Modal onClose={() => { 
                setShowAddOffer(false); 
                setEditingOffer(null); 
                setSelectedBannerPreview(null);
                setSelectedBannerBase64('');
              }}>
                <div className="max-w-2xl mx-auto">
                  <div className="flex items-center justify-between mb-6">
                    <h2 className="text-2xl font-bold text-gray-900">
                      {editingOffer ? 'Edit Offer' : 'Add New Offer'}
                    </h2>
                  </div>

                  <form onSubmit={async (e) => {
                    e.preventDefault();
                    const formData = new FormData(e.currentTarget);
                    
                    // Handle banner image logic
                    let offer_banner: string = '';
                    
                    // For new offers, require an image
                    if (!editingOffer && !selectedBannerBase64) {
                      toast.error('Please upload a banner image');
                      return;
                    }
                    
                    // For editing offers
                    if (editingOffer) {
                      // If there's a new image selected, use it
                      if (selectedBannerBase64) {
                        offer_banner = selectedBannerBase64;
                      } else {
                        // If no new image and current banner was deleted (set to special marker), send a special marker
                        if (editingOffer.offer_banner_location === 'DELETE_BANNER') {
                          offer_banner = 'DELETE_BANNER'; // Special marker to indicate deletion
                        } else {
                          // If current banner exists and no new image selected, don't include banner field
                          // This means the backend will keep the existing banner
                          offer_banner = ''; // Empty string means no change
                        }
                      }
                    } else {
                      // For new offers, use the base64 image
                      offer_banner = selectedBannerBase64;
                    }
                    
                    const offerData: any = {
                      offer_name: formData.get('offer_name') as string,
                      coupon_number: formData.get('coupon_number') as string,
                      offer_starts_on: formData.get('offer_starts_on') as string,
                      expires_on: formData.get('expires_on') as string,
                      offer_percentage: parseInt(formData.get('offer_percentage') as string)
                    };
                    
                    // Always include banner field, but use special markers
                    offerData.offer_banner = offer_banner;
                    
                    // Add offer_id if editing
                    if (editingOffer) {
                      offerData.offer_id = editingOffer.offer_id;
                    }
                    
                    try {
                      await handleAddOffer(offerData);
                      setSelectedBannerPreview(null);
                      setSelectedBannerBase64('');
                    } catch (error) {
                      console.error('Error saving offer:', error);
                      toast.error('Failed to save offer. Please try again.');
                    }
                  }} className="space-y-6">
                    {/* Basic Information */}
                    <div className="bg-gray-50 rounded-lg p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                        <FiTag className="w-5 h-5 mr-2 text-teal-600" />
                        Offer Information
                      </h3>
                      
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Offer Name *
                          </label>
                          <input
                            type="text"
                            name="offer_name"
                            required
                            defaultValue={editingOffer?.offer_name || ''}
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                            placeholder="Enter offer name"
                          />
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Coupon Code *
                          </label>
                          <input
                            type="text"
                            name="coupon_number"
                            required
                            defaultValue={editingOffer?.coupon_number || ''}
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                            placeholder="Enter coupon code"
                          />
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Discount Percentage *
                          </label>
                          <input
                            type="number"
                            name="offer_percentage"
                            required
                            min="1"
                            max="100"
                            defaultValue={editingOffer?.offer_percentage || ''}
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                            placeholder="Enter discount percentage"
                          />
                        </div>
                      </div>
                    </div>

                    {/* Date Information */}
                    <div className="bg-gray-50 rounded-lg p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                        <FiCalendar className="w-5 h-5 mr-2 text-teal-600" />
                        Date Information
                      </h3>
                      
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Start Date *
                          </label>
                          <input
                            type="date"
                            name="offer_starts_on"
                            required
                            defaultValue={editingOffer?.offer_starts_on || ''}
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                          />
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Expiry Date *
                          </label>
                          <input
                            type="date"
                            name="expires_on"
                            required
                            defaultValue={editingOffer?.expires_on || ''}
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                          />
                        </div>
                      </div>
                    </div>

                    {/* Banner Image */}
                    <div className="bg-gray-50 rounded-lg p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                        <FiImage className="w-5 h-5 mr-2 text-teal-600" />
                        Banner Image
                      </h3>
                      
                      <div className="space-y-4">
                        {/* Current Banner Preview (when editing) */}
                        {editingOffer?.offer_banner_location && editingOffer?.offer_banner_location !== 'DELETE_BANNER' && !selectedBannerPreview && (
                          <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                              Current Banner
                            </label>
                            <div className="relative w-full h-32 bg-gray-100 rounded-lg overflow-hidden">
                              <img
                                src={getOfferImageUrl(editingOffer.offer_banner_location)}
                                alt="Current banner"
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                  const target = e.target as HTMLImageElement;
                                  target.style.display = 'none';
                                }}
                              />
                              <button
                                type="button"
                                onClick={() => {
                                  // Remove the current banner by setting it to a special marker
                                  setEditingOffer({
                                    ...editingOffer,
                                    offer_banner_location: 'DELETE_BANNER'
                                  });
                                }}
                                className="absolute top-2 right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-600 transition-colors"
                                title="Delete current banner"
                              >
                                ×
                              </button>
                            </div>
                          </div>
                        )}
                        
                        {/* Selected Image Preview (when adding new or updating) */}
                        {selectedBannerPreview && (
                          <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                              Selected Image Preview
                            </label>
                            <div className="relative w-full h-32 bg-gray-100 rounded-lg overflow-hidden">
                              <img
                                src={selectedBannerPreview}
                                alt="Selected banner preview"
                                className="w-full h-full object-cover"
                              />
                              <button
                                type="button"
                                onClick={() => {
                                  setSelectedBannerPreview(null);
                                  setSelectedBannerBase64('');
                                  // Clear the file input
                                  const fileInput = document.querySelector('input[name="offer_banner"]') as HTMLInputElement;
                                  if (fileInput) {
                                    fileInput.value = '';
                                  }
                                }}
                                className="absolute top-2 right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-600 transition-colors"
                                title="Delete selected image"
                              >
                                ×
                              </button>
                            </div>
                          </div>
                        )}
                        
                        {/* File Upload (only show when no image is present) */}
                        {!selectedBannerPreview && (!editingOffer?.offer_banner_location || editingOffer?.offer_banner_location === 'DELETE_BANNER') && (
                          <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                              {editingOffer ? 'Upload Banner Image' : 'Upload Banner Image *'}
                            </label>
                            <input
                              type="file"
                              name="offer_banner"
                              accept="image/*"
                              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-medium file:bg-teal-50 file:text-teal-700 hover:file:bg-teal-100"
                              onChange={(e) => {
                                const file = e.target.files?.[0];
                                if (file) {
                                  // Check file size (2MB limit)
                                  if (file.size > 2 * 1024 * 1024) {
                                    toast.error('File size must be less than 2MB');
                                    e.target.value = '';
                                    setSelectedBannerPreview(null);
                                    setSelectedBannerBase64('');
                                    return;
                                  }
                                  
                                  const reader = new FileReader();
                                  reader.onload = (event) => {
                                    const base64 = event.target?.result as string;
                                    setSelectedBannerPreview(base64);
                                    setSelectedBannerBase64(base64.split(',')[1]); // Remove data:image/...;base64, prefix
                                  };
                                  reader.readAsDataURL(file);
                                } else {
                                  setSelectedBannerPreview(null);
                                  setSelectedBannerBase64('');
                                }
                              }}
                            />
                            <p className="text-sm text-gray-500 mt-1">
                              Recommended size: 800x400 pixels. Max file size: 2MB.
                            </p>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Action Buttons */}
                    <div className="flex justify-end gap-3 pt-6 border-t border-gray-200">
                      <button
                        type="button"
                        onClick={() => { 
                          setShowAddOffer(false); 
                          setEditingOffer(null); 
                          setSelectedBannerPreview(null);
                          setSelectedBannerBase64('');
                        }}
                        className="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
                      >
                        Cancel
                      </button>
                      <button
                        type="submit"
                        className="px-6 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 transition-colors"
                      >
                        {editingOffer ? 'Update Offer' : 'Add Offer'}
                      </button>
                    </div>
                  </form>
                </div>
              </Modal>
            )}
        </motion.div>
      </main>
    </div>
  );
};

export default AdminDashboard;
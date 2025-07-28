import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  FiArrowLeft, 
  FiMessageSquare, 
  FiUser, 
  FiMail, 
  FiPhone, 
  FiFileText, 
  FiSend, 
  FiCheckCircle, 
  FiAlertCircle,
  FiClock,
  FiShield,
  FiZap,
  FiAward,
  FiGlobe,
  FiHeart,
  FiRefreshCw,
  FiEye,
  FiEyeOff,
  FiMapPin,
  FiMail as FiContactMail,
  FiPhone as FiContactPhone,
  FiMapPin as FiContactMapPin
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { apiService } from '../services/api';
import { API_ENDPOINTS, API_BASE_URL } from '../config/api';
import toast from 'react-hot-toast';

interface ContactQuery {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  subject: string;
  message: string;
  status: string;
  admin_response?: string;
  response_date?: string;
  response_date_formatted?: string;
  created_at: string;
  created_at_formatted: string;
  updated_at: string;
  has_response: boolean;
}

interface UserProfile {
  customer_name?: string;
  email_id?: string;
  mobile_number?: string;
}

const RaiseTicket: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<'form' | 'queries'>('form');
  const [isLoading, setIsLoading] = useState(false);
  const [isLoadingQueries, setIsLoadingQueries] = useState(false);
  const [queries, setQueries] = useState<ContactQuery[]>([]);
  const [userProfile, setUserProfile] = useState<UserProfile>({});

  // Form state
  const [formData, setFormData] = useState({
    first_name: '',
    last_name: '',
    email: '',
    phone: '',
    subject: '',
    message: ''
  });

  const subjects = [
    'General Inquiry',
    'Billing Inquiry', 
    'Technical Support',
    'Feedback'
  ];

  useEffect(() => {
    fetchUserProfile();
    fetchQueries();
  }, []);

  const fetchUserProfile = async () => {
    try {
      const response = await apiService.getProfile();
      if (response.status === 'success' && response.data) {
        setUserProfile(response.data);
        // Pre-fill form with user data
        setFormData(prev => ({
          ...prev,
          email: response.data.email_id || '',
          first_name: response.data.customer_name?.split(' ')[0] || '',
          last_name: response.data.customer_name?.split(' ').slice(1).join(' ') || '',
          phone: response.data.mobile_number || ''
        }));
      }
    } catch (error) {
      console.error('Error fetching profile:', error);
    }
  };

  const fetchQueries = async () => {
    setIsLoadingQueries(true);
    try {
      const response = await apiService.getUserContactQueries();
      if (response.status === 'success') {
        setQueries(response.queries || []);
      }
    } catch (error) {
      console.error('Error fetching queries:', error);
      toast.error('Failed to load your queries');
    } finally {
      setIsLoadingQueries(false);
    }
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const validateForm = () => {
    if (!formData.first_name.trim()) {
      toast.error('First name is required');
      return false;
    }
    if (!formData.last_name.trim()) {
      toast.error('Last name is required');
      return false;
    }
    if (!formData.email.trim()) {
      toast.error('Email is required');
      return false;
    }
    if (!formData.phone.trim()) {
      toast.error('Phone number is required');
      return false;
    }
    if (!formData.subject.trim()) {
      toast.error('Please select a subject');
      return false;
    }
    if (!formData.message.trim()) {
      toast.error('Message is required');
      return false;
    }
    return true;
  };

  const handleSubmit = async () => {
    if (!validateForm()) return;

    setIsLoading(true);
    try {
      const response = await apiService.submitContactQuery(formData);
      if (response.status === 'success') {
        toast.success('Your ticket has been submitted successfully!');
        // Clear form
        setFormData({
          first_name: '',
          last_name: '',
          email: '',
          phone: '',
          subject: '',
          message: ''
        });
        // Refresh queries and switch to queries tab
        await fetchQueries();
        setActiveTab('queries');
      } else {
        toast.error(response.message || 'Failed to submit ticket');
      }
    } catch (error) {
      console.error('Error submitting ticket:', error);
      toast.error('Failed to submit ticket. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'responded':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'pending':
        return 'bg-orange-100 text-orange-800 border-orange-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'responded':
        return <FiCheckCircle className="w-4 h-4" />;
      case 'pending':
        return <FiClock className="w-4 h-4" />;
      default:
        return <FiAlertCircle className="w-4 h-4" />;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-blue-50">
      {/* Header */}
      <motion.header 
        className="bg-white/80 backdrop-blur-sm shadow-sm border-b border-gray-200"
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.5 }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => navigate(-1)}
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
                <h1 className="text-xl font-semibold text-gray-900">Raise a Ticket</h1>
                <p className="text-sm text-gray-500">Get help from our support team</p>
              </div>
            </div>
          </div>
        </div>
      </motion.header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Main Content */}
          <div className="lg:col-span-2">
            <motion.div 
              className="bg-white rounded-2xl shadow-xl overflow-hidden"
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ duration: 0.5, delay: 0.1 }}
            >
              {/* Tab Navigation */}
              <div className="flex border-b border-gray-200">
                <button
                  onClick={() => setActiveTab('form')}
                  className={`flex-1 px-6 py-4 text-sm font-medium transition-colors ${
                    activeTab === 'form'
                      ? 'text-teal-600 border-b-2 border-teal-600 bg-teal-50'
                      : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <div className="flex items-center space-x-2">
                    <FiMessageSquare className="w-4 h-4" />
                    <span>Submit Ticket</span>
                  </div>
                </button>
                <button
                  onClick={() => setActiveTab('queries')}
                  className={`flex-1 px-6 py-4 text-sm font-medium transition-colors ${
                    activeTab === 'queries'
                      ? 'text-teal-600 border-b-2 border-teal-600 bg-teal-50'
                      : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <div className="flex items-center space-x-2">
                    <FiFileText className="w-4 h-4" />
                    <span>My Tickets ({queries.length})</span>
                  </div>
                </button>
              </div>

              {/* Tab Content */}
              <div className="p-6">
                <AnimatePresence mode="wait">
                  {activeTab === 'form' ? (
                    <motion.div
                      key="form"
                      initial={{ opacity: 0, x: 20 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: -20 }}
                      transition={{ duration: 0.3 }}
                      className="space-y-6"
                    >
                      {/* Header Section */}
                      <div className="text-center mb-8">
                        <motion.div
                          className="w-16 h-16 bg-gradient-to-br from-teal-500 to-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-4"
                          whileHover={{ scale: 1.05, rotate: 5 }}
                          transition={{ duration: 0.3 }}
                        >
                          <FiMessageSquare className="w-8 h-8 text-white" />
                        </motion.div>
                        <h2 className="text-2xl font-bold text-gray-900 mb-2">
                          Need Help?
                        </h2>
                        <p className="text-gray-600 max-w-md mx-auto">
                          Our support team is here to help you with any questions or concerns you may have.
                        </p>
                      </div>

                      {/* Form Fields */}
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            First Name *
                          </label>
                          <div className="relative">
                            <FiUser className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                            <input
                              type="text"
                              value={formData.first_name}
                              onChange={(e) => handleInputChange('first_name', e.target.value)}
                              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-colors"
                              placeholder="Enter your first name"
                            />
                          </div>
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Last Name *
                          </label>
                          <div className="relative">
                            <FiUser className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                            <input
                              type="text"
                              value={formData.last_name}
                              onChange={(e) => handleInputChange('last_name', e.target.value)}
                              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-colors"
                              placeholder="Enter your last name"
                            />
                          </div>
                        </div>
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Email Address *
                        </label>
                        <div className="relative">
                          <FiMail className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                          <input
                            type="email"
                            value={formData.email}
                            onChange={(e) => handleInputChange('email', e.target.value)}
                            className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-colors"
                            placeholder="Enter your email address"
                          />
                        </div>
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Phone Number *
                        </label>
                        <div className="relative">
                          <FiPhone className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                          <input
                            type="tel"
                            value={formData.phone}
                            onChange={(e) => handleInputChange('phone', e.target.value)}
                            className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-colors"
                            placeholder="Enter your phone number"
                          />
                        </div>
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Subject *
                        </label>
                        <div className="grid grid-cols-2 gap-3">
                          {subjects.map((subject) => (
                            <button
                              key={subject}
                              type="button"
                              onClick={() => handleInputChange('subject', subject)}
                              className={`p-3 rounded-lg border-2 transition-all ${
                                formData.subject === subject
                                  ? 'border-teal-500 bg-teal-50 text-teal-700'
                                  : 'border-gray-200 hover:border-gray-300 text-gray-700'
                              }`}
                            >
                              {subject}
                            </button>
                          ))}
                        </div>
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Message *
                        </label>
                        <textarea
                          value={formData.message}
                          onChange={(e) => handleInputChange('message', e.target.value)}
                          rows={5}
                          className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-colors resize-none"
                          placeholder="Describe your issue or question in detail..."
                        />
                      </div>

                      <motion.button
                        onClick={handleSubmit}
                        disabled={isLoading}
                        className="w-full bg-gradient-to-r from-teal-600 to-blue-600 text-white py-4 px-6 rounded-lg font-semibold text-lg shadow-lg hover:shadow-xl transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                      >
                        {isLoading ? (
                          <div className="flex items-center justify-center space-x-2">
                            <FiRefreshCw className="w-5 h-5 animate-spin" />
                            <span>Submitting...</span>
                          </div>
                        ) : (
                          <div className="flex items-center justify-center space-x-2">
                            <FiSend className="w-5 h-5" />
                            <span>Submit Ticket</span>
                          </div>
                        )}
                      </motion.button>
                    </motion.div>
                  ) : (
                    <motion.div
                      key="queries"
                      initial={{ opacity: 0, x: 20 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: -20 }}
                      transition={{ duration: 0.3 }}
                    >
                      {isLoadingQueries ? (
                        <div className="flex items-center justify-center py-12">
                          <FiRefreshCw className="w-8 h-8 animate-spin text-teal-600" />
                        </div>
                      ) : queries.length === 0 ? (
                        <div className="text-center py-12">
                          <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                            <FiFileText className="w-10 h-10 text-gray-400" />
                          </div>
                          <h3 className="text-lg font-semibold text-gray-900 mb-2">
                            No tickets yet
                          </h3>
                          <p className="text-gray-500 mb-6">
                            Your submitted tickets will appear here
                          </p>
                          <button
                            onClick={() => setActiveTab('form')}
                            className="bg-teal-600 text-white px-6 py-3 rounded-lg font-medium hover:bg-teal-700 transition-colors"
                          >
                            Submit Your First Ticket
                          </button>
                        </div>
                      ) : (
                        <div className="space-y-4">
                          {queries.map((query) => (
                            <motion.div
                              key={query.id}
                              className="bg-gray-50 rounded-lg p-6 border border-gray-200"
                              initial={{ opacity: 0, y: 20 }}
                              animate={{ opacity: 1, y: 0 }}
                              transition={{ duration: 0.3 }}
                            >
                              <div className="flex items-start justify-between mb-4">
                                <div className="flex items-center space-x-3">
                                  <span className={`px-3 py-1 rounded-full text-xs font-medium border ${getStatusColor(query.status)}`}>
                                    <div className="flex items-center space-x-1">
                                      {getStatusIcon(query.status)}
                                      <span>{query.status === 'responded' ? 'Answered' : 'Pending'}</span>
                                    </div>
                                  </span>
                                                                     <span className="text-sm text-gray-500">
                                     {new Date(query.created_at).toLocaleDateString('en-US', { 
                                       year: 'numeric', 
                                       month: 'short', 
                                       day: 'numeric' 
                                     })}
                                   </span>
                                </div>
                              </div>

                              <div className="mb-4">
                                <h4 className="font-semibold text-gray-900 mb-2">
                                  {query.subject}
                                </h4>
                                <p className="text-gray-700 text-sm leading-relaxed">
                                  {query.message}
                                </p>
                              </div>

                              {query.admin_response && (
                                <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-4">
                                  <div className="flex items-center space-x-2 mb-2">
                                    <FiCheckCircle className="w-4 h-4 text-green-600" />
                                    <span className="font-medium text-green-800">Admin Response</span>
                                  </div>
                                  <p className="text-green-700 text-sm leading-relaxed">
                                    {query.admin_response}
                                  </p>
                                                                     {query.response_date && (
                                     <p className="text-green-600 text-xs mt-2">
                                       Responded on {new Date(query.response_date).toLocaleDateString('en-US', { 
                                         year: 'numeric', 
                                         month: 'short', 
                                         day: 'numeric' 
                                       })}
                                     </p>
                                   )}
                                </div>
                              )}

                              <div className="text-xs text-gray-500">
                                Ticket #{query.id} • Submitted by {query.first_name} {query.last_name}
                              </div>
                            </motion.div>
                          ))}
                        </div>
                      )}
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            </motion.div>
          </div>

          {/* Sidebar */}
          <div className="lg:col-span-1">
            <motion.div 
              className="bg-white rounded-2xl shadow-xl p-6"
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ duration: 0.5, delay: 0.2 }}
            >
              <h3 className="text-lg font-semibold text-gray-900 mb-6">
                Contact Information
              </h3>

              <div className="space-y-4">
                <div className="flex items-start space-x-3">
                  <div className="w-10 h-10 bg-teal-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <FiContactPhone className="w-5 h-5 text-teal-600" />
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">Phone</p>
                    <p className="text-sm text-gray-600">+91-8637454428</p>
                  </div>
                </div>

                <div className="flex items-start space-x-3">
                  <div className="w-10 h-10 bg-teal-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <FiContactMail className="w-5 h-5 text-teal-600" />
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">Email</p>
                    <p className="text-sm text-gray-600">ashikali613@gmail.com</p>
                  </div>
                </div>

                <div className="flex items-start space-x-3">
                  <div className="w-10 h-10 bg-teal-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <FiContactMapPin className="w-5 h-5 text-teal-600" />
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">Address</p>
                    <p className="text-sm text-gray-600">
                      NPC PVT LTD, NO. 158, Murugan Kovil Street,<br />
                      Vanashakthi Nagar, Kolather, Chennai - 99.
                    </p>
                  </div>
                </div>
              </div>

              <div className="mt-8 p-4 bg-gradient-to-r from-teal-50 to-blue-50 rounded-lg border border-teal-200">
                <div className="flex items-center space-x-2 mb-3">
                  <FiZap className="w-5 h-5 text-teal-600" />
                  <h4 className="font-semibold text-gray-900">Quick Tips</h4>
                </div>
                <ul className="text-sm text-gray-600 space-y-2">
                  <li className="flex items-start space-x-2">
                    <FiCheckCircle className="w-4 h-4 text-green-500 mt-0.5 flex-shrink-0" />
                    <span>Provide detailed information for faster resolution</span>
                  </li>
                  <li className="flex items-start space-x-2">
                    <FiCheckCircle className="w-4 h-4 text-green-500 mt-0.5 flex-shrink-0" />
                    <span>Include relevant order numbers if applicable</span>
                  </li>
                  <li className="flex items-start space-x-2">
                    <FiCheckCircle className="w-4 h-4 text-green-500 mt-0.5 flex-shrink-0" />
                    <span>We typically respond within 24 hours</span>
                  </li>
                </ul>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RaiseTicket; 
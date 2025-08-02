import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { 
  FiArrowLeft,
  FiShare2,
  FiCopy,
  FiExternalLink,
  FiDownload,
  FiSmartphone,
  FiShield,
  FiStar,
  FiCheck,
  FiMessageSquare,
  FiHeart,
  FiZap,
  FiHome,
  FiUsers,
  FiAward,
  FiUser
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { apiService } from '../services/api';
import { API_BASE_URL } from '../config/api';
import toast from 'react-hot-toast';

interface UserProfile {
  customer_name?: string;
  email_id?: string;
  mobile_number?: string;
  profile_pic?: string;
}

const SharePage: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [copied, setCopied] = useState(false);
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

  // App sharing content (matching Flutter app)
  const appName = "NPC";
  const appDescription = "Professional Pest Control & Home Services at your doorstep";
  const shareMessage = `🏠 Transform your home with NPC Services! 

🐛 Expert Pest Control Solutions
🧹 Professional Cleaning Services  
🔧 Home Maintenance & Repairs
⚡ Quick & Reliable Service

Download now and get your first service at special rates!

📱 Android: https://play.google.com/store/apps/details?id=com.npc.services
🍎 iOS: https://apps.apple.com/app/npc-services/id123456789

#NPCServices #PestControl #HomeServices #CleaningServices`;

  const playStoreUrl = "https://play.google.com/store/apps/details?id=com.npc.services";
  const appStoreUrl = "https://apps.apple.com/app/npc-services/id123456789";
  const whatsappMessage = "Check out this amazing NPC Services app for all your home needs! 🏠✨ Download: ";

  const shareData = {
    title: 'NPC Professional Services',
    text: shareMessage,
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
          const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(whatsappMessage + window.location.origin)}`;
          window.open(whatsappUrl, '_blank');
          break;
        case 'copy':
          await navigator.clipboard.writeText(shareData.text + '\n\n' + shareData.url);
          setCopied(true);
          toast.success('Share content copied to clipboard!');
          setTimeout(() => setCopied(false), 2000);
          break;
      }
    } catch (error) {
      toast.error('Failed to share. Please try again.');
    }
  };

  const handleDownload = (platform: 'android' | 'ios') => {
    const url = platform === 'android' ? playStoreUrl : appStoreUrl;
    window.open(url, '_blank');
  };

  const features = [
    {
      icon: FiShield,
      title: 'Expert Pest Control',
      description: 'Professional solutions for all types of pests'
    },
    {
      icon: FiHome,
      title: 'Home Services',
      description: 'Comprehensive cleaning and maintenance'
    },
    {
      icon: FiZap,
      title: 'Quick Service',
      description: 'Same-day service availability'
    },
    {
      icon: FiAward,
      title: 'Quality Guaranteed',
      description: '100% satisfaction guarantee'
    }
  ];

  const benefits = [
    'Professional & certified technicians',
    'Eco-friendly solutions',
    'Flexible scheduling',
    'Transparent pricing',
    '24/7 customer support',
    'Special first-time user discounts',
    'Same-day service availability',
    '100% satisfaction guarantee'
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-teal-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b fixed top-0 left-0 right-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
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
                <h1 className="text-xl font-semibold text-gray-900">Share NPC</h1>
                <p className="text-sm text-gray-500">Spread the word</p>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              <div className="text-right">
                <p className="text-sm font-medium text-gray-900">Welcome back,</p>
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
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Left Column - App Preview */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6 }}
            className="space-y-6"
          >
            {/* App Preview Card */}
            <div className="bg-white rounded-2xl shadow-xl overflow-hidden">
              <div className="bg-gradient-to-r from-teal-600 to-teal-700 p-8 text-white">
                <div className="flex items-center space-x-4 mb-6">
                  <div className="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center">
                    <FiShield className="w-8 h-8" />
                  </div>
                  <div>
                    <h2 className="text-2xl font-bold">{appName}</h2>
                    <p className="text-teal-100">{appDescription}</p>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4 mb-6">
                  <div className="bg-white/10 rounded-lg p-4">
                    <div className="flex items-center space-x-2 mb-2">
                      <FiStar className="w-4 h-4 text-yellow-300" />
                      <span className="text-sm font-medium">4.8/5 Rating</span>
                    </div>
                    <p className="text-xs text-teal-100">500+ Reviews</p>
                  </div>
                  <div className="bg-white/10 rounded-lg p-4">
                    <div className="flex items-center space-x-2 mb-2">
                      <FiUsers className="w-4 h-4 text-teal-100" />
                      <span className="text-sm font-medium">10K+ Users</span>
                    </div>
                    <p className="text-xs text-teal-100">Trusted by many</p>
                  </div>
                </div>

                <div className="flex space-x-3">
                  <button
                    onClick={() => handleDownload('android')}
                    className="flex-1 bg-white text-teal-700 px-4 py-3 rounded-lg font-semibold hover:bg-gray-50 transition-colors flex items-center justify-center space-x-2"
                  >
                    <FiDownload className="w-4 h-4" />
                    <span>Android</span>
                  </button>
                  <button
                    onClick={() => handleDownload('ios')}
                    className="flex-1 bg-white text-teal-700 px-4 py-3 rounded-lg font-semibold hover:bg-gray-50 transition-colors flex items-center justify-center space-x-2"
                  >
                    <FiDownload className="w-4 h-4" />
                    <span>iOS</span>
                  </button>
                </div>
              </div>
            </div>

            {/* Features Grid */}
            <div className="grid grid-cols-2 gap-4">
              {features.map((feature, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.6, delay: index * 0.1 }}
                  className="bg-white rounded-xl p-4 shadow-sm hover:shadow-md transition-shadow"
                >
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 bg-teal-100 rounded-lg flex items-center justify-center">
                      <feature.icon className="w-5 h-5 text-teal-600" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900 text-sm">{feature.title}</h3>
                      <p className="text-xs text-gray-500">{feature.description}</p>
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          </motion.div>

          {/* Right Column - Share Options */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="space-y-6"
          >
            {/* Share Options Card */}
            <div className="bg-white rounded-2xl shadow-xl p-8">
              <div className="text-center mb-8">
                <div className="w-16 h-16 bg-teal-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <FiShare2 className="w-8 h-8 text-teal-600" />
                </div>
                <h2 className="text-2xl font-bold text-gray-900 mb-2">Share with Friends</h2>
                <p className="text-gray-600">Help others discover NPC Services</p>
              </div>

              <div className="space-y-4">
                {/* Native Share */}
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => handleShare('native')}
                  className="w-full bg-teal-600 text-white p-4 rounded-xl font-semibold hover:bg-teal-700 transition-colors flex items-center justify-center space-x-3"
                >
                  <FiShare2 className="w-5 h-5" />
                  <span>Share via System</span>
                </motion.button>

                {/* WhatsApp Share */}
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => handleShare('whatsapp')}
                  className="w-full bg-green-600 text-white p-4 rounded-xl font-semibold hover:bg-green-700 transition-colors flex items-center justify-center space-x-3"
                >
                  <FiMessageSquare className="w-5 h-5" />
                  <span>Share on WhatsApp</span>
                </motion.button>

                {/* Copy Link */}
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => handleShare('copy')}
                  className={`w-full p-4 rounded-xl font-semibold transition-colors flex items-center justify-center space-x-3 ${
                    copied 
                      ? 'bg-green-100 text-green-700 border-2 border-green-300' 
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200 border-2 border-gray-200'
                  }`}
                >
                  {copied ? (
                    <>
                      <FiCheck className="w-5 h-5" />
                      <span>Copied!</span>
                    </>
                  ) : (
                    <>
                      <FiCopy className="w-5 h-5" />
                      <span>Copy Link</span>
                    </>
                  )}
                </motion.button>
              </div>
            </div>

            {/* Benefits Card */}
            <div className="bg-gradient-to-br from-teal-50 to-teal-100 rounded-2xl p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center space-x-2">
                <FiHeart className="w-5 h-5 text-teal-600" />
                <span>Why Choose NPC?</span>
              </h3>
              <div className="space-y-3">
                {benefits.map((benefit, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.4, delay: index * 0.1 }}
                    className="flex items-center space-x-3"
                  >
                    <div className="w-2 h-2 bg-teal-600 rounded-full"></div>
                    <span className="text-sm text-gray-700">{benefit}</span>
                  </motion.div>
                ))}
              </div>
            </div>

            {/* Download Links */}
            <div className="bg-white rounded-2xl shadow-lg p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center space-x-2">
                <FiSmartphone className="w-5 h-5 text-teal-600" />
                <span>Download App</span>
              </h3>
              <div className="space-y-3">
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => handleDownload('android')}
                  className="w-full bg-gray-900 text-white p-4 rounded-xl font-semibold hover:bg-gray-800 transition-colors flex items-center justify-center space-x-3"
                >
                  <FiDownload className="w-5 h-5" />
                  <span>Download for Android</span>
                </motion.button>
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => handleDownload('ios')}
                  className="w-full bg-gray-900 text-white p-4 rounded-xl font-semibold hover:bg-gray-800 transition-colors flex items-center justify-center space-x-3"
                >
                  <FiDownload className="w-5 h-5" />
                  <span>Download for iOS</span>
                </motion.button>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Bottom CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="mt-12 text-center"
        >
          <div className="bg-white rounded-2xl shadow-lg p-8 max-w-2xl mx-auto">
            <h3 className="text-xl font-bold text-gray-900 mb-4">
              Ready to transform your home?
            </h3>
            <p className="text-gray-600 mb-6">
              Join thousands of satisfied customers who trust NPC for their home service needs.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <button
                onClick={() => navigate('/dashboard')}
                className="bg-teal-600 text-white px-8 py-3 rounded-xl font-semibold hover:bg-teal-700 transition-colors"
              >
                Book a Service
              </button>
              <button
                onClick={() => navigate('/contact')}
                className="bg-gray-100 text-gray-700 px-8 py-3 rounded-xl font-semibold hover:bg-gray-200 transition-colors"
              >
                Contact Us
              </button>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default SharePage; 
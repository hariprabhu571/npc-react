import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  FiArrowLeft, 
  FiShield, 
  FiInfo, 
  FiFolder, 
  FiShare2, 
  FiLock, 
  FiCheckCircle, 
  FiUsers, 
  FiRefreshCw, 
  FiMail, 
  FiPhone, 
  FiMapPin,
  FiChevronDown,
  FiChevronUp,
  FiEye,
  FiEyeOff,
  FiZap,
  FiAward,
  FiGlobe,
  FiHeart
} from 'react-icons/fi';
import { motion, AnimatePresence, useScroll, useTransform } from 'framer-motion';
import { useAuth } from '../context/AuthContext';
import CompanyLogo from '../components/CompanyLogo';

interface SectionProps {
  title: string;
  icon: React.ReactNode;
  content: string[];
  isExpanded: boolean;
  onToggle: () => void;
  index: number;
}

const Section: React.FC<SectionProps> = ({ title, icon, content, isExpanded, onToggle, index }) => (
  <motion.div
    initial={{ opacity: 0, y: 30, scale: 0.95 }}
    animate={{ opacity: 1, y: 0, scale: 1 }}
    transition={{ 
      duration: 0.6, 
      delay: index * 0.1,
      type: "spring",
      stiffness: 100
    }}
    whileHover={{ 
      scale: 1.02,
      transition: { duration: 0.2 }
    }}
    className="group relative"
  >
    {/* Background Glow Effect */}
    <div className="absolute inset-0 bg-gradient-to-r from-teal-500/5 to-blue-500/5 rounded-3xl blur-xl group-hover:blur-2xl transition-all duration-500"></div>
    
    <div className="relative bg-white/80 backdrop-blur-sm rounded-3xl shadow-xl border border-white/20 overflow-hidden">
      {/* Animated Border */}
      <div className="absolute inset-0 bg-gradient-to-r from-teal-500/20 via-blue-500/20 to-purple-500/20 rounded-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
      
      <button
        onClick={onToggle}
        className="relative w-full px-8 py-6 flex items-center justify-between hover:bg-gradient-to-r hover:from-teal-50/50 hover:to-blue-50/50 transition-all duration-300"
      >
        <div className="flex items-center space-x-6">
          <motion.div 
            className="w-14 h-14 bg-gradient-to-br from-teal-500 to-blue-600 rounded-2xl flex items-center justify-center text-white shadow-lg"
            whileHover={{ 
              rotate: 5,
              scale: 1.1,
              transition: { duration: 0.2 }
            }}
          >
            {icon}
          </motion.div>
          <div>
                         <h3 className="text-lg font-bold text-gray-900 group-hover:text-teal-700 transition-colors duration-300">
               {title}
             </h3>
             <p className="text-xs text-gray-500 mt-1">
               {isExpanded ? 'Click to collapse' : 'Click to expand'}
             </p>
          </div>
        </div>
        <motion.div 
          className="text-gray-400"
          animate={{ rotate: isExpanded ? 180 : 0 }}
          transition={{ duration: 0.3 }}
        >
          {isExpanded ? <FiChevronUp className="w-6 h-6" /> : <FiChevronDown className="w-6 h-6" />}
        </motion.div>
      </button>
      
      <AnimatePresence>
        {isExpanded && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ 
              duration: 0.4,
              ease: "easeInOut"
            }}
            className="overflow-hidden"
          >
            <div className="px-8 pb-8">
              <div className="space-y-4">
                {content.map((item, itemIndex) => (
                  <motion.div 
                    key={itemIndex} 
                    className="flex items-start space-x-4"
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: itemIndex * 0.1 }}
                  >
                    <div className="w-3 h-3 bg-gradient-to-r from-teal-500 to-blue-600 rounded-full mt-2 flex-shrink-0 shadow-sm"></div>
                                         <p className="text-gray-700 leading-relaxed text-sm">{item}</p>
                  </motion.div>
                ))}
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  </motion.div>
);

const PrivacyPolicy: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [expandedSections, setExpandedSections] = useState<{ [key: string]: boolean }>({
    'Information We Collect': true,
  });
  const [scrollY, setScrollY] = useState(0);

  const { scrollYProgress } = useScroll();
  const headerOpacity = useTransform(scrollYProgress, [0, 0.1], [1, 0.8]);
  const headerScale = useTransform(scrollYProgress, [0, 0.1], [1, 0.95]);

  useEffect(() => {
    const handleScroll = () => setScrollY(window.scrollY);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const toggleSection = (title: string) => {
    setExpandedSections(prev => ({
      ...prev,
      [title]: !prev[title]
    }));
  };

  const sections = [
    {
      title: 'Information We Collect',
      icon: <FiFolder className="w-6 h-6" />,
      content: [
        'Personal Information: Name, contact details, address, and payment information necessary to provide our pest control services.',
        'Service Information: Details about your property, pest issues, service history, and preferences.',
        'Technical Information: Device details, IP address, app usage patterns, and other analytics to improve our service.'
      ]
    },
    {
      title: 'How We Use Your Information',
      icon: <FiZap className="w-6 h-6" />,
      content: [
        'Provide and improve our pest control services',
        'Process payments and maintain service records',
        'Communicate with you about appointments, promotions, and service updates',
        'Analyze usage patterns to enhance user experience',
        'Comply with legal obligations and protect our rights'
      ]
    },
    {
      title: 'Information Sharing and Disclosure',
      icon: <FiShare2 className="w-6 h-6" />,
      content: [
        'Service Providers: We may share information with trusted third-party service providers who assist us in operating our business and servicing you.',
        'Business Transfers: If NPC Pest Control is acquired or merges with another company, your information may be transferred to the new owners.',
        'Legal Requirements: We may disclose information if required by law or to protect the rights, property, or safety of NPC Pest Control, our customers, or others.'
      ]
    },
    {
      title: 'Data Security',
      icon: <FiLock className="w-6 h-6" />,
      content: [
        'We implement industry-standard security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction.',
        'Despite our efforts, no method of transmission over the Internet or electronic storage is 100% secure. We cannot guarantee absolute security.'
      ]
    },
    {
      title: 'Your Rights',
      icon: <FiCheckCircle className="w-6 h-6" />,
      content: [
        'Access, correct, or delete your personal information',
        'Object to or restrict certain processing of your data',
        'Withdraw consent at any time where we rely on consent to process your information',
        'Request portability of your personal data where technically feasible'
      ]
    },
    {
      title: 'Children\'s Privacy',
      icon: <FiUsers className="w-6 h-6" />,
      content: [
        'Our services are not directed to individuals under 18 years of age. We do not knowingly collect personal information from children. If you believe we have collected personal information from a child, please contact us immediately.'
      ]
    },
    {
      title: 'Changes to This Policy',
      icon: <FiRefreshCw className="w-6 h-6" />,
      content: [
        'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
        'We recommend reviewing this Privacy Policy periodically for any changes.'
      ]
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-teal-50 relative overflow-hidden">
      {/* Animated Background Elements */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-20 left-10 w-72 h-72 bg-gradient-to-r from-teal-400/20 to-blue-400/20 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-20 right-10 w-96 h-96 bg-gradient-to-r from-blue-400/20 to-purple-400/20 rounded-full blur-3xl animate-pulse delay-1000"></div>
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-80 h-80 bg-gradient-to-r from-teal-300/10 to-blue-300/10 rounded-full blur-3xl animate-pulse delay-500"></div>
      </div>

      {/* Header */}
      <motion.header 
        style={{ opacity: headerOpacity, scale: headerScale }}
        className="relative z-10 bg-gradient-to-r from-teal-600 via-blue-600 to-purple-600 text-white overflow-hidden"
      >
        {/* Animated Header Background */}
        <div className="absolute inset-0">
          <div className="absolute inset-0 bg-gradient-to-r from-teal-600/90 via-blue-600/90 to-purple-600/90"></div>
          <div className="absolute top-0 left-0 w-full h-full opacity-30">
            <div className="absolute inset-0 bg-gradient-to-r from-white/5 to-transparent"></div>
            <div className="absolute inset-0 bg-gradient-to-b from-transparent to-white/5"></div>
          </div>
        </div>
        
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-24">
            <div className="flex items-center space-x-6">
              <motion.button
                onClick={() => navigate(-1)}
                className="p-3 text-white/80 hover:text-white transition-all duration-300 rounded-2xl hover:bg-white/10 backdrop-blur-sm"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
              >
                <FiArrowLeft className="w-6 h-6" />
              </motion.button>
              
              <motion.div 
                className="w-14 h-14 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center shadow-2xl"
                whileHover={{ rotate: 5, scale: 1.1 }}
                transition={{ duration: 0.3 }}
              >
                <img 
                  src="/images/logo-npc.png" 
                  alt="NPC Pest Control Logo"
                  className="w-10 h-10 object-contain"
                  onError={(e) => {
                    // Fallback to shield icon if logo fails to load
                    e.currentTarget.style.display = 'none';
                    e.currentTarget.nextElementSibling?.classList.remove('hidden');
                  }}
                />
                <FiShield className="w-8 h-8 text-white hidden" />
              </motion.div>
              
              <div>
                                 <motion.h1 
                   className="text-2xl font-bold bg-gradient-to-r from-white to-blue-100 bg-clip-text text-transparent"
                   initial={{ opacity: 0, y: 20 }}
                   animate={{ opacity: 1, y: 0 }}
                   transition={{ delay: 0.2 }}
                 >
                   Privacy Policy
                 </motion.h1>
                 <motion.p 
                   className="text-white/80 text-base"
                   initial={{ opacity: 0, y: 20 }}
                   animate={{ opacity: 1, y: 0 }}
                   transition={{ delay: 0.3 }}
                 >
                   Last Updated: April 11, 2025
                 </motion.p>
              </div>
            </div>
            
            <motion.div 
              className="text-right"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.4 }}
            >
              <p className="text-sm font-medium text-white/90">Welcome back,</p>
              <p className="text-lg font-semibold text-white">{user?.name || 'User'}</p>
            </motion.div>
          </div>
        </div>
      </motion.header>

      {/* Main Content */}
      <div className="relative z-10 max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="space-y-12"
        >
          {/* Hero Introduction Card */}
          <motion.div
            initial={{ opacity: 0, y: 30, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ delay: 0.5, duration: 0.8 }}
            className="relative group"
          >
            {/* Card Glow Effect */}
            <div className="absolute inset-0 bg-gradient-to-r from-teal-500/20 via-blue-500/20 to-purple-500/20 rounded-3xl blur-2xl group-hover:blur-3xl transition-all duration-700"></div>
            
            <div className="relative bg-white/90 backdrop-blur-xl rounded-3xl shadow-2xl p-10 border border-white/20">
              <div className="flex items-center space-x-6 mb-8">
                <motion.div 
                  className="w-16 h-16 bg-gradient-to-br from-teal-500 via-blue-600 to-purple-600 rounded-2xl flex items-center justify-center shadow-xl"
                  whileHover={{ 
                    rotate: 10,
                    scale: 1.1,
                    transition: { duration: 0.3 }
                  }}
                >
                  <FiHeart className="w-8 h-8 text-white" />
                </motion.div>
                <div>
                                   <h2 className="text-2xl font-bold bg-gradient-to-r from-teal-600 to-blue-600 bg-clip-text text-transparent">
                   Your Privacy Matters
                 </h2>
                 <p className="text-gray-600 text-base mt-2">We're committed to protecting your data</p>
                </div>
              </div>
              
                             <div className="max-w-none">
                 <p className="text-gray-700 leading-relaxed text-base mb-6">
                   At <span className="font-semibold text-teal-600">NPC Pest Control</span>, we value your privacy and are committed to protecting your personal information. 
                   This Privacy Policy explains how we collect, use, and safeguard your data when you use our services.
                 </p>
                 <p className="text-gray-700 leading-relaxed text-base">
                   By using our app and services, you agree to the terms outlined in this policy.
                 </p>
               </div>
            </div>
          </motion.div>

          {/* Policy Sections */}
          <div className="space-y-8">
            {sections.map((section, index) => (
              <Section
                key={section.title}
                title={section.title}
                icon={section.icon}
                content={section.content}
                isExpanded={expandedSections[section.title] || false}
                onToggle={() => toggleSection(section.title)}
                index={index}
              />
            ))}
          </div>

          {/* Enhanced Contact Section */}
          <motion.div
            initial={{ opacity: 0, y: 30, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ delay: 1, duration: 0.8 }}
            className="relative group"
          >
            {/* Contact Card Glow */}
            <div className="absolute inset-0 bg-gradient-to-r from-teal-500/30 via-blue-500/30 to-purple-500/30 rounded-3xl blur-2xl group-hover:blur-3xl transition-all duration-700"></div>
            
            <div className="relative bg-gradient-to-br from-teal-600 via-blue-700 to-purple-700 rounded-3xl shadow-2xl p-10 text-white overflow-hidden">
              {/* Background Pattern */}
              <div className="absolute inset-0 opacity-20">
                <div className="absolute inset-0 bg-gradient-to-r from-white/5 to-transparent"></div>
                <div className="absolute inset-0 bg-gradient-to-b from-transparent to-white/5"></div>
                <div className="absolute inset-0 bg-gradient-to-br from-white/3 to-transparent"></div>
              </div>
              
              <div className="relative z-10">
                <div className="flex items-center space-x-6 mb-8">
                  <motion.div 
                    className="w-16 h-16 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center shadow-xl"
                    whileHover={{ rotate: 5, scale: 1.1 }}
                    transition={{ duration: 0.3 }}
                  >
                    <FiGlobe className="w-8 h-8 text-white" />
                  </motion.div>
                  <div>
                                       <h2 className="text-2xl font-bold text-white">Get In Touch</h2>
                   <p className="text-white/80 text-base">Our privacy team is here to help</p>
                  </div>
                </div>
                
                                 <p className="text-white/90 text-base mb-8 leading-relaxed">
                   If you have any questions about this Privacy Policy or our data practices, please contact us:
                 </p>
                
                <div className="grid md:grid-cols-2 gap-8 mb-10">
                  <motion.div 
                    className="flex items-center space-x-4 p-4 bg-white/10 backdrop-blur-sm rounded-2xl"
                    whileHover={{ scale: 1.05, backgroundColor: "rgba(255,255,255,0.15)" }}
                    transition={{ duration: 0.3 }}
                  >
                    <FiMail className="w-6 h-6 text-white/80" />
                    <span className="text-white/90 font-medium">ashikali613@gmail.com</span>
                  </motion.div>
                  
                  <motion.div 
                    className="flex items-center space-x-4 p-4 bg-white/10 backdrop-blur-sm rounded-2xl"
                    whileHover={{ scale: 1.05, backgroundColor: "rgba(255,255,255,0.15)" }}
                    transition={{ duration: 0.3 }}
                  >
                    <FiPhone className="w-6 h-6 text-white/80" />
                    <span className="text-white/90 font-medium">+91 86374 54428</span>
                  </motion.div>
                  
                  <motion.div 
                    className="flex items-start space-x-4 p-4 bg-white/10 backdrop-blur-sm rounded-2xl md:col-span-2"
                    whileHover={{ scale: 1.02, backgroundColor: "rgba(255,255,255,0.15)" }}
                    transition={{ duration: 0.3 }}
                  >
                    <FiMapPin className="w-6 h-6 text-white/80 mt-1" />
                    <span className="text-white/90 font-medium">
                      NPC PVT LTD, NO. 158, Murugan Kovil Street,<br />
                      Vanashakthi Nagar, Kolather, Chennai - 99
                    </span>
                  </motion.div>
                </div>
                
                <div className="flex flex-col sm:flex-row gap-6">
                  <motion.button
                    whileHover={{ scale: 1.05, y: -2 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => window.open('mailto:ashikali613@gmail.com', '_blank')}
                    className="flex-1 bg-white text-teal-600 font-bold py-4 px-8 rounded-2xl hover:bg-gray-50 transition-all duration-300 flex items-center justify-center space-x-3 shadow-xl"
                  >
                    <FiMail className="w-6 h-6" />
                    <span>Email Us</span>
                  </motion.button>
                  
                  <motion.button
                    whileHover={{ scale: 1.05, y: -2 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => window.open('tel:+918637454428', '_blank')}
                    className="flex-1 bg-transparent border-2 border-white text-white font-bold py-4 px-8 rounded-2xl hover:bg-white/10 transition-all duration-300 flex items-center justify-center space-x-3 backdrop-blur-sm"
                  >
                    <FiPhone className="w-6 h-6" />
                    <span>Call Us</span>
                  </motion.button>
                </div>
              </div>
            </div>
          </motion.div>

          {/* Footer Note */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.2 }}
            className="text-center"
          >
            <div className="bg-white/80 backdrop-blur-sm rounded-2xl p-8 shadow-xl border border-white/20">
              <motion.div 
                className="w-16 h-16 bg-gradient-to-br from-teal-500 to-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg"
                whileHover={{ rotate: 5, scale: 1.1 }}
                transition={{ duration: 0.3 }}
              >
                <FiAward className="w-8 h-8 text-white" />
              </motion.div>
                             <p className="text-gray-600 text-base leading-relaxed">
                 This Privacy Policy is effective as of <span className="font-semibold text-teal-600">April 11, 2025</span> and will remain in effect except with respect to any changes in its provisions in the future.
               </p>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </div>
  );
};

export default PrivacyPolicy; 
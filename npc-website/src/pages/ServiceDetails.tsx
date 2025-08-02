import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
// @ts-ignore
import html2canvas from 'html2canvas';
// @ts-ignore
import jsPDF from 'jspdf';
import { 
  FiShield, 
  FiArrowLeft, 
  FiCalendar, 
  FiClock, 
  FiMapPin, 
  FiCheck, 
  FiPlus, 
  FiMinus,
  FiStar,
  FiUsers,
  FiAward,
  FiShield as FiShieldIcon,
  FiCheckCircle,
  FiAlertCircle,
  FiInfo,
  FiTruck,
  FiClock as FiTimeIcon,
  FiMapPin as FiLocationIcon,
  FiPhone,
  FiMail,
  FiCreditCard,
  FiDollarSign,
  FiPercent,
  FiGift,
  FiZap,
  FiHeart,
  FiEye,
  FiEyeOff,
  FiShare2,
  FiShoppingCart,
  FiUser,
  FiLogOut
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { Service } from '../types';
import { apiService } from '../services/api';
import { API_ENDPOINTS, API_BASE_URL } from '../config/api';
import { useQuery } from 'react-query';
import toast from 'react-hot-toast';

// Helper function to get image URL
const getImageUrl = (imagePath?: string): string | null => {
  if (!imagePath) return null;
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('data:')) {
    return imagePath;
  }
  return `${API_BASE_URL}${imagePath.replace(/^\/+/, '')}`;
};



// Local interfaces for this component
interface ServiceType {
  service_type_id: number;
  service_type_name: string;
  pricing: PricingField[];
}

interface PricingField {
  id: string;
  room_size: string;
  price: number;
}

interface CartItem {
  service_type_id: number;
  service_type_name: string;
  room_size: string;
  price: number;
  quantity: number;
}

interface BookingResponse {
  status: string;
  message?: string;
  booking_id?: string;
}

interface RazorpayOptions {
  key: string;
  amount: number;
  name: string;
  description: string;
  prefill: {
    contact?: string;
    email?: string;
  };
  external?: {
    wallets: string[];
  };
  handler: (response: RazorpayResponse) => void;
  modal?: {
    ondismiss?: () => void;
  };
}

interface RazorpayResponse {
  razorpay_payment_id: string;
  razorpay_order_id: string;
  razorpay_signature: string;
}

const ServiceDetails: React.FC = () => {
  const { serviceName } = useParams<{ serviceName: string }>();
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  
  console.log('ServiceDetails component - serviceName:', serviceName);
  const [currentStep, setCurrentStep] = useState<'types' | 'details' | 'confirmation'>('types');
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [selectedTime, setSelectedTime] = useState('');
  const [address, setAddress] = useState('');
  const [notes, setNotes] = useState('');
  const [isBooking, setIsBooking] = useState(false);
  const [cartItems, setCartItems] = useState<CartItem[]>([]);
  const [serviceTypes, setServiceTypes] = useState<ServiceType[]>([]);
  const [serviceInfo, setServiceInfo] = useState<any>(null);
  
  // New state variables for missing features
  const [couponCode, setCouponCode] = useState('');
  const [isCouponApplied, setIsCouponApplied] = useState(false);
  const [appliedCouponCode, setAppliedCouponCode] = useState('');
  const [couponDiscount, setCouponDiscount] = useState(0);
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState('cash');
  const [agreedToTerms, setAgreedToTerms] = useState(false);
  
  // Enhanced UI state
  const [showServiceDetails, setShowServiceDetails] = useState(false);
  const [selectedServiceType, setSelectedServiceType] = useState<ServiceType | null>(null);
  const [showBenefits, setShowBenefits] = useState(false);
  const [showProcess, setShowProcess] = useState(false);
  const [showTestimonials, setShowTestimonials] = useState(false);
  const [activeTab, setActiveTab] = useState<'overview' | 'details' | 'reviews'>('overview');
  
  // Profile-related state
  const [userProfile, setUserProfile] = useState<{ customer_name?: string; profile_pic?: string }>({});
  const [showProfileDropdown, setShowProfileDropdown] = useState(false);
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

  // Profile dropdown handlers
  const handleProfileClick = () => {
    setShowProfileDropdown(!showProfileDropdown);
  };

  const handleProfileNavigation = () => {
    navigate('/profile');
    setShowProfileDropdown(false);
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  // Fetch service types
  const { data: serviceTypesData, isLoading: typesLoading, refetch } = useQuery(
    ['serviceTypes', serviceName],
    () => apiService.get<{ status: string, data: ServiceType[], service_info: any, message: string, total_service_types: number }>(`${API_ENDPOINTS.GET_USER_SERVICE_DETAILS}?service_name=${encodeURIComponent(serviceName || '')}`),
    {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 0, // Always fetch fresh data
      onError: (error: any) => {
        console.error('Service types fetch error:', error);
        toast.error('Failed to load service types');
      },
      onSuccess: (data: any) => {
        console.log('API call successful:', data);
        console.log('Full API response:', JSON.stringify(data, null, 2));
      }
    }
  );

  useEffect(() => {
    console.log('ServiceTypesData received:', serviceTypesData);
    const serviceTypesDataAny = serviceTypesData as any;
    if (serviceTypesDataAny?.data) {
      console.log('Setting service types:', serviceTypesDataAny.data);
      console.log('Setting service info:', serviceTypesDataAny.service_info);
      console.log('Service image path:', serviceTypesDataAny.service_info?.image_path);
      console.log('Image URL:', getImageUrl(serviceTypesDataAny.service_info?.image_path));
      console.log('API_BASE_URL:', API_BASE_URL);
      setServiceTypes(serviceTypesDataAny.data || []);
      setServiceInfo(serviceTypesDataAny.service_info);
    }
  }, [serviceTypesData]);

  // Check if Razorpay is loaded
  useEffect(() => {
    const checkRazorpay = () => {
      if (typeof window !== 'undefined') {
        if ((window as any).Razorpay) {
          console.log('✅ Razorpay script loaded successfully');
        } else {
          console.error('❌ Razorpay script not found');
        }
      }
    };

    // Check immediately
    checkRazorpay();

    // Check again after a short delay in case script loads later
    const timer = setTimeout(checkRazorpay, 1000);
    return () => clearTimeout(timer);
  }, []);

  // Available time slots
  const timeSlots = [
    '9:00 AM - 11:00 AM',
    '11:00 AM - 1:00 PM', 
    '2:00 PM - 4:00 PM',
    '4:00 PM - 6:00 PM',
    '6:00 PM - 8:00 PM'
  ];

  // Get minimum date (today)
  const today = new Date().toISOString().split('T')[0];

  // Enhanced service information
  const serviceBenefits = [
    {
      icon: FiShieldIcon,
      title: "Professional Expertise",
      description: "Certified technicians with years of experience in pest control"
    },
    {
      icon: FiAward,
      title: "Quality Guarantee",
      description: "90-day warranty on all treatments with follow-up support"
    },
    {
      icon: FiZap,
      title: "Quick Service",
      description: "Same-day service available in most areas"
    },
    {
      icon: FiHeart,
      title: "Safe Chemicals",
      description: "HACCP certified chemicals safe for your family and pets"
    }
  ];

  const serviceProcess = [
    {
      step: 1,
      title: "Thorough Inspection",
      description: "Our expert conducts a comprehensive inspection of your space to identify all pest entry points and breeding areas.",
      icon: FiEye
    },
    {
      step: 2,
      title: "Customized Treatment",
      description: "Tailored treatment plan using advanced techniques and safe chemicals based on inspection findings.",
      icon: FiShieldIcon
    },
    {
      step: 3,
      title: "Follow-up Service",
      description: "Second visit after 2 weeks to ensure complete elimination and prevent future infestations.",
      icon: FiCheckCircle
    }
  ];

  const testimonials = [
    {
      name: "Sarah M.",
      rating: 5,
      comment: "Excellent service! The technician was professional and thorough. No more pests in our home.",
      date: "2 days ago"
    },
    {
      name: "Rajesh K.",
      rating: 5,
      comment: "Very satisfied with the pest control service. The team was punctual and the treatment was effective.",
      date: "1 week ago"
    },
    {
      name: "Priya S.",
      rating: 4,
      comment: "Good service and reasonable pricing. Would definitely recommend to others.",
      date: "2 weeks ago"
    }
  ];

  const addToCart = (serviceType: ServiceType, pricingField: PricingField) => {
    const cartItemKey = `${serviceType.service_type_id}_${pricingField.id}`;
    console.log('Adding to cart:', { serviceType, pricingField });
    setCartItems(prev => {
      const existing = prev.find(item => 
        item.service_type_id === serviceType.service_type_id && 
        item.room_size === pricingField.room_size
      );
      if (existing) {
        const updated = prev.map(item => 
          item.service_type_id === serviceType.service_type_id && item.room_size === pricingField.room_size
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
        console.log('Updated cart items:', updated);
        return updated;
      } else {
        const newItem = { 
          service_type_id: serviceType.service_type_id,
          service_type_name: serviceType.service_type_name,
          room_size: pricingField.room_size,
          price: pricingField.price,
          quantity: 1 
        };
        const updated = [...prev, newItem];
        console.log('Added new cart item:', newItem);
        console.log('Updated cart items:', updated);
        return updated;
      }
    });
  };

  const addAllToCart = () => {
    if (cartItems.length === 0) {
      toast.error('Please select at least one service');
      return;
    }

    // Get the global cart from localStorage
    const globalCart = JSON.parse(localStorage.getItem('globalCart') || '[]');
    
    // Add all current cart items to global cart
    const updatedGlobalCart = [...globalCart];
    
    cartItems.forEach(item => {
      const existingItem = updatedGlobalCart.find(
        globalItem => globalItem.service_type_id === item.service_type_id && globalItem.room_size === item.room_size
      );

      if (existingItem) {
        existingItem.quantity += item.quantity;
      } else {
        updatedGlobalCart.push({
          ...item,
          service_name: serviceInfo.service_name,
          service_image: serviceInfo.image_path
        });
      }
    });

    // Save to localStorage
    localStorage.setItem('globalCart', JSON.stringify(updatedGlobalCart));
    
    // Clear the current cart
    setCartItems([]);
    
    toast.success('All services added to cart!');
    navigate('/cart');
  };

  const removeFromCart = (serviceTypeId: number, roomSize: string) => {
    console.log('Removing from cart:', { serviceTypeId, roomSize });
    setCartItems(prev => {
      const existing = prev.find(item => 
        item.service_type_id === serviceTypeId && item.room_size === roomSize
      );
      if (existing && existing.quantity > 1) {
        const updated = prev.map(item => 
          item.service_type_id === serviceTypeId && item.room_size === roomSize
            ? { ...item, quantity: item.quantity - 1 }
            : item
        );
        console.log('Updated cart items (decreased quantity):', updated);
        return updated;
      } else {
        const updated = prev.filter(item => 
          !(item.service_type_id === serviceTypeId && item.room_size === roomSize)
        );
        console.log('Updated cart items (removed item):', updated);
        return updated;
      }
    });
  };

  const getCartItemQuantity = (serviceTypeId: number, roomSize: string) => {
    const item = cartItems.find(item => 
      item.service_type_id === serviceTypeId && item.room_size === roomSize
    );
    return item ? item.quantity : 0;
  };

  const calculateSubtotal = () => {
    const subtotal = cartItems.reduce((total, item) => total + (item.price * item.quantity), 0);
    console.log('Subtotal calculation:', { cartItems, subtotal });
    return subtotal;
  };

  const calculateDiscount = () => {
    const subtotal = calculateSubtotal();
    const discount = Math.round(subtotal * 0.15); // 15% discount
    console.log('Discount calculation:', { subtotal, discount });
    return discount;
  };

  const calculateTotal = () => {
    const subtotal = calculateSubtotal();
    const discount = calculateDiscount();
    const total = subtotal - discount - couponDiscount;
    const finalTotal = Math.max(0, total); // Ensure total is never negative
    console.log('Total calculation:', { subtotal, discount, couponDiscount, total, finalTotal });
    return finalTotal;
  };

  const applyCoupon = async () => {
    if (!couponCode.trim()) {
      toast.error('Please enter a coupon code');
      return;
    }
    
    try {
      const orderAmount = calculateSubtotal();
      const response = await apiService.get(`${API_ENDPOINTS.CREATE_BOOKING}?action=validate_coupon&coupon_code=${encodeURIComponent(couponCode.trim())}&order_amount=${orderAmount}`);
      
      const responseData = response as any;
      
      if (responseData?.status === 'success') {
        setCouponDiscount(responseData.discount_amount);
        setAppliedCouponCode(couponCode.trim());
        setIsCouponApplied(true);
        toast.success(responseData.message || 'Coupon applied successfully!');
      } else {
        toast.error(responseData?.message || 'Invalid coupon code');
      }
    } catch (error) {
      console.error('Coupon validation error:', error);
      toast.error('Failed to validate coupon');
    }
  };

  const removeCoupon = () => {
    setCouponDiscount(0);
    setAppliedCouponCode('');
    setIsCouponApplied(false);
    setCouponCode('');
    toast.success('Coupon removed');
  };

  const handleProceedToDetails = () => {
    if (cartItems.length === 0) {
      toast.error('Please select at least one service type');
      return;
    }
    setCurrentStep('details');
  };

  const handleProceedToConfirmation = () => {
    if (!selectedDate || !selectedTime || !address.trim()) {
      toast.error('Please fill in all required fields');
      return;
    }
    if (!agreedToTerms) {
      toast.error('Please agree to terms and conditions');
      return;
    }
    setCurrentStep('confirmation');
  };

  const handleBooking = async () => {
    console.log('🔵 handleBooking called');
    console.log('🔵 Payment method:', selectedPaymentMethod);
    console.log('🔵 Agreed to terms:', agreedToTerms);
    
    if (!agreedToTerms) {
      toast.error('Please agree to the terms and conditions');
      return;
    }

    if (selectedPaymentMethod === 'online') {
      console.log('🔵 Proceeding with online payment');
      initiateRazorpayPayment();
    } else {
      console.log('🔵 Proceeding with cash payment');
      createBooking();
    }
  };

  const initiateRazorpayPayment = () => {
    console.log('🔵 Initiating Razorpay payment...');
    console.log('Total amount:', calculateTotal());
    console.log('Amount in paise:', Math.round(calculateTotal() * 100));
    
    // Validate amount
    const amount = calculateTotal();
    if (amount <= 0) {
      console.error('❌ Invalid amount:', amount);
      toast.error('Invalid amount. Please select services.');
      return;
    }
    
    const amountInPaise = Math.round(amount * 100);
    if (amountInPaise <= 0) {
      console.error('❌ Invalid amount in paise:', amountInPaise);
      toast.error('Invalid amount. Please select services.');
      return;
    }
    
    // Check if Razorpay is loaded
    if (typeof window === 'undefined' || !(window as any).Razorpay) {
      console.error('❌ Razorpay script not loaded, attempting to load...');
      
      // Try to load Razorpay script dynamically
      const script = document.createElement('script');
      script.src = 'https://checkout.razorpay.com/v1/checkout.js';
      script.onload = () => {
        console.log('✅ Razorpay script loaded dynamically');
        // Retry after script loads
        setTimeout(() => {
          initiateRazorpayPayment();
        }, 100);
      };
      script.onerror = () => {
        console.error('❌ Failed to load Razorpay script');
        toast.error('Payment gateway not available. Please refresh the page.');
      };
      document.head.appendChild(script);
      return;
    }

    const options: RazorpayOptions = {
      key: 'rzp_test_TGcPYUXCQVm6fX', // Same key as Flutter app
      amount: amountInPaise, // Amount in paise
      name: 'NPC Services',
      description: serviceName || 'Service Booking',
      prefill: {
        contact: '',
        email: ''
      },
      external: {
        wallets: ['paytm']
      },
      handler: (response: RazorpayResponse) => {
        console.log('✅ Payment successful:', response);
        handlePaymentSuccess(response);
      },
      modal: {
        ondismiss: () => {
          console.log('❌ Payment cancelled by user');
          toast.error('Payment cancelled');
        }
      }
    };

    console.log('🔵 Razorpay options:', options);

    try {
      const razorpay = new (window as any).Razorpay(options);
      console.log('🔵 Razorpay instance created:', razorpay);
      razorpay.open();
      console.log('🔵 Razorpay modal opened');
    } catch (error) {
      console.error('❌ Razorpay error:', error);
      toast.error('Failed to initialize payment. Please try again.');
    }
  };

  const handlePaymentSuccess = (response: RazorpayResponse) => {
    console.log('Payment successful:', response);
    createBooking(response.razorpay_payment_id, response.razorpay_order_id);
  };

  const createBooking = async (razorpayPaymentId?: string, razorpayOrderId?: string) => {
    setIsBooking(true);

    try {
      const bookingData = {
        action: 'create_booking',
        service_name: serviceName,
        service_date: selectedDate ? selectedDate.toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
        time_slot: selectedTime,
        service_address: address,
        special_notes: notes,
        subtotal: calculateSubtotal(),
        discount_amount: calculateDiscount(),
        coupon_code: isCouponApplied ? appliedCouponCode : null,
        coupon_discount: couponDiscount,
        total_amount: calculateTotal(),
        payment_method: selectedPaymentMethod,
        cart_items: cartItems,
        razorpay_order_id: razorpayOrderId
      };

      console.log('Creating booking with data:', bookingData);

      const response = await apiService.post(API_ENDPOINTS.CREATE_BOOKING, bookingData);
      const responseData = (response.data || response) as BookingResponse;

      if (responseData.status === 'success') {
        const bookingId = responseData.booking_id;
        console.log('✅ Booking created successfully with ID:', bookingId);

        // Update payment status if Razorpay payment
        if (razorpayPaymentId && bookingId) {
          await updatePaymentStatus(bookingId, razorpayPaymentId);
        }

        // Fetch user profile to get the correct name
        let userProfile = null;
        try {
          const profileResponse = await apiService.getProfile();
          if (profileResponse.status === 'success' && profileResponse.data) {
            userProfile = profileResponse.data;
          }
        } catch (error) {
          console.error('Error fetching user profile:', error);
        }

        // Create booking object for invoice
        const bookingData = {
          booking_id: bookingId,
          service_name: serviceName,
          service_date: selectedDate ? selectedDate.toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
          service_time: selectedTime,
          address: address,
          special_notes: notes,
          item_total: calculateSubtotal(),
          discount: calculateDiscount() + couponDiscount, // Include both regular discount and coupon discount
          taxes: 0, // You can calculate taxes if needed
          total_amount: calculateTotal(),
          payment_status: razorpayPaymentId ? 'paid' : 'pending',
          payment_mode: selectedPaymentMethod,
          payment_id: razorpayPaymentId,
          status: 'confirmed',
          created_at: new Date().toISOString(),
          booking_date: new Date().toISOString().split('T')[0],
          cart_items: cartItems // Include cart items for sub-services
        };

        // Create invoice data with actual user profile data
        const invoiceData = {
          booking: bookingData,
          user: {
            name: userProfile?.customer_name || user?.name || 'Customer',
            email: userProfile?.email_id || user?.email || '',
            phone: userProfile?.mobile_number || user?.mobile || '',
            address: address
          }
        };

        console.log('ServiceDetails: Created invoice data:', invoiceData);

        // Store invoice data in localStorage first
        localStorage.setItem('invoiceData', JSON.stringify(invoiceData));
        console.log('ServiceDetails: Stored invoice data in localStorage');
        
        // Also store a timestamp to ensure fresh data
        localStorage.setItem('invoiceDataTimestamp', Date.now().toString());
        
        // Open invoice page in new tab
        const invoiceUrl = `/invoice/${bookingId}`;
        const newWindow = window.open(invoiceUrl, '_blank');
        
        if (!newWindow) {
          console.warn('Popup blocked. Invoice page could not be opened.');
          toast.error('Please allow popups to view the invoice');
        }
        
        // Generate PDF and send invoice email with attachment
        try {
          console.log('ServiceDetails: Generating PDF for invoice...');
          const pdfBase64 = await generateInvoicePDF(invoiceData);
          console.log('ServiceDetails: PDF generated successfully');
          
          console.log('ServiceDetails: Sending invoice email with PDF attachment...');
          const emailSent = await sendInvoiceEmailWithPDF(invoiceData, pdfBase64);
          
          if (emailSent) {
            toast.success('Booking created successfully! Invoice email with PDF attachment sent to your email address.', {
              duration: 4000,
              style: {
                background: '#d1fae5',
                color: '#065f46',
                border: '1px solid #10b981'
              }
            });
          } else {
            toast.success('Booking created successfully! Invoice will be available in your bookings.', {
              duration: 4000,
              style: {
                background: '#d1fae5',
                color: '#065f46',
                border: '1px solid #10b981'
              }
            });
          }
        } catch (emailError) {
          console.error('ServiceDetails: PDF generation or email sending failed:', emailError);
          toast.success('Booking created successfully! Invoice will be available in your bookings.', {
            duration: 4000,
            style: {
              background: '#d1fae5',
              color: '#065f46',
              border: '1px solid #10b981'
            }
          });
        }
        
        // Redirect to bookings page
        navigate('/bookings');
      } else {
        toast.error(responseData.message || 'Booking creation failed');
      }
    } catch (error) {
      console.error('Booking error:', error);
      toast.error('Failed to create booking');
    } finally {
      setIsBooking(false);
    }
  };

  const updatePaymentStatus = async (bookingId: string, razorpayPaymentId: string) => {
    try {
      const requestBody = {
        action: 'update_payment',
        booking_id: bookingId,
        payment_status: 'paid',
        razorpay_payment_id: razorpayPaymentId
      };

      console.log('Updating payment status:', requestBody);

      const response = await apiService.post(API_ENDPOINTS.CREATE_BOOKING, requestBody);
      const responseData = response as any;

      if (responseData?.status === 'success') {
        console.log('✅ Payment status updated successfully');
      } else {
        console.log('❌ Payment update failed:', responseData?.message);
      }
    } catch (error) {
      console.error('Payment status update error:', error);
      // Don't fail the booking for payment update issues
    }
  };

  // Function to generate PDF using frontend's exact format
  const generateInvoicePDF = async (invoiceData: any): Promise<string> => {
    try {
      // Create a temporary div to render the invoice
      const tempDiv = document.createElement('div');
      tempDiv.style.position = 'absolute';
      tempDiv.style.left = '-9999px';
      tempDiv.style.top = '0';
      tempDiv.style.width = '800px';
      tempDiv.style.backgroundColor = 'white';
      tempDiv.style.padding = '40px';
      tempDiv.style.fontFamily = 'Arial, sans-serif';
      tempDiv.style.fontSize = '14px';
      tempDiv.style.lineHeight = '1.6';
      tempDiv.style.color = '#333';
      
      // Generate the invoice HTML content - matching InvoicePage.tsx structure exactly
      const invoiceHTML = `
        <div style="max-width: 800px; margin: 0 auto; background: white; padding: 32px; font-family: Arial, sans-serif; color: #333;">
          <!-- Header -->
          <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 32px;">
            <div>
              <div style="display: flex; align-items: center; margin-bottom: 16px;">
                <div style="width: 48px; height: 48px; background: #0d9488; border-radius: 8px; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0;">
                  <img src="/images/logo-npc.png" alt="NPC Pest Control Logo" style="width: 32px; height: 32px; object-fit: contain; display: block; max-width: 100%; height: auto;">
                </div>
                <div style="display: flex; flex-direction: column; justify-content: center; margin-left: 12px;">
                  <h1 style="margin: 0; line-height: 1.2; font-size: 24px; font-weight: bold; color: #111827;">NPC Pest Control</h1>
                  <p style="margin: 0; line-height: 1.2; color: #6b7280;">Professional Services</p>
                </div>
              </div>
              <div style="font-size: 14px; color: #6b7280;">
                <p style="margin: 4px 0;">NPC PVT LTD, NO. 158, Murugan Kovil Street</p>
                <p style="margin: 4px 0;">Vanashakthi Nagar, Kolather, Chennai - 99</p>
                <p style="margin: 4px 0;">Phone: +91 86374 54428</p>
                <p style="margin: 4px 0;">Email: ashikali613@gmail.com</p>
              </div>
            </div>
            
            <div style="text-align: right;">
              <h2 style="margin: 0 0 8px 0; font-size: 30px; font-weight: bold; color: #111827;">INVOICE</h2>
              <div style="font-size: 14px; color: #6b7280;">
                <p style="margin: 4px 0;"><strong>Invoice Date:</strong> ${new Date().toLocaleDateString()}</p>
                <p style="margin: 4px 0;"><strong>Invoice #:</strong> ${invoiceData.booking.booking_id}</p>
                <div style="display: flex; align-items: center; margin-top: 8px;">
                  <span style="margin-right: 8px;"><strong>Status:</strong></span>
                  <span style="color: #111827; font-weight: 500;">
                    ${invoiceData.booking.payment_status.charAt(0).toUpperCase() + invoiceData.booking.payment_status.slice(1)}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Customer Information -->
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 32px; margin-bottom: 32px;">
            <div>
              <h3 style="margin: 0 0 12px 0; font-size: 18px; font-weight: 600; color: #111827;">Bill To:</h3>
              <div style="font-size: 14px; color: #374151;">
                <p style="margin: 4px 0; font-weight: 600;">${invoiceData.user.name}</p>
                <p style="margin: 4px 0;">${invoiceData.user.email}</p>
                <p style="margin: 4px 0;">${invoiceData.user.phone}</p>
                <p style="margin: 8px 0 0 0;">${invoiceData.user.address}</p>
              </div>
            </div>
            
            <div>
              <h3 style="margin: 0 0 12px 0; font-size: 18px; font-weight: 600; color: #111827;">Service Details:</h3>
              <div style="font-size: 14px; color: #374151;">
                <div style="display: flex; align-items: center; margin-bottom: 4px;">
                  <span style="margin-right: 8px;">📅</span>
                  <span><strong>Service Date:</strong> ${new Date(invoiceData.booking.service_date).toLocaleDateString()}</span>
                </div>
                <div style="display: flex; align-items: center; margin-bottom: 4px;">
                  <span style="margin-right: 8px;">🕐</span>
                  <span><strong>Time Slot:</strong> ${invoiceData.booking.service_time}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Service Items -->
          <div style="margin-bottom: 32px;">
            <h3 style="margin: 0 0 16px 0; font-size: 18px; font-weight: 600; color: #111827;">Service Details</h3>
            <div style="border: 1px solid #e5e7eb; border-radius: 8px; overflow: hidden;">
              <table style="width: 100%; border-collapse: collapse;">
                <thead style="background: #f9fafb;">
                  <tr>
                    <th style="padding: 24px 24px 12px 24px; text-align: left; font-size: 12px; font-weight: 500; color: #6b7280; text-transform: uppercase; letter-spacing: 0.05em;">
                      Service
                    </th>
                    <th style="padding: 24px 24px 12px 24px; text-align: left; font-size: 12px; font-weight: 500; color: #6b7280; text-transform: uppercase; letter-spacing: 0.05em;">
                      Description
                    </th>
                    <th style="padding: 24px 24px 12px 24px; text-align: right; font-size: 12px; font-weight: 500; color: #6b7280; text-transform: uppercase; letter-spacing: 0.05em;">
                      Amount
                    </th>
                  </tr>
                </thead>
                <tbody style="background: white;">
                  <!-- Main Service -->
                  <tr>
                    <td style="padding: 16px 24px; font-size: 14px; font-weight: 500; color: #111827; white-space: nowrap;">
                      ${invoiceData.booking.service_name}
                    </td>
                    <td style="padding: 16px 24px; font-size: 14px; color: #6b7280;">
                      ${invoiceData.booking.service_description || 'Professional pest control service'}
                    </td>
                    <td style="padding: 16px 24px; font-size: 14px; color: #111827; text-align: right; white-space: nowrap;">
                      -
                    </td>
                  </tr>
                  
                  <!-- Sub-services -->
                  ${invoiceData.booking.cart_items && invoiceData.booking.cart_items.length > 0 ? 
                    invoiceData.booking.cart_items.map((item: any) => `
                      <tr style="background: #f9fafb;">
                        <td style="padding: 8px 24px; font-size: 14px; font-weight: 500; color: #111827; white-space: nowrap; padding-left: 48px;">
                          • ${item.service_type_name} - ${item.room_size}
                        </td>
                        <td style="padding: 8px 24px; font-size: 14px; color: #6b7280;">
                          Quantity: ${item.quantity} × ₹${item.price}
                        </td>
                        <td style="padding: 8px 24px; font-size: 14px; color: #111827; text-align: right; white-space: nowrap;">
                          ₹${item.price * item.quantity}
                        </td>
                      </tr>
                    `).join('') : 
                    `<tr style="background: #f9fafb;">
                      <td style="padding: 8px 24px; font-size: 14px; font-weight: 500; color: #111827; white-space: nowrap; padding-left: 48px;">
                        • ${invoiceData.booking.service_name}
                      </td>
                      <td style="padding: 8px 24px; font-size: 14px; color: #6b7280;">
                        Professional pest control service
                      </td>
                      <td style="padding: 8px 24px; font-size: 14px; color: #111827; text-align: right; white-space: nowrap;">
                        ₹${invoiceData.booking.item_total}
                      </td>
                    </tr>`
                  }
                </tbody>
              </table>
            </div>
          </div>

          <!-- Payment Summary -->
          <div style="display: flex; justify-content: flex-end;">
            <div style="width: 320px;">
              <div style="background: #f9fafb; border-radius: 8px; padding: 24px;">
                <h3 style="margin: 0 0 16px 0; font-size: 18px; font-weight: 600; color: #111827;">Payment Summary</h3>
                <div style="margin-bottom: 12px;">
                  <div style="display: flex; justify-content: space-between; font-size: 14px; margin-bottom: 12px;">
                    <span style="color: #6b7280;">Item Total:</span>
                    <span style="color: #111827;">₹${invoiceData.booking.item_total}</span>
                  </div>
                  <div style="display: flex; justify-content: space-between; font-size: 14px; margin-bottom: 12px;">
                    <span style="color: #6b7280;">Discount:</span>
                    <span style="color: #059669;">-₹${invoiceData.booking.discount || 0}</span>
                  </div>
                  <div style="display: flex; justify-content: space-between; font-size: 14px; margin-bottom: 12px;">
                    <span style="color: #6b7280;">Taxes:</span>
                    <span style="color: #111827;">₹${invoiceData.booking.taxes}</span>
                  </div>
                  <div style="border-top: 1px solid #e5e7eb; padding-top: 12px;">
                    <div style="display: flex; justify-content: space-between; font-size: 18px; font-weight: 600;">
                      <span style="color: #111827;">Total Amount:</span>
                      <span style="color: #0d9488;">₹${invoiceData.booking.total_amount}</span>
                    </div>
                  </div>
                </div>
                
                <div style="margin-top: 24px; padding-top: 16px; border-top: 1px solid #e5e7eb;">
                  <div style="display: flex; justify-content: space-between; align-items: center; font-size: 14px; margin-bottom: 8px;">
                    <span style="color: #6b7280;">Payment Status:</span>
                    <span style="color: #111827; font-weight: 500;">
                      ${invoiceData.booking.payment_status.charAt(0).toUpperCase() + invoiceData.booking.payment_status.slice(1)}
                    </span>
                  </div>
                  ${invoiceData.booking.payment_mode ? `
                    <div style="display: flex; justify-content: space-between; font-size: 14px; margin-bottom: 8px;">
                      <span style="color: #6b7280;">Payment Mode:</span>
                      <span style="color: #111827;">${invoiceData.booking.payment_mode}</span>
                    </div>
                  ` : ''}
                  ${invoiceData.booking.payment_id ? `
                    <div style="display: flex; justify-content: space-between; font-size: 14px; margin-bottom: 8px;">
                      <span style="color: #6b7280;">Payment ID:</span>
                      <span style="color: #111827; font-family: monospace;">${invoiceData.booking.payment_id}</span>
                    </div>
                  ` : ''}
                </div>
              </div>
            </div>
          </div>

                     <!-- Footer -->
           <div style="margin-top: 48px; padding-top: 32px; border-top: 1px solid #e5e7eb;">
             <div style="text-align: center; font-size: 12px; color: #6b7280;">
               <p style="margin: 0;">This is a computer-generated invoice.</p>
             </div>
           </div>
        </div>
      `;
      
      tempDiv.innerHTML = invoiceHTML;
      document.body.appendChild(tempDiv);
      
      // Wait for images to load
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Generate PDF
      const canvas = await html2canvas(tempDiv, {
        background: 'white',
        width: 800,
        height: tempDiv.scrollHeight,
        useCORS: true,
        allowTaint: true
      });
      
      // Remove the temporary div
      document.body.removeChild(tempDiv);
      
      // Convert to PDF
      const imgData = canvas.toDataURL('image/png');
      const pdf = new jsPDF('p', 'mm', 'a4');
      const imgWidth = 210;
      const pageHeight = 295;
      const imgHeight = (canvas.height * imgWidth) / canvas.width;
      let heightLeft = imgHeight;
      let position = 0;
      
      pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight);
      heightLeft -= pageHeight;
      
      while (heightLeft >= 0) {
        position = heightLeft - imgHeight;
        pdf.addPage();
        pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight);
        heightLeft -= pageHeight;
      }
      
      // Convert to base64
      const pdfBase64 = pdf.output('datauristring').split(',')[1];
      return pdfBase64;
      
    } catch (error) {
      console.error('Error generating PDF:', error);
      throw new Error('Failed to generate PDF');
    }
  };

  // Function to send invoice email with PDF attachment
  const sendInvoiceEmailWithPDF = async (invoiceData: any, pdfBase64: string) => {
    try {
      const emailData = {
        user_email: invoiceData.user.email,
        user_name: invoiceData.user.name,
        booking_id: invoiceData.booking.booking_id,
        service_name: invoiceData.booking.service_name,
        total_amount: invoiceData.booking.total_amount,
        service_date: invoiceData.booking.service_date,
        service_time: invoiceData.booking.service_time,
        address: invoiceData.user.address,
        cart_items: invoiceData.booking.cart_items,
        discount: invoiceData.booking.discount,
        taxes: invoiceData.booking.taxes,
        payment_status: invoiceData.booking.payment_status,
        pdf_data: pdfBase64
      };
      
      const response = await apiService.post('send_invoice_email_with_pdf.php', emailData);
      
      if (response?.status === 'success') {
        console.log('✅ Invoice email with PDF sent successfully');
        return true;
      } else {
        console.error('❌ Failed to send invoice email:', response?.message);
        return false;
      }
    } catch (error) {
      console.error('❌ Error sending invoice email:', error);
      return false;
    }
  };


  if (typesLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
      </div>
    );
  }

  if (!serviceInfo || serviceTypes.length === 0) {
    console.log('Service not found condition triggered:');
    console.log('serviceInfo:', serviceInfo);
    console.log('serviceTypes:', serviceTypes);
    console.log('serviceTypes.length:', serviceTypes.length);
    
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Service Not Found</h2>
          <p className="text-gray-600 mb-4">The requested service could not be found or has no available options.</p>
          <button
            onClick={() => navigate('/dashboard')}
            className="px-6 py-3 bg-teal-600 text-white rounded-lg font-medium hover:bg-teal-700 transition-colors"
          >
            Back to Dashboard
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header - Same as User Dashboard */}
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
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Main Content */}
          <div className="lg:col-span-2">
            {/* Service Hero Section with Image */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-2xl shadow-sm overflow-hidden mb-6"
            >
              <div className="relative h-64 bg-gradient-to-br from-teal-500 to-teal-700">
                <div className="absolute inset-0 bg-black bg-opacity-20"></div>
                {serviceInfo.image_path && getImageUrl(serviceInfo.image_path) ? (
                  <img
                    src={getImageUrl(serviceInfo.image_path)!}
                    alt={serviceInfo.service_name}
                    className="absolute inset-0 w-full h-full object-cover"
                    onError={(e) => {
                      console.log('Image failed to load:', e.currentTarget.src);
                      console.log('Original image path:', serviceInfo.image_path);
                      console.log('Constructed URL:', getImageUrl(serviceInfo.image_path));
                      // Fallback to gradient background if image fails to load
                      e.currentTarget.style.display = 'none';
                    }}
                    onLoad={() => {
                      console.log('Image loaded successfully:', serviceInfo.image_path);
                    }}
                  />
                ) : (
                  <div className="absolute inset-0 flex items-center justify-center">
                    <FiShield className="w-16 h-16 text-white" />
                  </div>
                                                  )}
                                  
                {/* Service Image Placeholder - only show if no image */}
                {!serviceInfo.image_path && (
                  <div className="absolute top-4 right-4 w-24 h-24 bg-white bg-opacity-20 rounded-lg flex items-center justify-center">
                    <FiShield className="w-12 h-12 text-white" />
                  </div>
                )}
              </div>
            </motion.div>

            {/* Green Area Card - Service Details */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-gradient-to-r from-teal-600 to-teal-700 rounded-2xl shadow-lg mb-6"
            >
              <div className="p-6">
                {/* Service Name and Image Section */}
                <div className="flex items-center space-x-4">
                  <div className="w-16 h-16 rounded-lg overflow-hidden bg-white bg-opacity-20 flex-shrink-0">
                    {serviceInfo.image_path ? (
                      <img
                        src={getImageUrl(serviceInfo.image_path)!}
                        alt={serviceInfo.service_name}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          console.log('Service card image failed to load:', e.currentTarget.src);
                          e.currentTarget.style.display = 'none';
                          e.currentTarget.nextElementSibling?.classList.remove('hidden');
                        }}
                        onLoad={() => {
                          console.log('Service card image loaded successfully:', serviceInfo.image_path);
                        }}
                      />
                    ) : null}
                    <div className={`w-full h-full flex items-center justify-center bg-teal-600 ${serviceInfo.image_path ? 'hidden' : ''}`}>
                      <FiShield className="w-8 h-8 text-white" />
                    </div>
                  </div>
                  <div className="flex-1">
                    <h2 className="text-xl font-bold text-white mb-1">{serviceInfo.service_name}</h2>
                    <div className="flex items-center space-x-4">
                      <div className="flex items-center text-sm text-white text-opacity-90">
                        <FiTimeIcon className="w-4 h-4 mr-1" />
                        <span>2-3 hours</span>
                      </div>
                      <div className="flex items-center text-sm text-white text-opacity-90">
                        <FiTruck className="w-4 h-4 mr-1" />
                        <span>Same day available</span>
                      </div>
                      <div className="flex items-center text-sm text-white text-opacity-90">
                        <FiShieldIcon className="w-4 h-4 mr-1" />
                        <span>90-day warranty</span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-3xl font-bold text-white">₹{serviceTypes[0]?.pricing[0]?.price || 999}</div>
                    <div className="text-sm text-white text-opacity-90">Starting price</div>
                  </div>
                </div>
              </div>
            </motion.div>

            {/* Service Benefits */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-2xl shadow-sm p-6 mb-6"
            >
              <h3 className="text-xl font-bold text-gray-900 mb-4">Why Choose Our Service?</h3>
              <div className="grid grid-cols-2 gap-4">
                {serviceBenefits.map((benefit, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="flex items-start space-x-3 p-4 bg-gray-50 rounded-xl"
                  >
                    <div className="w-10 h-10 bg-teal-100 rounded-lg flex items-center justify-center flex-shrink-0">
                      <benefit.icon className="w-5 h-5 text-teal-600" />
                    </div>
                    <div>
                      <h4 className="font-semibold text-gray-900 text-sm">{benefit.title}</h4>
                      <p className="text-xs text-gray-600 mt-1">{benefit.description}</p>
                    </div>
                  </motion.div>
                ))}
              </div>
            </motion.div>

            {/* Service Process */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-2xl shadow-sm p-6 mb-6"
            >
              <h3 className="text-xl font-bold text-gray-900 mb-4">How it works</h3>
              <div className="space-y-4">
                {serviceProcess.map((process, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="flex items-start space-x-4"
                  >
                    <div className="w-8 h-8 bg-teal-600 rounded-full flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                      {process.step}
                    </div>
                    <div className="flex-1">
                      <h4 className="font-semibold text-gray-900">{process.title}</h4>
                      <p className="text-sm text-gray-600 mt-1">{process.description}</p>
                    </div>
                  </motion.div>
                ))}
              </div>
            </motion.div>

            {/* Progress Steps */}
            <div className="mb-8">
              <div className="flex items-center justify-center space-x-4">
                <div className={`flex items-center ${currentStep === 'types' ? 'text-teal-600' : 'text-gray-400'}`}>
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 ${currentStep === 'types' ? 'border-teal-600 bg-teal-600 text-white' : 'border-gray-300'}`}>
                    1
                  </div>
                  <span className="ml-2 text-sm font-medium">Choose Services</span>
                </div>
                <div className={`w-16 h-0.5 ${currentStep === 'details' || currentStep === 'confirmation' ? 'bg-teal-600' : 'bg-gray-300'}`}></div>
                <div className={`flex items-center ${currentStep === 'details' ? 'text-teal-600' : currentStep === 'confirmation' ? 'text-teal-600' : 'text-gray-400'}`}>
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 ${currentStep === 'details' || currentStep === 'confirmation' ? 'border-teal-600 bg-teal-600 text-white' : 'border-gray-300'}`}>
                    2
                  </div>
                  <span className="ml-2 text-sm font-medium">Details</span>
                </div>
                <div className={`w-16 h-0.5 ${currentStep === 'confirmation' ? 'bg-teal-600' : 'bg-gray-300'}`}></div>
                <div className={`flex items-center ${currentStep === 'confirmation' ? 'text-teal-600' : 'text-gray-400'}`}>
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 ${currentStep === 'confirmation' ? 'border-teal-600 bg-teal-600 text-white' : 'border-gray-300'}`}>
                    3
                  </div>
                  <span className="ml-2 text-sm font-medium">Confirm</span>
                </div>
              </div>
            </div>

            {/* Step 1: Choose Service Types */}
            {currentStep === 'types' && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="space-y-6"
              >
                <div className="bg-white rounded-2xl shadow-sm p-6">
                  <div className="flex items-center justify-between mb-6">
                    <h2 className="text-xl font-bold text-gray-900">Choose Your Services</h2>
                    <div className="text-sm text-gray-500">
                      {cartItems.length} item{cartItems.length !== 1 ? 's' : ''} selected
                    </div>
                  </div>
                  
                  {serviceTypes.length === 0 ? (
                    <div className="text-center py-8">
                      <FiShield className="w-16 h-16 text-gray-400 mx-auto mb-4" />
                      <p className="text-gray-500">No service types available for this service.</p>
                    </div>
                  ) : (
                    <div className="space-y-4">
                      {serviceTypes.map((serviceType) => (
                        <motion.div
                          key={serviceType.service_type_id}
                          initial={{ opacity: 0, y: 20 }}
                          animate={{ opacity: 1, y: 0 }}
                          className="border border-gray-200 rounded-xl p-6 hover:border-teal-300 transition-colors"
                        >
                          <div className="flex items-start justify-between mb-4">
                            <div>
                              <h3 className="font-semibold text-gray-900 text-lg">{serviceType.service_type_name}</h3>
                            </div>
                            <div className="flex items-center space-x-2">
                              <FiStar className="w-4 h-4 text-yellow-400 fill-current" />
                              <span className="text-sm text-gray-600">4.8</span>
                            </div>
                          </div>
                          
                          <div className="space-y-3">
                            {serviceType.pricing.map((pricingField: PricingField) => (
                              <motion.div
                                key={pricingField.id}
                                initial={{ opacity: 0 }}
                                animate={{ opacity: 1 }}
                                className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-100"
                              >
                                <div className="flex-1">
                                  <div className="flex items-center space-x-2">
                                    <div className="w-2 h-2 bg-teal-600 rounded-full"></div>
                                    <p className="font-medium text-gray-900">{pricingField.room_size}</p>
                                  </div>
                                </div>
                                <div className="flex items-center space-x-4">
                                  <div className="text-right">
                                    <p className="text-2xl font-bold text-teal-600">₹{pricingField.price}</p>
                                    <p className="text-xs text-gray-500">per treatment</p>
                                  </div>
                                  <div className="flex items-center space-x-3">
                                    {getCartItemQuantity(serviceType.service_type_id, pricingField.room_size) > 0 && (
                                      <>
                                        <button
                                          onClick={() => removeFromCart(serviceType.service_type_id, pricingField.room_size)}
                                          className="w-8 h-8 rounded-full bg-red-100 text-red-600 flex items-center justify-center hover:bg-red-200 transition-colors"
                                        >
                                          <FiMinus className="w-4 h-4" />
                                        </button>
                                        <span className="text-lg font-semibold text-gray-900 w-8 text-center">
                                          {getCartItemQuantity(serviceType.service_type_id, pricingField.room_size)}
                                        </span>
                                      </>
                                    )}
                                    <button
                                      onClick={() => addToCart(serviceType, pricingField)}
                                      className="w-8 h-8 rounded-full bg-teal-100 text-teal-600 flex items-center justify-center hover:bg-teal-200 transition-colors"
                                    >
                                      <FiPlus className="w-4 h-4" />
                                    </button>
                                  </div>
                                </div>
                              </motion.div>
                            ))}
                          </div>
                        </motion.div>
                      ))}
                    </div>
                  )}
                </div>
              </motion.div>
            )}

            {/* Step 2: Booking Details */}
            {currentStep === 'details' && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="space-y-6"
              >
                <div className="bg-white rounded-lg shadow-sm p-6">
                  <h2 className="text-xl font-bold text-gray-900 mb-6">Booking Details</h2>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {/* Date Selection */}
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        <FiCalendar className="inline w-4 h-4 mr-1" />
                        Select Date
                      </label>
                      <input
                        type="date"
                        min={today}
                        value={selectedDate ? selectedDate.toISOString().split('T')[0] : ''}
                        onChange={(e) => setSelectedDate(e.target.value ? new Date(e.target.value) : null)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                      />
                    </div>

                    {/* Time Selection */}
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        <FiClock className="inline w-4 h-4 mr-1" />
                        Select Time
                      </label>
                      <select
                        value={selectedTime}
                        onChange={(e) => setSelectedTime(e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                      >
                        <option value="">Choose a time slot</option>
                        {timeSlots.map((time) => (
                          <option key={time} value={time}>{time}</option>
                        ))}
                      </select>
                    </div>
                  </div>

                  {/* Address */}
                  <div className="mt-6">
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      <FiMapPin className="inline w-4 h-4 mr-1" />
                      Service Address
                    </label>
                    <textarea
                      value={address}
                      onChange={(e) => setAddress(e.target.value)}
                      placeholder="Enter your complete address"
                      rows={3}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                    />
                  </div>

                  {/* Special Notes */}
                  <div className="mt-6">
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Special Notes (Optional)
                    </label>
                    <textarea
                      value={notes}
                      onChange={(e) => setNotes(e.target.value)}
                      placeholder="Any special instructions or requirements"
                      rows={2}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                    />
                  </div>

                  {/* Coupon Section */}
                  <div className="mt-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                      <svg className="w-5 h-5 mr-2 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 5v2m0 4v2m0 4v2M5 5a2 2 0 00-2 2v3a2 2 0 110 4v3a2 2 0 002 2h14a2 2 0 002-2v-3a2 2 0 110-4V7a2 2 0 00-2-2H5z" />
                      </svg>
                      Apply Coupon
                    </h3>
                    
                    {!isCouponApplied ? (
                      <div className="flex space-x-3">
                        <input
                          type="text"
                          value={couponCode}
                          onChange={(e) => setCouponCode(e.target.value)}
                          placeholder="Enter coupon code"
                          className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                        />
                        <button
                          onClick={applyCoupon}
                          className="px-6 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 transition-colors"
                        >
                          Apply
                        </button>
                      </div>
                    ) : (
                      <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center">
                            <svg className="w-5 h-5 text-green-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                            </svg>
                            <div>
                              <p className="font-medium text-green-800">Coupon Applied: {appliedCouponCode}</p>
                              <p className="text-sm text-green-600">You saved ₹{couponDiscount.toFixed(0)}</p>
                            </div>
                          </div>
                          <button
                            onClick={removeCoupon}
                            className="text-green-600 hover:text-green-800"
                          >
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                            </svg>
                          </button>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Payment Method */}
                  <div className="mt-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                      <svg className="w-5 h-5 mr-2 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                      </svg>
                      Payment Method
                    </h3>
                    
                    <div className="space-y-3">
                      <label className="flex items-center p-4 border border-gray-200 rounded-lg cursor-pointer hover:bg-gray-50">
                        <input
                          type="radio"
                          name="paymentMethod"
                          value="cash"
                          checked={selectedPaymentMethod === 'cash'}
                          onChange={(e) => setSelectedPaymentMethod(e.target.value)}
                          className="w-4 h-4 text-teal-600 border-gray-300 focus:ring-teal-500"
                        />
                        <div className="ml-3">
                          <p className="font-medium text-gray-900">Cash on Delivery</p>
                          <p className="text-sm text-gray-500">Pay when service is completed</p>
                        </div>
                      </label>
                      
                      <label className="flex items-center p-4 border border-gray-200 rounded-lg cursor-pointer hover:bg-gray-50">
                        <input
                          type="radio"
                          name="paymentMethod"
                          value="online"
                          checked={selectedPaymentMethod === 'online'}
                          onChange={(e) => setSelectedPaymentMethod(e.target.value)}
                          className="w-4 h-4 text-teal-600 border-gray-300 focus:ring-teal-500"
                        />
                        <div className="ml-3">
                          <p className="font-medium text-gray-900">Online Payment</p>
                          <p className="text-sm text-gray-500">Pay securely online</p>
                        </div>
                      </label>
                    </div>
                  </div>

                  {/* Terms and Conditions */}
                  <div className="mt-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                      <svg className="w-5 h-5 mr-2 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      Terms & Conditions
                    </h3>
                    
                    <div className="p-4 bg-gray-50 border border-gray-200 rounded-lg mb-4">
                      <ul className="space-y-2 text-sm text-gray-600">
                        <li>• Service will be provided on the scheduled date and time</li>
                        <li>• Payment is due upon completion of service</li>
                        <li>• Cancellation must be made 24 hours in advance</li>
                        <li>• Additional charges may apply for extra requirements</li>
                        <li>• Service guarantee as per company policy</li>
                      </ul>
                    </div>
                    
                    <label className="flex items-start cursor-pointer">
                      <input
                        type="checkbox"
                        checked={agreedToTerms}
                        onChange={(e) => setAgreedToTerms(e.target.checked)}
                        className="w-4 h-4 text-teal-600 border-gray-300 rounded focus:ring-teal-500 mt-1"
                      />
                      <span className="ml-3 text-sm text-gray-700">
                        I agree to the terms and conditions and privacy policy
                      </span>
                    </label>
                  </div>
                </div>
              </motion.div>
            )}

            {/* Step 3: Confirmation */}
            {currentStep === 'confirmation' && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="space-y-6"
              >
                <div className="bg-white rounded-lg shadow-sm p-6">
                  <h2 className="text-xl font-bold text-gray-900 mb-6">Booking Summary</h2>
                  
                  <div className="space-y-4">
                    <div className="border-b pb-4">
                      <h3 className="font-semibold text-gray-900 mb-2">Selected Services</h3>
                      {cartItems.map((item) => (
                        <div key={`${item.service_type_id}_${item.room_size}`} className="flex justify-between items-center py-1">
                          <span className="text-gray-700">{item.service_type_name} ({item.room_size}) x {item.quantity}</span>
                          <span className="font-semibold">₹{item.price * item.quantity}</span>
                        </div>
                      ))}
                    </div>

                    <div className="border-b pb-4">
                      <h3 className="font-semibold text-gray-900 mb-2">Booking Details</h3>
                      <div className="space-y-2 text-sm">
                        <div className="flex justify-between">
                          <span className="text-gray-600">Date:</span>
                          <span className="text-gray-900">{selectedDate ? selectedDate.toLocaleDateString() : 'Not selected'}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Time:</span>
                          <span className="text-gray-900">{selectedTime}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Address:</span>
                          <span className="text-gray-900">{address}</span>
                        </div>
                        {notes && (
                          <div className="flex justify-between">
                            <span className="text-gray-600">Notes:</span>
                            <span className="text-gray-900">{notes}</span>
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="space-y-2">
                      <div className="flex justify-between">
                        <span className="text-gray-600">Subtotal:</span>
                        <span className="font-semibold">₹{calculateSubtotal()}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Discount (15%):</span>
                        <span className="font-semibold text-green-600">-₹{calculateDiscount()}</span>
                      </div>
                      {isCouponApplied && (
                        <div className="flex justify-between">
                          <span className="text-gray-600">Coupon Discount ({appliedCouponCode}):</span>
                          <span className="font-semibold text-green-600">-₹{couponDiscount.toFixed(0)}</span>
                        </div>
                      )}
                      <div className="flex justify-between text-lg font-bold text-teal-600 border-t pt-2">
                        <span>Total Amount:</span>
                        <span>₹{calculateTotal()}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}
          </div>

          {/* Sticky Sidebar */}
          <div className="lg:col-span-1">
            <div className="sticky top-24">
              {/* Cart Summary */}
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                className="bg-white rounded-2xl shadow-lg p-6 mb-6"
              >
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold text-gray-900">Selected Services</h3>
                  <div className="text-sm text-teal-600 font-medium">
                    {cartItems.length} item{cartItems.length !== 1 ? 's' : ''}
                  </div>
                </div>
                
                {cartItems.length > 0 ? (
                  <>
                    <div className="space-y-3 mb-4">
                      {cartItems.map((item) => (
                        <div key={`${item.service_type_id}_${item.room_size}`} className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                          <div>
                            <span className="font-medium text-gray-900 text-sm">{item.service_type_name}</span>
                            <p className="text-xs text-gray-600">{item.room_size} x {item.quantity}</p>
                          </div>
                          <span className="font-semibold text-teal-600">₹{item.price * item.quantity}</span>
                        </div>
                      ))}
                    </div>
                    
                    <div className="border-t pt-4 space-y-2">
                      <div className="flex justify-between items-center">
                        <span className="text-gray-600">Subtotal:</span>
                        <span className="font-semibold">₹{calculateSubtotal()}</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-600">Discount (15%):</span>
                        <span className="font-semibold text-green-600">-₹{calculateDiscount()}</span>
                      </div>
                      {isCouponApplied && (
                        <div className="flex justify-between items-center">
                          <span className="text-gray-600">Coupon:</span>
                          <span className="font-semibold text-green-600">-₹{couponDiscount.toFixed(0)}</span>
                        </div>
                      )}
                      <div className="flex justify-between items-center pt-2 border-t">
                        <span className="text-lg font-bold text-gray-900">Total:</span>
                        <span className="text-xl font-bold text-teal-600">₹{calculateTotal()}</span>
                      </div>
                    </div>
                  </>
                                 ) : (
                   <div className="text-center py-8">
                     <div className="text-gray-400">
                       <FiShoppingCart className="w-12 h-12 mx-auto" />
                     </div>
                   </div>
                 )}
              </motion.div>

              {/* Action Buttons */}
              {currentStep === 'types' && cartItems.length > 0 && (
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="bg-white rounded-2xl shadow-lg p-6 space-y-3"
                >
                  <button
                    onClick={handleProceedToDetails}
                    className="w-full px-6 py-4 bg-gradient-to-r from-teal-600 to-teal-700 text-white rounded-xl font-semibold hover:from-teal-700 hover:to-teal-800 transition-all duration-200 transform hover:scale-105 shadow-lg"
                  >
                    Continue to Details
                  </button>
                  <button
                    onClick={addAllToCart}
                    className="w-full px-6 py-3 border border-teal-600 text-teal-600 rounded-xl font-semibold hover:bg-teal-50 transition-all duration-200"
                  >
                    Add to Cart
                  </button>
                </motion.div>
              )}

              {currentStep === 'details' && (
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="bg-white rounded-2xl shadow-lg p-6"
                >
                  <div className="space-y-4">
                    <button
                      onClick={() => setCurrentStep('types')}
                      className="w-full px-6 py-3 border border-gray-300 text-gray-700 rounded-xl font-medium hover:bg-gray-50 transition-colors"
                    >
                      Back to Services
                    </button>
                    <button
                      onClick={handleProceedToConfirmation}
                      className="w-full px-6 py-4 bg-gradient-to-r from-teal-600 to-teal-700 text-white rounded-xl font-semibold hover:from-teal-700 hover:to-teal-800 transition-all duration-200 transform hover:scale-105 shadow-lg"
                    >
                      Review & Confirm
                    </button>
                  </div>
                </motion.div>
              )}

              {currentStep === 'confirmation' && (
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="bg-white rounded-2xl shadow-lg p-6"
                >
                  <div className="space-y-4">
                    <button
                      onClick={() => setCurrentStep('details')}
                      className="w-full px-6 py-3 border border-gray-300 text-gray-700 rounded-xl font-medium hover:bg-gray-50 transition-colors"
                    >
                      Back to Details
                    </button>
                    <button
                      onClick={handleBooking}
                      disabled={isBooking}
                      className="w-full px-6 py-4 bg-gradient-to-r from-teal-600 to-teal-700 text-white rounded-xl font-semibold hover:from-teal-700 hover:to-teal-800 disabled:bg-gray-300 disabled:cursor-not-allowed transition-all duration-200 transform hover:scale-105 shadow-lg"
                    >
                      {isBooking ? (
                        <div className="flex items-center justify-center">
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                          Creating Booking...
                        </div>
                      ) : (
                        `Confirm Booking - ₹${calculateTotal()}`
                      )}
                    </button>
                  </div>
                </motion.div>
              )}


            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ServiceDetails; 
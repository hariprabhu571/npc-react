import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { FiShield, FiArrowLeft, FiCalendar, FiClock, FiMapPin, FiCheck, FiPlus, FiMinus } from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { Service } from '../types';
import { apiService } from '../services/api';
import { API_ENDPOINTS, API_BASE_URL } from '../config/api';
import { useQuery } from 'react-query';
import toast from 'react-hot-toast';

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
  const { user } = useAuth();
  const navigate = useNavigate();
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
      }
    }
  );

  useEffect(() => {
    console.log('ServiceTypesData received:', serviceTypesData);
    const serviceTypesDataAny = serviceTypesData as any;
    if (serviceTypesDataAny?.data) {
      console.log('Setting service types:', serviceTypesDataAny.data);
      console.log('Setting service info:', serviceTypesDataAny.service_info);
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

  const addToCart = (serviceType: ServiceType, pricingField: PricingField) => {
    const cartItemKey = `${serviceType.service_type_id}_${pricingField.id}`;
    setCartItems(prev => {
      const existing = prev.find(item => 
        item.service_type_id === serviceType.service_type_id && 
        item.room_size === pricingField.room_size
      );
      if (existing) {
        return prev.map(item => 
          item.service_type_id === serviceType.service_type_id && item.room_size === pricingField.room_size
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      } else {
        return [...prev, { 
          service_type_id: serviceType.service_type_id,
          service_type_name: serviceType.service_type_name,
          room_size: pricingField.room_size,
          price: pricingField.price,
          quantity: 1 
        }];
      }
    });
  };

  const removeFromCart = (serviceTypeId: number, roomSize: string) => {
    setCartItems(prev => {
      const existing = prev.find(item => 
        item.service_type_id === serviceTypeId && item.room_size === roomSize
      );
      if (existing && existing.quantity > 1) {
        return prev.map(item => 
          item.service_type_id === serviceTypeId && item.room_size === roomSize
            ? { ...item, quantity: item.quantity - 1 }
            : item
        );
      } else {
        return prev.filter(item => 
          !(item.service_type_id === serviceTypeId && item.room_size === roomSize)
        );
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
    return cartItems.reduce((total, item) => total + (item.price * item.quantity), 0);
  };

  const calculateDiscount = () => {
    return calculateSubtotal() * 0.15; // 15% discount
  };

  const calculateTotal = () => {
    return calculateSubtotal() - calculateDiscount() - couponDiscount;
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

        toast.success('Booking created successfully!');
        // Navigate to booking confirmation or dashboard
        navigate('/dashboard');
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
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center h-16">
              <button
              onClick={() => navigate('/dashboard')}
                className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <FiArrowLeft className="w-5 h-5" />
              </button>
            <div className="ml-4">
              <h1 className="text-xl font-semibold text-gray-900">Complete Booking</h1>
              <p className="text-sm text-gray-500">{serviceInfo.service_name}</p>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
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
            <div className="bg-white rounded-lg shadow-sm p-6">
              <h2 className="text-xl font-bold text-gray-900 mb-6">Choose Your Services</h2>
              
              {serviceTypes.length === 0 ? (
                <div className="text-center py-8">
                  <FiShield className="w-16 h-16 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-500">No service types available for this service.</p>
            </div>
              ) : (
                <div className="space-y-4">
                  {serviceTypes.map((serviceType) => (
                    <div key={serviceType.service_type_id} className="border border-gray-200 rounded-lg p-4">
                      <h3 className="font-semibold text-gray-900 mb-3">{serviceType.service_type_name}</h3>
                      
                      {serviceType.pricing.map((pricingField: PricingField) => (
                        <div key={pricingField.id} className="flex items-center justify-between py-2 border-t border-gray-100">
                          <div className="flex-1">
                            <p className="text-sm text-gray-600">Room Size: {pricingField.room_size}</p>
                            <p className="text-lg font-bold text-teal-600">₹{pricingField.price}</p>
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
                      ))}
                    </div>
                ))}
              </div>
              )}
            </div>

            {/* Cart Summary */}
            {cartItems.length > 0 && (
              <div className="bg-white rounded-lg shadow-sm p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Selected Services</h3>
                <div className="space-y-2">
                  {cartItems.map((item) => (
                    <div key={`${item.service_type_id}_${item.room_size}`} className="flex justify-between items-center">
                      <span className="text-gray-700">{item.service_type_name} ({item.room_size}) x {item.quantity}</span>
                      <span className="font-semibold">₹{item.price * item.quantity}</span>
                    </div>
                  ))}
                  <div className="border-t pt-2 mt-4">
                    <div className="flex justify-between items-center font-semibold text-lg">
                      <span>Total:</span>
                      <span className="text-teal-600">₹{calculateSubtotal()}</span>
              </div>
              </div>
              </div>
              </div>
            )}

            <div className="flex justify-end">
              <button
                onClick={handleProceedToDetails}
                disabled={cartItems.length === 0}
                className="px-6 py-3 bg-teal-600 text-white rounded-lg font-medium hover:bg-teal-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
              >
                Proceed to Details
              </button>
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

            <div className="flex justify-between">
              <button
                onClick={() => setCurrentStep('types')}
                className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-50 transition-colors"
              >
                Back
              </button>
              <button
                onClick={handleProceedToConfirmation}
                className="px-6 py-3 bg-teal-600 text-white rounded-lg font-medium hover:bg-teal-700 transition-colors"
              >
                Review & Confirm
              </button>
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
                    <span>₹{calculateTotal().toFixed(0)}</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="flex justify-between">
              <button
                onClick={() => setCurrentStep('details')}
                className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-50 transition-colors"
              >
                Back
              </button>
              <button
                onClick={handleBooking}
                disabled={isBooking}
                className="px-6 py-3 bg-teal-600 text-white rounded-lg font-medium hover:bg-teal-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
              >
                {isBooking ? (
                  <div className="flex items-center">
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
  );
};

export default ServiceDetails; 
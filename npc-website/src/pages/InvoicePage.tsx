import React, { useEffect, useRef, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { motion } from 'framer-motion';
import { 
  FiArrowLeft,
  FiShield,
  FiDownload,
  FiMapPin,
  FiCalendar,
  FiClock,
  FiDollarSign,
  FiCheckCircle,
  FiAlertCircle
} from 'react-icons/fi';
import { useAuth } from '../context/AuthContext';
import { Booking, CartItem } from '../types';
// @ts-ignore
import html2canvas from 'html2canvas';
// @ts-ignore
import jsPDF from 'jspdf';

interface InvoiceData {
  booking: Booking;
  user: {
    name: string;
    email: string;
    phone: string;
    address: string;
  };
}

const InvoicePage: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { user } = useAuth();
  const invoiceRef = useRef<HTMLDivElement>(null);
  
  // Get invoice data from localStorage or location state
  const [invoiceData, setInvoiceData] = useState<InvoiceData | null>(null);

  useEffect(() => {
    console.log('InvoicePage: useEffect triggered');
    // Try to get invoice data from localStorage first, then from location state
    const storedInvoiceData = localStorage.getItem('invoiceData');
    const storedTimestamp = localStorage.getItem('invoiceDataTimestamp');
    console.log('InvoicePage: storedInvoiceData from localStorage:', storedInvoiceData);
    console.log('InvoicePage: storedTimestamp from localStorage:', storedTimestamp);
    
    if (storedInvoiceData && storedTimestamp) {
      try {
        const parsedData = JSON.parse(storedInvoiceData);
        console.log('InvoicePage: parsed invoice data:', parsedData);
        setInvoiceData(parsedData);
        // Clear localStorage after reading
        localStorage.removeItem('invoiceData');
        localStorage.removeItem('invoiceDataTimestamp');
      } catch (error) {
        console.error('Error parsing invoice data from localStorage:', error);
      }
    } else if (location.state?.invoiceData) {
      console.log('InvoicePage: invoice data from location state:', location.state.invoiceData);
      setInvoiceData(location.state.invoiceData);
    } else {
      console.log('InvoicePage: No invoice data found in localStorage or location state');
    }
  }, [location.state]);

  useEffect(() => {
    console.log('InvoicePage: Auto-download useEffect triggered');
    console.log('InvoicePage: invoiceData:', invoiceData);
    console.log('InvoicePage: invoiceRef.current:', invoiceRef.current);
    
    // Auto-download invoice when component mounts
    if (invoiceData && invoiceRef.current) {
      console.log('InvoicePage: Starting auto-download in 2 seconds...');
      setTimeout(() => {
        console.log('InvoicePage: Executing downloadInvoice...');
        downloadInvoice();
      }, 2000); // Increased delay to ensure rendering is complete
    } else {
      console.log('InvoicePage: Cannot auto-download - missing invoiceData or invoiceRef');
      
              // Fallback: try again after a longer delay in case data loads later
        if (!invoiceData) {
          setTimeout(() => {
            console.log('InvoicePage: Retrying to get invoice data...');
            const storedInvoiceData = localStorage.getItem('invoiceData');
            const storedTimestamp = localStorage.getItem('invoiceDataTimestamp');
            if (storedInvoiceData && storedTimestamp) {
              try {
                const parsedData = JSON.parse(storedInvoiceData);
                setInvoiceData(parsedData);
                localStorage.removeItem('invoiceData');
                localStorage.removeItem('invoiceDataTimestamp');
              } catch (error) {
                console.error('Error parsing invoice data from localStorage:', error);
              }
            }
          }, 3000);
        }
    }
  }, [invoiceData]);

  const downloadInvoice = async () => {
    console.log('downloadInvoice: Starting download process');
    console.log('downloadInvoice: invoiceRef.current:', invoiceRef.current);
    console.log('downloadInvoice: invoiceData:', invoiceData);
    
    if (!invoiceRef.current) {
      console.log('downloadInvoice: No invoiceRef.current, returning');
      return;
    }

    try {
      console.log('downloadInvoice: Creating canvas with html2canvas...');
      const canvas = await html2canvas(invoiceRef.current, {
        useCORS: true,
        allowTaint: true,
        background: '#ffffff',
        width: invoiceRef.current.scrollWidth,
        height: invoiceRef.current.scrollHeight
      });
      console.log('downloadInvoice: Canvas created successfully');

      const imgData = canvas.toDataURL('image/png');
      console.log('downloadInvoice: Image data created');
      
      const pdf = new jsPDF('p', 'mm', 'a4');
      console.log('downloadInvoice: PDF created');
      
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

      const fileName = `Invoice_${invoiceData?.booking.booking_id}_${new Date().toISOString().split('T')[0]}.pdf`;
      console.log('downloadInvoice: Saving PDF with filename:', fileName);
      pdf.save(fileName);
      console.log('downloadInvoice: PDF saved successfully');
    } catch (error) {
      console.error('Error generating PDF:', error);
    }
  };





  if (!invoiceData) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <FiShield className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h2 className="text-xl font-semibold text-gray-900 mb-2">Invoice Not Found</h2>
          <p className="text-gray-600 mb-4">No invoice data available.</p>
          <button
            onClick={() => navigate('/bookings')}
            className="bg-teal-600 text-white px-6 py-2 rounded-lg hover:bg-teal-700 transition-colors"
          >
            Back to Bookings
          </button>
        </div>
      </div>
    );
  }

  const { booking, user: customerData } = invoiceData;

  return (
    <div className="min-h-screen bg-gray-50">
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
                <h1 className="text-xl font-semibold text-gray-900">Invoice</h1>
                <p className="text-sm text-gray-500">Booking #{booking.booking_id}</p>
              </div>
            </div>
            
            <div className="flex items-center space-x-3 no-print">
              <button
                onClick={downloadInvoice}
                className="flex items-center space-x-2 px-4 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 transition-colors"
              >
                <FiDownload className="w-4 h-4" />
                <span>Download</span>
              </button>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pt-24">
        {/* Debug Information */}
        {!invoiceData && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6"
          >
            <div className="flex items-center space-x-2 mb-2">
              <FiAlertCircle className="w-5 h-5 text-yellow-600" />
              <h3 className="text-lg font-semibold text-yellow-800">Invoice Data Not Found</h3>
            </div>
            <p className="text-yellow-700 mb-3">
              No invoice data was found. This might happen if:
            </p>
            <ul className="text-yellow-700 text-sm space-y-1 mb-3">
              <li>• The popup was blocked by your browser</li>
              <li>• You navigated directly to this page</li>
              <li>• The booking process was interrupted</li>
            </ul>
            <div className="flex space-x-3">
              <button
                onClick={() => navigate('/bookings')}
                className="px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition-colors"
              >
                Go to Bookings
              </button>
              <button
                onClick={() => window.location.reload()}
                className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
              >
                Reload Page
              </button>
            </div>
          </motion.div>
        )}

        {/* Invoice Document */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="bg-white rounded-lg shadow-lg overflow-hidden invoice-container"
        >
          <div ref={invoiceRef} className="p-8 invoice-content">
            {/* Header */}
            <div className="flex justify-between items-start mb-8">
              <div>
                <div className="flex items-center space-x-3 mb-4" style={{ alignItems: 'center' }}>
                  <div className="w-12 h-12 bg-teal-600 rounded-lg flex items-center justify-center overflow-hidden" style={{ flexShrink: 0 }}>
                    <img 
                      src="/images/logo-npc.png" 
                      alt="NPC Pest Control Logo"
                      className="w-8 h-8 object-contain"
                      style={{ display: 'block', maxWidth: '100%', height: 'auto' }}
                      onError={(e) => {
                        // Fallback to shield icon if logo fails to load
                        e.currentTarget.style.display = 'none';
                        e.currentTarget.nextElementSibling?.classList.remove('hidden');
                      }}
                    />
                    <FiShield className="w-6 h-6 text-white hidden" />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                    <h1 className="text-2xl font-bold text-gray-900" style={{ margin: 0, lineHeight: '1.2' }}>NPC Pest Control</h1>
                    <p className="text-gray-600" style={{ margin: 0, lineHeight: '1.2' }}>Professional Services</p>
                  </div>
                </div>
                <div className="text-sm text-gray-600">
                  <p>NPC PVT LTD, NO. 158, Murugan Kovil Street</p>
                  <p>Vanashakthi Nagar, Kolather, Chennai - 99</p>
                  <p>Phone: +91 86374 54428</p>
                  <p>Email: ashikali613@gmail.com</p>
                </div>
              </div>
              
              <div className="text-right">
                <h2 className="text-3xl font-bold text-gray-900 mb-2">INVOICE</h2>
                <div className="text-sm text-gray-600">
                  <p><strong>Invoice Date:</strong> {new Date().toLocaleDateString()}</p>
                  <p><strong>Invoice #:</strong> {booking.booking_id}</p>
                                     <div className="flex items-center space-x-2">
                     <span><strong>Status:</strong></span>
                     <span className="text-gray-900 font-medium">
                       {booking.status.charAt(0).toUpperCase() + booking.status.slice(1)}
                     </span>
                   </div>
                </div>
              </div>
            </div>

            {/* Customer Information */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">Bill To:</h3>
                <div className="text-sm text-gray-700">
                  <p className="font-semibold">{customerData.name}</p>
                  <p>{customerData.email}</p>
                  <p>{customerData.phone}</p>
                  <p className="mt-2">{customerData.address}</p>
                </div>
              </div>
              
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">Service Details:</h3>
                <div className="text-sm text-gray-700 space-y-1">
                  <div className="flex items-center space-x-2">
                    <FiCalendar className="w-4 h-4 text-gray-500" />
                    <span><strong>Service Date:</strong> {new Date(booking.service_date).toLocaleDateString()}</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <FiClock className="w-4 h-4 text-gray-500" />
                    <span><strong>Time Slot:</strong> {booking.service_time}</span>
                  </div>
                  {booking.special_notes && (
                    <div className="flex items-start space-x-2">
                      <FiCheckCircle className="w-4 h-4 text-gray-500 mt-0.5" />
                      <span><strong>Special Notes:</strong> {booking.special_notes}</span>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Service Items */}
            <div className="mb-8">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Service Details</h3>
              <div className="border border-gray-200 rounded-lg overflow-hidden">
                <table className="w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Service
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Description
                      </th>
                      <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Amount
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {/* Main Service */}
                    <tr>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {booking.service_name}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-500">
                        {booking.service_description || 'Professional pest control service'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 text-right">
                        -
                      </td>
                    </tr>
                    
                                         {/* Sub-services */}
                     {booking.cart_items && booking.cart_items.length > 0 ? (
                       // Display individual sub-services
                       booking.cart_items.map((item, index) => (
                         <tr key={index} className="bg-gray-50">
                           <td className="px-6 py-2 whitespace-nowrap text-sm font-medium text-gray-900 pl-8">
                             • {item.service_type_name} - {item.room_size}
                           </td>
                           <td className="px-6 py-2 text-sm text-gray-500">
                             Quantity: {item.quantity} × ₹{item.price}
                           </td>
                           <td className="px-6 py-2 whitespace-nowrap text-sm text-gray-900 text-right">
                             ₹{item.price * item.quantity}
                           </td>
                         </tr>
                       ))
                     ) : (
                       // If no cart items, show main service with total
                       <tr className="bg-gray-50">
                         <td className="px-6 py-2 whitespace-nowrap text-sm font-medium text-gray-900 pl-8">
                           • {booking.service_name}
                         </td>
                         <td className="px-6 py-2 text-sm text-gray-500">
                           Professional pest control service
                         </td>
                         <td className="px-6 py-2 whitespace-nowrap text-sm text-gray-900 text-right">
                           ₹{booking.item_total}
                         </td>
                       </tr>
                     )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Payment Summary */}
            <div className="flex justify-end">
              <div className="w-80">
                <div className="bg-gray-50 rounded-lg p-6">
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Payment Summary</h3>
                                     <div className="space-y-3">
                     <div className="flex justify-between text-sm">
                       <span className="text-gray-600">Item Total:</span>
                       <span className="text-gray-900">₹{booking.item_total}</span>
                     </div>
                     <div className="flex justify-between text-sm">
                       <span className="text-gray-600">Discount:</span>
                       <span className="text-green-600">-₹{booking.discount || 0}</span>
                     </div>
                     <div className="flex justify-between text-sm">
                       <span className="text-gray-600">Taxes:</span>
                       <span className="text-gray-900">₹{booking.taxes}</span>
                     </div>
                     <div className="border-t border-gray-200 pt-3">
                       <div className="flex justify-between text-lg font-semibold">
                         <span className="text-gray-900">Total Amount:</span>
                         <span className="text-teal-600">₹{booking.total_amount}</span>
                       </div>
                     </div>
                   </div>
                  
                  <div className="mt-6 pt-4 border-t border-gray-200">
                                         <div className="flex justify-between items-center text-sm">
                       <span className="text-gray-600">Payment Status:</span>
                       <span className="text-gray-900 font-medium">
                         {booking.payment_status.charAt(0).toUpperCase() + booking.payment_status.slice(1)}
                       </span>
                     </div>
                    {booking.payment_mode && (
                      <div className="flex justify-between text-sm mt-2">
                        <span className="text-gray-600">Payment Mode:</span>
                        <span className="text-gray-900">{booking.payment_mode}</span>
                      </div>
                    )}
                    {booking.payment_id && (
                      <div className="flex justify-between text-sm mt-2">
                        <span className="text-gray-600">Payment ID:</span>
                        <span className="text-gray-900 font-mono">{booking.payment_id}</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>

            {/* Footer */}
            <div className="mt-12 pt-8 border-t border-gray-200">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-sm text-gray-600">
                <div>
                  <h4 className="font-semibold text-gray-900 mb-2">Terms & Conditions</h4>
                  <ul className="space-y-1 text-xs">
                    <li>• Payment is due upon receipt of this invoice</li>
                    <li>• Late payments may incur additional charges</li>
                    <li>• Service satisfaction is guaranteed</li>
                  </ul>
                </div>
                <div>
                  <h4 className="font-semibold text-gray-900 mb-2">Contact Information</h4>
                  <div className="text-xs space-y-1">
                    <p>Phone: +91 86374 54428</p>
                    <p>Email: ashikali613@gmail.com</p>
                    <p>Website: www.npcservices.com</p>
                  </div>
                </div>
                <div>
                  <h4 className="font-semibold text-gray-900 mb-2">Thank You</h4>
                  <p className="text-xs">
                    Thank you for choosing NPC Pest Control for your service needs. 
                    We appreciate your business and look forward to serving you again.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default InvoicePage; 
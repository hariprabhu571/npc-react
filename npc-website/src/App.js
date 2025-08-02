import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { motion, AnimatePresence } from 'framer-motion';

// Pages
import LandingPage from './pages/LandingPage';
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import UserDashboard from './pages/UserDashboard';
import AdminDashboard from './pages/AdminDashboard';
import TechnicianDashboard from './pages/TechnicianDashboard';
import ServiceDetails from './pages/ServiceDetails';
import BookingHistory from './pages/BookingHistory';
import ContactPage from './pages/ContactPage';
import ProfilePage from './pages/ProfilePage';
import ChangePassword from './pages/ChangePassword';
import PrivacyPolicy from './pages/PrivacyPolicy';
import RaiseTicket from './pages/RaiseTicket';
import OffersManagement from './pages/OffersManagement';
import SharePage from './pages/SharePage';
import InvoicePage from './pages/InvoicePage';
import CartPage from './pages/CartPage';
import MultiServiceBooking from './pages/MultiServiceBooking';
import LoadingSpinner from './components/LoadingSpinner';

// Protected Route Component
const ProtectedRoute = ({ children, allowedRoles }) => {
  const { isAuthenticated, user, isLoading } = useAuth();

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles && user && !allowedRoles.includes(user.role)) {
    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
};

// Main App Content
const AppContent = () => {
  const { isAuthenticated, user, isLoading } = useAuth();

  if (isLoading) {
    return <LoadingSpinner />;
  }

  return (
    <AnimatePresence mode="wait">
      <Routes>
        {/* Public Routes */}
        <Route 
          path="/" 
          element={
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              <LandingPage />
            </motion.div>
          } 
        />
        
        <Route 
          path="/login" 
          element={
            isAuthenticated ? (
              <Navigate to={user?.role === 'Admin' ? '/admin' : user?.role === 'Technician' ? '/technician' : '/dashboard'} replace />
            ) : (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
              >
                <LoginPage />
              </motion.div>
            )
          } 
        />
        
        <Route 
          path="/signup" 
          element={
            isAuthenticated ? (
              <Navigate to={user?.role === 'Admin' ? '/admin' : user?.role === 'Technician' ? '/technician' : '/dashboard'} replace />
            ) : (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
              >
                <SignupPage />
              </motion.div>
            )
          } 
        />

        {/* Protected Routes */}
        <Route 
          path="/dashboard" 
          element={
            <ProtectedRoute allowedRoles={['User']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <UserDashboard />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/admin" 
          element={
            <ProtectedRoute allowedRoles={['Admin']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <AdminDashboard />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/technician" 
          element={
            <ProtectedRoute allowedRoles={['Technician']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <TechnicianDashboard />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/service/:serviceName" 
          element={
            <ProtectedRoute allowedRoles={['User']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <ServiceDetails />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/bookings" 
          element={
            <ProtectedRoute allowedRoles={['User']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <BookingHistory />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/cart" 
          element={
            <ProtectedRoute allowedRoles={['User']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <CartPage />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/multi-service-booking" 
          element={
            <ProtectedRoute allowedRoles={['User']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <MultiServiceBooking />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/contact" 
          element={
            <ProtectedRoute>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <ContactPage />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/profile" 
          element={
            <ProtectedRoute allowedRoles={['User']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <ProfilePage />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/change-password" 
          element={
            <ProtectedRoute>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <ChangePassword />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/privacy-policy" 
          element={
            <ProtectedRoute>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <PrivacyPolicy />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/raise-ticket" 
          element={
            <ProtectedRoute allowedRoles={['User']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <RaiseTicket />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/offers" 
          element={
            <ProtectedRoute allowedRoles={['Admin']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <OffersManagement />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/share" 
          element={
            <ProtectedRoute allowedRoles={['User']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <SharePage />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        <Route 
          path="/invoice/:bookingId?" 
          element={
            <ProtectedRoute allowedRoles={['User']}>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
              >
                <InvoicePage />
              </motion.div>
            </ProtectedRoute>
          } 
        />

        {/* Catch all route */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </AnimatePresence>
  );
};

// Main App Component
const App = () => {
  return (
    <Router>
      <AuthProvider>
        <AppContent />
      </AuthProvider>
    </Router>
  );
};

export default App; 
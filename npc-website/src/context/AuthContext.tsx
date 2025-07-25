import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { User, LoginForm, SignupForm, UserProfileData, LoginResponseData, ApiResponse } from '../types';
import { apiService } from '../services/api';
import { API_ENDPOINTS } from '../config/api';
import toast from 'react-hot-toast';

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (formData: LoginForm) => Promise<boolean>;
  signup: (formData: SignupForm) => Promise<boolean>;
  logout: () => void;
  checkSession: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const isAuthenticated = !!user;

  const checkSession = async () => {
      const sessionId = localStorage.getItem('sessionId');
      const sessionExpiry = localStorage.getItem('sessionExpiry');
      const userRole = localStorage.getItem('userRole');

      if (!sessionId || !sessionExpiry || !userRole) {
        setIsLoading(false);
        return;
      }

      // Check if session has expired
      const expiryDate = new Date(sessionExpiry);
      if (new Date() > expiryDate) {
        logout();
        setIsLoading(false);
        return;
      }

    // Set a minimal user object for all roles (like the app)
        setUser({
      id: '',
      email: '',
      name: userRole,
      mobile: '',
      role: userRole as 'Admin' | 'Technician' | 'User',
      profile_pic: '',
    });
      setIsLoading(false);
  };

  const login = async (formData: LoginForm): Promise<boolean> => {
    try {
      setIsLoading(true);
      
      let endpoint = API_ENDPOINTS.USER_LOGIN;
      if (formData.role === 'Admin') {
        endpoint = API_ENDPOINTS.ADMIN_LOGIN;
      } else if (formData.role === 'Technician') {
        endpoint = API_ENDPOINTS.TECHNICIAN_LOGIN;
      }

      const response = await apiService.post(endpoint, {
        email: formData.email,
        password: formData.password,
        fcm_token: 'web_token', // For web, we use a static token
      }) as ApiResponse<LoginResponseData>;

      if (response.status === 'success' && response.sessionid) {
        // Store session data
        localStorage.setItem('sessionId', response.sessionid);
        localStorage.setItem('userRole', formData.role);
        if (response.session_expiry) {
          localStorage.setItem('sessionExpiry', response.session_expiry);
        }

        // Set user data
        if (response.data) {
        setUser({
          id: response.data?.id || '',
          email: formData.email,
          name: response.data?.customer_name || response.data?.employee_name || '',
          mobile: response.data?.mobile_number || response.data?.phone_number || '',
          role: formData.role,
          profile_pic: response.data?.profile_pic,
        });
        } else {
          // Minimal user object for Admin/Technician if no data field
          setUser({
            id: '',
            email: formData.email,
            name: formData.role, // Or 'Admin'/'Technician'
            mobile: '',
            role: formData.role as 'Admin' | 'Technician' | 'User',
            profile_pic: '',
          });
        }

        toast.success('Login successful!');
        return true;
      } else {
        toast.error(response.message || 'Login failed');
        return false;
      }
    } catch (error: any) {
      toast.error(error.message || 'Login failed');
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const signup = async (formData: SignupForm): Promise<boolean> => {
    try {
      setIsLoading(true);
      
      const response = await apiService.post(API_ENDPOINTS.USER_SIGNUP, formData);

      if (response.status === 'success') {
        toast.success('Account created successfully!');
        return true;
      } else {
        toast.error(response.message || 'Signup failed');
        return false;
      }
    } catch (error: any) {
      toast.error(error.message || 'Signup failed');
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem('sessionId');
    localStorage.removeItem('userRole');
    localStorage.removeItem('sessionExpiry');
    setUser(null);
    toast.success('Logged out successfully');
  };

  useEffect(() => {
    checkSession();
  }, []);

  const value: AuthContextType = {
    user,
    isAuthenticated,
    isLoading,
    login,
    signup,
    logout,
    checkSession,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}; 
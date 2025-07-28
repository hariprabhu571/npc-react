import axios, { AxiosInstance, AxiosResponse } from 'axios';
import { getApiUrl } from '../config/api';
import { ApiResponse } from '../types';

// Create axios instance
const api: AxiosInstance = axios.create({
  baseURL: getApiUrl(''),
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add session ID
api.interceptors.request.use(
  (config) => {
    const sessionId = localStorage.getItem('sessionId');
    if (sessionId) {
      config.headers['Session-ID'] = sessionId;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle errors
api.interceptors.response.use(
  (response: AxiosResponse) => {
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      // Session expired, redirect to login
      localStorage.removeItem('sessionId');
      localStorage.removeItem('userRole');
      localStorage.removeItem('sessionExpiry');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Generic API methods
export const apiService = {
  // GET request
  get: async <T>(endpoint: string): Promise<ApiResponse<T>> => {
    try {
      const response = await api.get(endpoint);
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Network error');
    }
  },

  // GET request for services (returns data directly)
  getServices: async (): Promise<any> => {
    try {
      const response = await api.get('fetch_services.php');
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Network error');
    }
  },

  // GET request for offers (returns data directly)
  getOffers: async (): Promise<any> => {
    try {
      const response = await api.get('fetch_all_offers.php');
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Network error');
    }
  },

  // GET request for user bookings (returns data directly)
  getUserBookings: async (): Promise<any> => {
    try {
      const response = await api.get('user-bookings.php');
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Network error');
    }
  },

  // POST request
  post: async <T>(endpoint: string, data?: any): Promise<ApiResponse<T>> => {
    try {
      const response = await api.post(endpoint, data);
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Network error');
    }
  },

  // POST request with form data
  postFormData: async <T>(endpoint: string, formData: FormData): Promise<ApiResponse<T>> => {
    try {
      const response = await api.post(endpoint, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Network error');
    }
  },

  // PUT request
  put: async <T>(endpoint: string, data?: any): Promise<ApiResponse<T>> => {
    try {
      const response = await api.put(endpoint, data);
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Network error');
    }
  },

  // DELETE request
  delete: async <T>(endpoint: string): Promise<ApiResponse<T>> => {
    try {
      const response = await api.delete(endpoint);
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Network error');
    }
  },

  // GET request for user profile
  getProfile: async (): Promise<any> => {
    try {
      const response = await api.get('getprofile.php');
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Network error');
    }
  },

  // GET request for user contact queries
  getUserContactQueries: async (): Promise<any> => {
    try {
      const response = await api.get('user_contact_queries.php');
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Network error');
    }
  },

  // POST request for submitting contact query
  submitContactQuery: async (data: any): Promise<any> => {
    try {
      const response = await api.post('submit_contact_query.php', data);
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Network error');
    }
  },
};

export default api; 
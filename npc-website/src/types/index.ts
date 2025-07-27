// User types
export interface User {
  id: string;
  email: string;
  name: string;
  mobile: string;
  role: 'User' | 'Admin' | 'Technician';
  profile_pic?: string;
}

// API Response Data types
export interface UserProfileData {
  id?: string;
  email_id?: string;
  customer_name?: string;
  employee_name?: string;
  mobile_number?: string;
  phone_number?: string;
  profile_pic?: string;
  address1?: string;
  address2?: string;
  gender?: string;
  country?: string;
}

// Specific API Response types
export interface ServicesResponse {
  status: 'success' | 'error';
  services: Service[];
  filtered_by_location?: string | null;
  total_count: number;
  message?: string;
}

export interface OffersResponse {
  status: 'success' | 'error';
  offers: Offer[];
  message?: string;
}

export interface BookingsResponse {
  user: {
    id: string;
    name: string;
    email: string;
    phone: string;
    address: string;
  };
  summary: {
    total_bookings: number;
    total_spent: number;
    active_bookings: number;
    completed_bookings: number;
  };
  bookings: {
    active: Booking[];
    completed: Booking[];
    cancelled: Booking[];
  };
}

export interface LoginResponseData {
  id?: string;
  email_id?: string;
  customer_name?: string;
  employee_name?: string;
  mobile_number?: string;
  phone_number?: string;
  profile_pic?: string;
}

// Service types
export interface Service {
  service_id: string;
  service_name: string;
  description: string;
  image_path?: string;
  locations?: string;
  created_at?: string;
}

export interface ServiceTypeData {
  typeName: string;
  pricingFields: PricingField[];
  id?: number;
}

export interface PricingField {
  roomSize: string;
  price: string;
  id?: number;
}

// Booking types
export interface Booking {
  booking_id: string;
  service_id?: string | null;
  service_name: string;
  service_description?: string;
  service_image?: string | null;
  category?: string;
  space_type?: string;
  item_total: number;
  taxes: number;
  total_amount: number;
  booking_date: string;
  service_date: string;
  service_time: string;
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
  address: string;
  special_notes?: string;
  payment_mode?: string;
  payment_status: string;
  payment_id?: string | null;
  created_at: string;
  updated_at?: string;
  booking_date_formatted?: string;
  service_date_formatted?: string;
  created_at_formatted?: string;
  can_cancel?: boolean;
  status_color?: string;
  status_icon?: string;
  technician_status?: 'assigned' | 'reached' | 'started' | 'completed';
}

// Offer types
export interface Offer {
  offer_id: string;
  offer_name: string;
  coupon_number: string;
  offer_starts_on: string;
  expires_on: string;
  offer_percentage: number;
  offer_banner_location?: string;
  status?: string;
}

// Employee types
export interface Employee {
  id: string;
  name: string;
  mobile: string;
  address: string;
  email: string;
  serviceType: string;
  idProof?: string;
}

// Contact types
export interface ContactQuery {
  query_id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  subject: string;
  message: string;
  status: 'pending' | 'resolved';
  created_at: string;
}

// API Response types
export interface ApiResponse<T> {
  status: 'success' | 'error';
  message?: string;
  data?: T;
  sessionid?: string;
  session_expiry?: string;
}

// Form types
export interface LoginForm {
  email: string;
  password: string;
  role: 'User' | 'Admin' | 'Technician';
}

export interface SignupForm {
  customer_name: string;
  mobile_number: string;
  password: string;
}

export interface ContactForm {
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  subject: string;
  message: string;
}

// Navigation types
export interface NavItem {
  label: string;
  path: string;
  icon: string;
  requiresAuth?: boolean;
  roles?: string[];
} 
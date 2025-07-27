export const API_BASE_URL = 'https://npcpest.com/npc/';

export const API_ENDPOINTS = {
  USER_LOGIN: 'userlogin.php',
  ADMIN_LOGIN: 'adminlogin.php',
  TECHNICIAN_LOGIN: 'technicianlogin.php',
  USER_SIGNUP: 'usersignup.php',

  // Services
  FETCH_SERVICES: 'fetch_services.php',
  GET_SERVICE_DETAILS: 'get_service_details.php',
  GET_USER_SERVICE_DETAILS: 'get_user_service_details.php',
  UPDATE_SERVICE_DETAILS: 'services_manager.php',
  UPDATE_SERVICE_TYPES: 'update-service-details.php',
  ADD_SERVICE: 'add_service.php',
  GET_SERVICE_TYPES: 'fetch_services.php',
  ADD_SERVICE_TYPE: 'add_service_type.php',
  UPDATE_SERVICE_TYPE: 'update_service_type.php',
  DELETE_SERVICE_TYPE: 'delete-service-type.php',
  ADD_PRICING_FIELD: 'add_pricing_field.php',
  UPDATE_PRICING_FIELD: 'update_pricing_field.php',
  DELETE_PRICING_FIELD: 'delete-pricing-field.php',

  // Bookings
  CREATE_BOOKING: 'book_service_v2.php',
  USER_BOOKINGS: 'user-bookings.php',
  CANCEL_BOOKING: 'cancel_booking.php',
  UPDATE_ORDER_STATUS: 'update_order_status.php',
  TECHNICIAN_ORDERS: 'technician_orders.php',

  // Offers
  FETCH_OFFERS: 'fetch_all_offers.php',
  FETCH_ALL_OFFERS: 'fetch_all_offers.php',
  ADD_OFFER: 'add_offers.php',
  DELETE_OFFER: 'delete_offers.php',

  // Profile
  USER_PROFILE: 'userupdate.php',
  GET_PROFILE: 'getprofile.php',
  GET_ADMIN_PROFILE: 'getadminprofile.php',
  GET_TECHNICIAN_PROFILE: 'gettechnicianprofile.php',
  CHANGE_PASSWORD: 'change_password.php',

  // Contact
  SUBMIT_CONTACT_QUERY: 'submit_contact_query.php',
  USER_CONTACT_QUERIES: 'user_contact_queries.php',
  ADMIN_CONTACT_QUERIES: 'admin_contact_queries.php',

  // Employees
  GET_TECHNICIANS: 'get_technicians.php',
  ADD_TECHNICIAN: 'add_technician.php',
  ADMIN_ORDERS: 'admin_orders.php',
  ASSIGN_TECHNICIAN: 'assign_technicians.php',
  RESET_PASSWORD: 'reset_password.php',
};

export function getApiUrl(endpoint: string) {
  return `${API_BASE_URL}${endpoint}`;
} 
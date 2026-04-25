class ApiConstants {
  // Base URL - Change this to your Flask backend URL
  static const String baseUrl = 'http://localhost:5001';
  
  // Auth endpoints
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String refresh = '$baseUrl/api/auth/refresh';
  static const String me = '$baseUrl/api/auth/me';
  static const String changePassword = '$baseUrl/api/auth/change-password';
  static const String forgotPassword = '$baseUrl/api/auth/forgot-password';
  static const String resetPassword = '$baseUrl/api/auth/reset-password';
  
  // Patient endpoints
  static const String patientProfile = '$baseUrl/api/patient/profile';
  static const String patientAppointments = '$baseUrl/api/patient/appointments';
  static const String patientPrescriptions = '$baseUrl/api/patient/prescriptions';
  static const String patientMedicineOrders = '$baseUrl/api/patient/medicine-orders';
  static const String patientLabOrders = '$baseUrl/api/patient/lab-orders';
  static const String patientLabReports = '$baseUrl/api/patient/lab-reports';
  
  // Doctor endpoints
  static const String doctorProfile = '$baseUrl/api/doctor/profile';
  static const String doctorAppointments = '$baseUrl/api/doctor/appointments';
  static const String doctorPrescriptions = '$baseUrl/api/doctor/prescriptions';
  static const String searchDoctors = '$baseUrl/api/doctor/search';
  
  // Nurse endpoints
  static const String nurseProfile = '$baseUrl/api/nurse/profile';
  static const String nurseAppointments = '$baseUrl/api/nurse/appointments';
  static const String searchNurses = '$baseUrl/api/nurse/search';
  
  // Medical Store endpoints
  static const String medicalStoreProfile = '$baseUrl/api/medical-store/profile';
  static const String medicines = '$baseUrl/api/medical-store/medicines';
  static const String medicineOrders = '$baseUrl/api/medical-store/orders';
  static const String medicalStoreDashboard = '$baseUrl/api/medical-store/dashboard';
  static const String searchMedicines = '$baseUrl/api/medical-store/search';
  
  // Lab Store endpoints
  static const String labStoreProfile = '$baseUrl/api/lab-store/profile';
  static const String labTests = '$baseUrl/api/lab-store/tests';
  static const String labTestOrders = '$baseUrl/api/lab-store/orders';
  static const String labReports = '$baseUrl/api/lab-store/reports';
  static const String labStoreDashboard = '$baseUrl/api/lab-store/dashboard';
  static const String searchLabTests = '$baseUrl/api/lab-store/search';
  
  // Admin endpoints
  static const String adminDashboard = '$baseUrl/api/admin/dashboard';
  static const String adminUsers = '$baseUrl/api/admin/users';
  static const String adminPatients = '$baseUrl/api/admin/patients';
  static const String adminDoctors = '$baseUrl/api/admin/doctors';
  static const String adminAnalytics = '$baseUrl/api/admin/analytics';
  
  // Appointments
  static const String appointments = '$baseUrl/api/appointments';
  
  // Notifications
  static const String notifications = '$baseUrl/api/notifications';
  
  // Payments
  static const String payments = '$baseUrl/api/payments';
}

class ApiConfig {
  static const String baseUrl = 'https://api.afyashelf.pesacrow.top/api/v1';

  // Auth
  static const String authLogin = '$baseUrl/auth/login';
  static const String authRegister = '$baseUrl/auth/register';
  static const String authRefresh = '$baseUrl/auth/refresh';
  static const String authLogout = '$baseUrl/auth/logout';
  static const String authMe = '$baseUrl/auth/me';
  static const String authSwitchClinic = '$baseUrl/auth/switch-clinic';
  static const String authWorkers = '$baseUrl/auth/workers';
  static const String authUsers = '$baseUrl/auth/users';

  // Clinics
  static const String clinics = '$baseUrl/clinics';
  static String clinic(String id) => '$baseUrl/clinics/$id';

  // Medicines
  static const String medicines = '$baseUrl/medicines';
  static String medicine(String id) => '$baseUrl/medicines/$id';
  static const String medicineOCR = '$baseUrl/medicines/ocr';

  // Batches
  static const String batches = '$baseUrl/batches';
  static const String batchesBulk = '$baseUrl/batches/bulk';

  // Transactions
  static const String transactions = '$baseUrl/transactions';

  // Reports
  static const String reportExpiry = '$baseUrl/reports/expiry';
  static const String reportLowStock = '$baseUrl/reports/low-stock';
  static const String reportStockSummary = '$baseUrl/reports/stock-summary';

  // Sync
  static const String syncFull = '$baseUrl/sync/full';
  static const String syncPull = '$baseUrl/sync/pull';
  static const String syncPush = '$baseUrl/sync/push';

  // Health
  static const String health = '$baseUrl/health';
}

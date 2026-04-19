class AppConstants {
  // API URL'sini güvenli bir şekilde tanımlıyoruz.
  // Eğer projeyi başlatırken özel bir URL verilmezse, 
  // otomatik olarak (defaultValue) bizim lokal sunucumuzu kullanır.
  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}

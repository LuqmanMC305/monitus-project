enum Environment{ local, staging }

class ApiConfig{
  static Environment current = Environment.local;

  static String get baseUrl {
    switch (current){
      case Environment.local:
        return 'https://jmazh9jinv.sharedwithexpose.com/api';
      
      case Environment.staging:
        return 'https://monitus-laravel-backend-49hltibe.on-forge.com/api';
    }
  }

  // Auth endpoints

   // Endpoint 1: For registering User Account (app_users table)
  static Uri register() =>
      Uri.parse('$baseUrl/app-register');

  // Endpoint 2: For login User Account (app_users table)
  static Uri login() =>
      Uri.parse('$baseUrl/app-login');
  
  // Endpoint 3: For syncing Device data (mobile_users table)
  static Uri registerMobile() =>
      Uri.parse('$baseUrl/register-mobile');

  // Community Endpoints
  static Uri loadCommunity() =>
      Uri.parse('$baseUrl/communities');

  static Uri joinCommunity() =>
      Uri.parse('$baseUrl/communities/join');

  // Request Alert
  static Uri requestAlert() =>
      Uri.parse('$baseUrl/reports');
  
}

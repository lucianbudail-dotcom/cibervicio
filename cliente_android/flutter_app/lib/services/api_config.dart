class ApiConfig {
  // URL del servidor de producción
  static const String baseUrl = 'http://lucicasa.es:3000/api';
  
  // Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String recover = '$baseUrl/auth/recover';
  static const String reset = '$baseUrl/auth/reset';
  static const String profile = '$baseUrl/perfil';
  static const String equipos = '$baseUrl/equipos';
  static const String equiposLibres = '$baseUrl/equipos/libres';
  static const String reservas = '$baseUrl/reservas';
  static const String misReservas = '$baseUrl/mis-reservas';
  static const String stats = '$baseUrl/stats';
}

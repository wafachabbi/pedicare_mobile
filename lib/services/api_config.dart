class ApiConfig {
  // Adresse de votre XAMPP — utilisez l'IP de votre PC sur le réseau local
  // pour que l'émulateur Android puisse y accéder.
  // Emulateur Android : 10.0.2.2  |  Appareil physique : IP LAN ex. 192.168.1.X
  static const String baseUrl = 'http://10.0.2.2/pedicare';

  static const String signup      = '$baseUrl/auth/signup.php';
  static const String login       = '$baseUrl/auth/login.php';
  static const String vaccins     = '$baseUrl/vaccins/index.php';
  static const String rendezvous  = '$baseUrl/rendezvous/index.php';
  static const String croissance  = '$baseUrl/croissance/index.php';
}

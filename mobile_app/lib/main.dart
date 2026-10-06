import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'config/app_theme.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/device_service.dart';
import 'services/fcm_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved custom base URL if any
  await ApiConfig.init();

  // Initialize infrastructure services
  final storageService = StorageService();
  final apiService = ApiService(storageService);
  final authService = AuthService(apiService, storageService);
  final deviceService = DeviceService(apiService);
  final fcmService = FcmService(apiService);

  // Initialize FCM in background without blocking app startup
  unawaited(fcmService.initialize());

  runApp(LaptopGuardianApp(
    storageService: storageService,
    apiService: apiService,
    authService: authService,
    deviceService: deviceService,
    fcmService: fcmService,
  ));
}

class LaptopGuardianApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;
  final AuthService authService;
  final DeviceService deviceService;
  final FcmService fcmService;

  const LaptopGuardianApp({
    super.key,
    required this.storageService,
    required this.apiService,
    required this.authService,
    required this.deviceService,
    required this.fcmService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<ApiService>.value(value: apiService),
        Provider<AuthService>.value(value: authService),
        Provider<DeviceService>.value(value: deviceService),
        Provider<FcmService>.value(value: fcmService),
      ],
      child: MaterialApp(
        title: 'Laptop Guardian',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/pairing': (context) => const PairingScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

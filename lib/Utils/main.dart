import 'package:flutter/material.dart';
import 'Screens/splash_screen.dart'; // Yeni oluşturduğunuz splash ekran dosyası
import 'Pages/home_page.dart';
import 'Pages/ble_scanner_page.dart';
import 'Pages/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RemoteX',
      theme: ThemeData(primarySwatch: Colors.blue),
      // İlk açılışta splash ekranı göster
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const HomePage(),
        '/bleScanner': (context) => const BleScannerPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

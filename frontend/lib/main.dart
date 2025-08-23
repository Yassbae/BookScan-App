import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_book/services/history_service.dart';
import 'package:scan_book/services/upload_service.dart';
import 'package:scan_book/viewmodels/AuthViewmodel.dart';
import 'package:scan_book/viewmodels/HistoryViewModel.dart';
import 'package:scan_book/viewmodels/UploadViewmodel.dart';
import 'package:scan_book/views/auth_screen.dart';
import 'package:scan_book/views/main_screen.dart';
import 'package:scan_book/views/scan_screen.dart';
import 'package:scan_book/views/register_screen.dart';
import 'package:scan_book/views/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ScanHistoryViewModel(HistoryService())),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = Dio();
    final uploadService = UploadService(dio);
    return MaterialApp(
      title: 'Scan Book',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/principle': (context) => ChangeNotifierProvider(
          create: (_) => UploadViewModel(uploadService),
          child: MainScreen(),
        ),
      },
    );
  }
}

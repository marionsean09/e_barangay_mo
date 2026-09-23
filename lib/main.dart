import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_barangay_mo/services/appwrite_service.dart';
import 'package:e_barangay_mo/theme/app_theme.dart';
import 'package:e_barangay_mo/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;

  try {
    await AppwriteService.client.ping();
    debugPrint('✅ Connected to Appwrite');
  } catch (e) {
    debugPrint('❌ Appwrite ping failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eBarangay Mo',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

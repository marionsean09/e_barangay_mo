import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'package:e_barangay_mo/services/appwrite_service.dart';
import 'package:e_barangay_mo/auth/login_page.dart';
import 'package:e_barangay_mo/resident/resident_dashboard.dart';
import 'package:e_barangay_mo/admin/admin_dashboard.dart';

void goToAuthGate(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthGate()),
    (route) => false,
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<models.User?> _userFuture = _getUser();

  Future<models.User?> _getUser() async {
    try {
      return await AppwriteService.account.get();
    } on AppwriteException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<models.User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        if (user.labels.contains('admin')) {
          return AdminDashboard(user: user);
        }
        return ResidentDashboard(user: user);
      },
    );
  }
}

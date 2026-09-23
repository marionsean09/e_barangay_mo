import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'package:e_barangay_mo/services/appwrite_service.dart';
import 'package:e_barangay_mo/auth/login_page.dart';
import 'package:e_barangay_mo/resident/submit_concern_page.dart';
import 'package:e_barangay_mo/admin/admin_dashboard.dart';

/// Clears the navigation history and shows the right page for the
/// current session. Call this after login, signup, and logout.
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
      return await AppwriteService.account.get(); // throws if not logged in
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

        // ROLE LOGIC: admins have the "admin" label (set in Console → Auth → Users)
        if (user.labels.contains('admin')) {
          return const AdminDashboard();
        }
        return const SubmitConcernPage();
      },
    );
  }
}

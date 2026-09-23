import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:e_barangay_mo/services/appwrite_service.dart';
import 'package:e_barangay_mo/auth/auth_gate.dart';

import 'package:e_barangay_mo/auth/signup_page.dart';
import 'package:e_barangay_mo/theme/app_colors.dart';
import 'package:e_barangay_mo/theme/app_tokens.dart';
import 'package:e_barangay_mo/widgets/app_card.dart';
import 'package:e_barangay_mo/widgets/brand_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  void login() async {
    try {
      setState(() => isLoading = true);

      // Remove any leftover session (e.g. from a signup that failed halfway)
      try {
        await AppwriteService.account.deleteSession(sessionId: 'current');
      } on AppwriteException {
        // no active session, nothing to remove
      }

      await AppwriteService.account.createEmailPasswordSession(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;
      goToAuthGate(context);
    } on AppwriteException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpace.s6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLockup(height: 48),
                  const SizedBox(height: AppSpace.s2),
                  Text("Request, report, resolve", style: text.bodySmall),

                  const SizedBox(height: AppSpace.s8),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),

                  const SizedBox(height: AppSpace.s4),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),

                  const SizedBox(height: AppSpace.s6),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: c.onPrimary),
                            )
                          : const Text("Log in"),
                    ),
                  ),

                  const SizedBox(height: AppSpace.s2),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupPage(),
                        ),
                      );
                    },
                    child: const Text("Create an account"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

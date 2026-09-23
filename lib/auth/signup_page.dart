import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:e_barangay_mo/services/appwrite_service.dart';
import 'package:e_barangay_mo/auth/auth_gate.dart';
import 'package:e_barangay_mo/theme/app_colors.dart';
import 'package:e_barangay_mo/theme/app_tokens.dart';
import 'package:e_barangay_mo/widgets/app_card.dart';
import 'package:e_barangay_mo/widgets/brand_logo.dart';


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();

  bool isLoading = false;

  void signUp() async {
    try {
      setState(() => isLoading = true);

      // 1. Create the account (password must be at least 8 characters)
      final user = await AppwriteService.account.create(
        userId: ID.unique(),
        email: email.text.trim(),
        password: password.text.trim(),
        name: fullName.text.trim(),
      );

      // 2. Log in, so this user is allowed to write to the database
      await AppwriteService.account.createEmailPasswordSession(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      // 3. Save the profile in the "users" table (row ID = user ID)
      await AppwriteService.tablesDB.createRow(
        databaseId: AppwriteService.databaseId,
        tableId: AppwriteService.usersTableId,
        rowId: user.$id,
        data: {
          'fullName': fullName.text.trim(),
          'email': email.text.trim(),
          'role': 'resident',
        },
      );

      if (!mounted) return;
      goToAuthGate(context); // goes straight to Submit Concern
    } on AppwriteException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? "Sign up failed")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Create account")),
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
                  const BrandMark(size: 56),
                  const SizedBox(height: AppSpace.s4),
                  Text("Resident registration", style: text.titleLarge),
                  const SizedBox(height: AppSpace.s1),
                  Text(
                    "Use your real name. It appears on your documents.",
                    style: text.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.s6),

                  TextField(
                    controller: fullName,
                    decoration: const InputDecoration(
                      labelText: "Full name",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s4),

                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s4),

                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      helperText: "At least 8 characters",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s6),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : signUp,
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: c.onPrimary),
                            )
                          : const Text("Sign up"),
                    ),
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

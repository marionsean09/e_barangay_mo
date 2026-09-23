import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:e_barangay_mo/services/appwrite_service.dart';
import 'package:e_barangay_mo/auth/auth_gate.dart';


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
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Center(
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.all(20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add,
                    size: 60, color: Colors.blue),
                const SizedBox(height: 10),
                const Text(
                  "Resident Registration",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: fullName,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signUp,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SIGN UP"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

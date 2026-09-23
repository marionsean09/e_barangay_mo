import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'package:e_barangay_mo/services/appwrite_service.dart';
import 'package:e_barangay_mo/auth/auth_gate.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<models.Row> concerns = [];
  bool isLoading = true;
  RealtimeSubscription? subscription;

  @override
  void initState() {
    super.initState();
    loadConcerns();

    // Reload whenever any row in "concerns" is created or updated
    subscription = AppwriteService.realtime.subscribe([
      Channel.tablesdb(AppwriteService.databaseId)
          .table(AppwriteService.concernsTableId)
          .row(),
    ]);
    subscription!.stream.listen((_) => loadConcerns());
  }

  @override
  void dispose() {
    subscription?.close();
    super.dispose();
  }

  Future<void> loadConcerns() async {
    try {
      final result = await AppwriteService.tablesDB.listRows(
        databaseId: AppwriteService.databaseId,
        tableId: AppwriteService.concernsTableId,
        queries: [
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );
      if (!mounted) return;
      setState(() {
        concerns = result.rows;
        isLoading = false;
      });
    } on AppwriteException catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Failed to load concerns")));
    }
  }

  Future<void> updateStatus(String rowId, String status) async {
    await AppwriteService.tablesDB.updateRow(
      databaseId: AppwriteService.databaseId,
      tableId: AppwriteService.concernsTableId,
      rowId: rowId,
      data: {'status': status},
    );
    await loadConcerns();
  }

  Color statusColor(String status) {
    switch (status) {
      case "Resolved":
        return Colors.green;
      case "In Progress":
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barangay Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: loadConcerns,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AppwriteService.account.deleteSession(sessionId: 'current');
              if (context.mounted) goToAuthGate(context);
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : concerns.isEmpty
          ? const Center(
              child: Text(
                "No concerns yet",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadConcerns,
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: concerns.map((row) {
                  final data = row.data;
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor(data['status']),
                        child: const Icon(Icons.report, color: Colors.white),
                      ),
                      title: Text(data['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${data['type']} • ${data['status']}"),
                      trailing: DropdownButton<String>(
                        value: data['status'],
                        underline: const SizedBox(),
                        items: ["Pending", "In Progress", "Resolved"]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => updateStatus(row.$id, v!),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}

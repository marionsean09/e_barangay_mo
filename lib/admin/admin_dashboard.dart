import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'package:e_barangay_mo/services/appwrite_service.dart';
import 'package:e_barangay_mo/auth/auth_gate.dart';
import 'package:e_barangay_mo/theme/app_colors.dart';
import 'package:e_barangay_mo/theme/app_tokens.dart';
import 'package:e_barangay_mo/widgets/app_card.dart';
import 'package:e_barangay_mo/widgets/status_pill.dart';

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

  static const statuses = ["Pending", "In Progress", "Resolved"];
  static const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "2026-09-23T08:15:00.000+00:00" → "Sep 23, 2026"
  String formatDate(String iso) {
    final date = DateTime.tryParse(iso)?.toLocal();
    if (date == null) return '';
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  IconData typeIcon(String? type) => switch (type) {
        'Request' => Icons.description_outlined,
        'Suggestion' => Icons.lightbulb_outline,
        _ => Icons.report_outlined,
      };

  Widget concernCard(models.Row row) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final data = row.data;
    final String status = data['status'] ?? 'Pending';

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Icon(typeIcon(data['type']), color: c.primary, size: 22),
          ),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? '', style: text.titleMedium),
                const SizedBox(height: AppSpace.s1),
                Text(
                  "${data['type']} · ${formatDate(row.$createdAt)}",
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpace.s2),
                StatusPill(status),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: "Change status",
            icon: Icon(Icons.more_vert, color: c.inkMuted),
            onSelected: (v) => updateStatus(row.$id, v),
            itemBuilder: (_) => [
              for (final s in statuses)
                CheckedPopupMenuItem(
                  value: s,
                  checked: s == status,
                  child: Text(s),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: loadConcerns,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Log out",
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s8),
                child: Text("No concerns yet", style: text.bodySmall),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadConcerns,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpace.s4),
                itemCount: concerns.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpace.s3),
                itemBuilder: (_, i) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: concernCard(concerns[i]),
                  ),
                ),
              ),
            ),
    );
  }
}

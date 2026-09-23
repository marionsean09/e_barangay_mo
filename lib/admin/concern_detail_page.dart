import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:e_barangay_mo/theme/phosphor_icons.dart';

import 'package:e_barangay_mo/resident/request_options.dart';
import 'package:e_barangay_mo/services/appwrite_service.dart';
import 'package:e_barangay_mo/theme/app_colors.dart';
import 'package:e_barangay_mo/theme/app_tokens.dart';
import 'package:e_barangay_mo/utils/concern_format.dart';
import 'package:e_barangay_mo/widgets/app_card.dart';
import 'package:e_barangay_mo/widgets/press_scale.dart';
import 'package:e_barangay_mo/widgets/status_pill.dart';

class ConcernDetailPage extends StatefulWidget {
  const ConcernDetailPage({super.key, required this.row});

  final models.Row row;

  @override
  State<ConcernDetailPage> createState() => _ConcernDetailPageState();
}

class _ConcernDetailPageState extends State<ConcernDetailPage> {
  late Map<String, dynamic> data = Map.of(widget.row.data);
  String? requesterName;
  bool isSaving = false;
  bool changed = false;

  bool get isRequest => data['type'] == 'Request';
  bool get isBlotter => data['type'] == 'Blotter';
  DateTime? get requestedDate => parseDate(data['requestedDate']);
  DateTime? get finalDate => parseDate(data['finalDate']);

  List<(String, String?)> get photos {
    if (isRequest) {
      return [
        for (final entry in requirementLabels.entries)
          (entry.value, data[entry.key] as String?),
      ];
    }
    final evidence = (data['evidence'] as List?)?.cast<String>() ?? [];
    return [
      for (var i = 0; i < evidence.length; i++) ("Photo ${i + 1}", evidence[i]),
    ];
  }
  DateTime? get claimDate => parseDate(data['claimDate']);

  @override
  void initState() {
    super.initState();
    loadRequester();
  }

  Future<void> loadRequester() async {
    try {
      final profile = await AppwriteService.tablesDB.getRow(
        databaseId: AppwriteService.databaseId,
        tableId: AppwriteService.usersTableId,
        rowId: data['userId'],
      );
      if (mounted) setState(() => requesterName = profile.data['fullName']);
    } on AppwriteException {
    }
  }

  Future<void> save(Map<String, dynamic> update, String message) async {
    setState(() => isSaving = true);
    try {
      await AppwriteService.tablesDB.updateRow(
        databaseId: AppwriteService.databaseId,
        tableId: AppwriteService.concernsTableId,
        rowId: widget.row.$id,
        data: update,
      );
      if (!mounted) return;
      setState(() {
        data.addAll(update);
        changed = true;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } on AppwriteException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Could not save.")));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> pickClaimDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: claimDate ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
      helpText: "Claiming date",
      confirmText: "Set date",
      selectableDayPredicate: (day) => day.weekday <= DateTime.friday,
    );
    if (picked == null) return;

    final value = DateTime(picked.year, picked.month, picked.day, 12)
        .toUtc()
        .toIso8601String();
    await save(
      {'claimDate': value, 'status': 'Resolved'},
      "Claiming date set to ${formatLongDate(picked)}",
    );
  }

  Future<void> setFinalDate(DateTime day, String message) async {
    final value =
        DateTime(day.year, day.month, day.day, 12).toUtc().toIso8601String();
    await save({'finalDate': value, 'status': 'In Progress'}, message);
  }

  Future<void> pickFinalDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    var initial = finalDate ?? requestedDate ?? today;
    if (initial.isBefore(today)) initial = today;
    while (initial.weekday > DateTime.friday) {
      initial = initial.add(const Duration(days: 1));
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
      helpText: "Final date",
      confirmText: "Set date",
      selectableDayPredicate: (day) => day.weekday <= DateTime.friday,
    );
    if (picked == null) return;
    await setFinalDate(picked, "Final date set to ${formatLongDate(picked)}");
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final String status = data['status'] ?? 'Pending';
    final filed = parseDate(widget.row.$createdAt) ?? DateTime.now();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Ref. ${referenceFor(widget.row)}")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpace.s2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(data['title'] ?? '',
                            style: text.headlineMedium),
                      ),
                      const SizedBox(width: AppSpace.s3),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.s2),
                        child: StatusPill(status, label: statusLabel(data)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s2),
                  Text(
                    "${data['type']} from ${requesterName ?? 'a resident'}, filed ${formatDate(filed)}",
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: AppSpace.s6),

                  if (isRequest) ...[
                    _claimCard(),
                    const SizedBox(height: AppSpace.s4),
                  ],
                  if (isBlotter) ...[
                    _scheduleCard(),
                    const SizedBox(height: AppSpace.s4),
                  ],

                  AppCard(
                    padding: const EdgeInsets.all(AppSpace.s6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            isRequest
                                ? "Purpose"
                                : isBlotter
                                ? "Reason"
                                : "Details",
                            style: text.titleMedium),
                        const SizedBox(height: AppSpace.s2),
                        Text(
                          (isRequest ? data['purpose'] : data['description']) ??
                              '',
                          style: text.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.s4),

                  if (isRequest || isBlotter) ...[
                    AppCard(
                      padding: const EdgeInsets.all(AppSpace.s6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isRequest ? "Requirements" : "Photos",
                              style: text.titleMedium),
                          const SizedBox(height: AppSpace.s4),
                          if (photos.isEmpty)
                            Text("No photos attached.", style: text.bodySmall)
                          else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns =
                                  constraints.maxWidth < 480 ? 2 : 4;
                              final width = (constraints.maxWidth -
                                      AppSpace.s3 * (columns - 1)) /
                                  columns;
                              return Wrap(
                                spacing: AppSpace.s3,
                                runSpacing: AppSpace.s3,
                                children: [
                                  for (final (label, fileId) in photos)
                                    SizedBox(
                                      width: width,
                                      child: _RequirementPhoto(
                                        label: label,
                                        fileId: fileId,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.s4),
                  ],

                  AppCard(
                    padding: const EdgeInsets.all(AppSpace.s6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status", style: text.titleMedium),
                        const SizedBox(height: AppSpace.s3),
                        Wrap(
                          spacing: AppSpace.s2,
                          runSpacing: AppSpace.s2,
                          children: [
                            for (final s in concernStatuses)
                              ChoiceChip(
                                label: Text(s),
                                selected: status == s,
                                showCheckmark: false,
                                onSelected: (_) {
                                  if (isSaving || status == s) return;
                                  save({'status': s}, "Marked as $s");
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSaving) ...[
                    const SizedBox(height: AppSpace.s4),
                    LinearProgressIndicator(
                      color: c.primary,
                      backgroundColor: c.primarySoft,
                    ),
                  ],
                  const SizedBox(height: AppSpace.s8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scheduleCard() {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final requested = requestedDate;
    final scheduled = finalDate;
    final canApprove = requested != null &&
        !requested.isBefore(DateUtils.dateOnly(DateTime.now())) &&
        (scheduled == null || !DateUtils.isSameDay(scheduled, requested));

    return Container(
      padding: const EdgeInsets.all(AppSpace.s6),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.calendarCheck, color: c.primary),
              const SizedBox(width: AppSpace.s2),
              Text("Blotter schedule",
                  style: text.titleMedium?.copyWith(color: c.primary)),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          Text("Requested by the resident",
              style: text.bodySmall?.copyWith(color: c.primary)),
          Text(
            requested == null ? "No date given" : formatLongDate(requested),
            style: text.titleMedium?.copyWith(color: c.primary),
          ),
          const SizedBox(height: AppSpace.s3),
          Text("Final date", style: text.bodySmall?.copyWith(color: c.primary)),
          Text(
            scheduled == null ? "Not set yet" : formatLongDate(scheduled),
            style: text.titleLarge?.copyWith(color: c.primary),
          ),
          const SizedBox(height: AppSpace.s1),
          Text(
            scheduled == null
                ? "Approve the requested date or set another one. The resident sees the final date on their home screen."
                : "The resident sees this date on their home screen.",
            style: text.bodyMedium?.copyWith(color: c.primary),
          ),
          const SizedBox(height: AppSpace.s4),
          Wrap(
            spacing: AppSpace.s2,
            runSpacing: AppSpace.s2,
            children: [
              if (canApprove) ...[
                PressScale(
                  enabled: !isSaving,
                  child: ElevatedButton.icon(
                    icon: const Icon(PhosphorIconsRegular.checkCircle),
                    label: const Text("Approve requested date"),
                    onPressed: isSaving
                        ? null
                        : () => setFinalDate(requested,
                            "Approved ${formatLongDate(requested)}"),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(PhosphorIconsRegular.calendarPlus),
                  label: Text(
                      scheduled == null ? "Set another date" : "Change date"),
                  onPressed: isSaving ? null : pickFinalDate,
                ),
              ] else
                PressScale(
                  enabled: !isSaving,
                  child: ElevatedButton.icon(
                    icon: const Icon(PhosphorIconsRegular.calendarPlus),
                    label: Text(
                        scheduled == null ? "Set final date" : "Change date"),
                    onPressed: isSaving ? null : pickFinalDate,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _claimCard() {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final date = claimDate;

    return Container(
      padding: const EdgeInsets.all(AppSpace.s6),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.calendarCheck, color: c.primary),
              const SizedBox(width: AppSpace.s2),
              Text("Claiming date",
                  style: text.titleMedium?.copyWith(color: c.primary)),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          Text(
            date == null ? "Not set yet" : formatLongDate(date),
            style: text.titleLarge?.copyWith(color: c.primary),
          ),
          const SizedBox(height: AppSpace.s1),
          Text(
            date == null
                ? "Pick the day the resident can claim this document. They will see it on their home screen."
                : "The resident sees this date on their home screen.",
            style: text.bodyMedium?.copyWith(color: c.primary),
          ),
          const SizedBox(height: AppSpace.s4),
          Wrap(
            spacing: AppSpace.s2,
            runSpacing: AppSpace.s2,
            children: [
              PressScale(
                enabled: !isSaving,
                child: ElevatedButton.icon(
                  icon: const Icon(PhosphorIconsRegular.calendarPlus),
                  label: Text(date == null ? "Set date" : "Change date"),
                  onPressed: isSaving ? null : pickClaimDate,
                ),
              ),
              if (date != null)
                OutlinedButton(
                  onPressed: isSaving
                      ? null
                      : () => save({'claimDate': null}, "Claiming date cleared"),
                  child: const Text("Clear"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequirementPhoto extends StatefulWidget {
  const _RequirementPhoto({required this.label, required this.fileId});

  final String label;
  final String? fileId;

  @override
  State<_RequirementPhoto> createState() => _RequirementPhotoState();
}

class _RequirementPhotoState extends State<_RequirementPhoto> {
  Future<Uint8List>? bytes;

  bool get hasFile => (widget.fileId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    if (!hasFile) return;
    setState(() {
      bytes = AppwriteService.storage
          .getFileView(
            bucketId: AppwriteService.requirementsBucketId,
            fileId: widget.fileId!,
          )
          .catchError((Object e) {
        debugPrint('Requirement photo ${widget.fileId} failed: $e');
        throw e;
      });
    });
  }

  String reason(Object? error) {
    if (error is AppwriteException) {
      if (error.code == 401 || error.type == 'user_unauthorized') {
        return "No permission. Give the admin Read on the bucket.";
      }
      if (error.code == 404) {
        return error.type == 'storage_bucket_not_found'
            ? "Bucket not found. Check the bucket ID."
            : "Photo was deleted from Storage.";
      }
      return error.message ?? "Could not load";
    }
    return "Could not load. Check the connection.";
  }

  void openFull(Uint8List data) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: InteractiveViewer(child: Image.memory(data)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    Widget placeholder(IconData icon, String message) => Container(
          color: c.surface,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpace.s2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: c.inkMuted),
              const SizedBox(height: AppSpace.s1),
              Text(message,
                  style: text.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: !hasFile || bytes == null
                ? placeholder(PhosphorIconsRegular.imageBroken, "Not uploaded")
                : FutureBuilder<Uint8List>(
                    future: bytes,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return InkWell(
                          onTap: load,
                          child: placeholder(
                            PhosphorIconsRegular.warning,
                            "${reason(snapshot.error)} Tap to retry.",
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return Container(color: c.border);
                      }
                      return InkWell(
                        onTap: () => openFull(snapshot.data!),
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => placeholder(
                            PhosphorIconsRegular.imageBroken,
                            "Can't show this format. Ask for a JPG or PNG.",
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: AppSpace.s2),
        Text(widget.label, style: text.bodySmall),
      ],
    );
  }
}

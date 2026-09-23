import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:e_barangay_mo/services/appwrite_service.dart';
import 'package:e_barangay_mo/auth/auth_gate.dart';
import 'package:e_barangay_mo/resident/request_options.dart';
import 'package:e_barangay_mo/theme/app_colors.dart';
import 'package:e_barangay_mo/theme/app_tokens.dart';
import 'package:e_barangay_mo/widgets/app_card.dart';

class SubmitConcernPage extends StatefulWidget {
  const SubmitConcernPage({super.key});

  @override
  State<SubmitConcernPage> createState() => _SubmitConcernPageState();
}

class _SubmitConcernPageState extends State<SubmitConcernPage> {
  final title = TextEditingController();
  final description = TextEditingController();
  final purpose = TextEditingController();
  String type = "Complaint";
  String requestType = requestFees.keys.first;

  final picker = ImagePicker();
  final Map<String, XFile> requirementFiles = {};
  final Map<String, Uint8List> requirementPreviews = {};
  bool isSubmitting = false;

  bool get isRequest => type == "Request";

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> pickRequirement(String key) async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      requirementFiles[key] = picked;
      requirementPreviews[key] = bytes;
    });
  }

  void submit() async {
    final String concernTitle;
    final String concernDescription;

    if (isRequest) {
      final missing = requirementLabels.keys
          .where((key) => !requirementPreviews.containsKey(key))
          .map((key) => requirementLabels[key]);
      if (missing.isNotEmpty) {
        showMessage("Please upload: ${missing.join(', ')}");
        return;
      }
      if (purpose.text.trim().isEmpty) {
        showMessage("Please enter the purpose of your request");
        return;
      }
      concernTitle = requestType;
      concernDescription = purpose.text.trim();
    } else {
      if (title.text.trim().isEmpty || description.text.trim().isEmpty) {
        showMessage("Please fill in the title and description");
        return;
      }
      concernTitle = title.text.trim();
      concernDescription = description.text.trim();
    }

    setState(() => isSubmitting = true);

    try {
      final user = await AppwriteService.account.get();

      // Upload each requirement photo and keep its file ID
      final Map<String, String> fileIds = {};
      if (isRequest) {
        for (final key in requirementLabels.keys) {
          final picked = requirementFiles[key]!;
          final uploaded = await AppwriteService.storage.createFile(
            bucketId: AppwriteService.requirementsBucketId,
            fileId: ID.unique(),
            file: InputFile.fromBytes(
              bytes: requirementPreviews[key]!,
              filename: picked.name.isNotEmpty ? picked.name : '$key.jpg',
            ),
          );
          fileIds[key] = uploaded.$id;
        }
      }

      await AppwriteService.tablesDB.createRow(
        databaseId: AppwriteService.databaseId,
        tableId: AppwriteService.concernsTableId,
        rowId: ID.unique(),
        data: {
          'userId': user.$id,
          'title': concernTitle,
          'description': concernDescription,
          'type': type,
          'status': 'Pending',
          if (isRequest) ...{
            'requestType': requestType,
            'purpose': purpose.text.trim(),
            ...fileIds,
          },
        },
      );

      if (!mounted) return;
      showMessage(isRequest
          ? "Request submitted successfully"
          : "Concern submitted successfully");
      setState(() {
        title.clear();
        description.clear();
        purpose.clear();
        requirementFiles.clear();
        requirementPreviews.clear();
      });
    } on AppwriteException catch (e) {
      if (!mounted) return;
      showMessage(e.message ?? "Submit failed");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Widget requirementTile(String key) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final preview = requirementPreviews[key];
    final done = preview != null;
    final radius = BorderRadius.circular(AppRadius.sm);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s3),
      child: Material(
        color: c.surfaceRaised,
        borderRadius: radius,
        child: InkWell(
          onTap: isSubmitting ? null : () => pickRequirement(key),
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s3),
            decoration: BoxDecoration(
              border: Border.all(color: done ? c.success : c.inkMuted),
              borderRadius: radius,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: radius,
                  child: done
                      ? Image.memory(preview, width: 56, height: 56,
                          fit: BoxFit.cover)
                      : Container(
                          width: 56,
                          height: 56,
                          color: c.primarySoft,
                          child: Icon(Icons.add_a_photo_outlined,
                              color: c.primary),
                        ),
                ),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(requirementLabels[key]!, style: text.titleMedium),
                      Text(
                        done
                            ? "Uploaded. Tap to change."
                            : "Tap to upload a photo",
                        style: text.bodySmall
                            ?.copyWith(color: done ? c.success : c.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(done ? Icons.check_circle : Icons.upload_outlined,
                    color: done ? c.success : c.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Info banner: primary-soft with primary text.
  Widget feeNotice() {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: c.primary, size: 20),
              const SizedBox(width: AppSpace.s2),
              Text("Notice of fee",
                  style: text.titleMedium?.copyWith(color: c.primary)),
            ],
          ),
          const SizedBox(height: AppSpace.s2),
          Text("$requestType: ${requestFees[requestType]}",
              style: text.titleLarge?.copyWith(color: c.primary)),
          const SizedBox(height: AppSpace.s2),
          Text(
            "• Pay the fee at the Barangay Treasurer's Office when you claim your document.\n"
            "• Bring the original copies of your valid ID and Cedula for verification.\n"
            "• An official receipt is issued for every payment. Fees follow the barangay ordinance and may change.",
            style: text.bodyMedium?.copyWith(color: c.primary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit a concern"),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpace.s6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Concern details", style: text.titleLarge),
                  const SizedBox(height: AppSpace.s1),
                  Text(
                    "Tell the barangay what you need. We'll update you here.",
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: AppSpace.s6),

                  DropdownButtonFormField(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: "Concern type",
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: ["Complaint", "Request", "Suggestion"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: AppSpace.s4),

                  if (!isRequest) ...[
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s4),
                    TextField(
                      controller: description,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],

                  if (isRequest) ...[
                    DropdownButtonFormField(
                      initialValue: requestType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Document requested",
                        prefixIcon: Icon(Icons.article_outlined),
                      ),
                      items: requestFees.keys
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => requestType = v!),
                    ),
                    const SizedBox(height: AppSpace.s6),

                    Text("General requirements", style: text.titleMedium),
                    const SizedBox(height: AppSpace.s1),
                    Text("Clear photos, all four corners visible.",
                        style: text.bodySmall),
                    const SizedBox(height: AppSpace.s3),
                    for (final key in requirementLabels.keys)
                      requirementTile(key),
                    const SizedBox(height: AppSpace.s3),

                    TextField(
                      controller: purpose,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Purpose of request",
                        hintText:
                            "e.g. Employment, school requirement, bank account",
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpace.s6),

                    feeNotice(),
                  ],

                  const SizedBox(height: AppSpace.s6),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: isSubmitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: c.onPrimary),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(isSubmitting ? "Submitting" : "Submit"),
                      onPressed: isSubmitting ? null : submit,
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

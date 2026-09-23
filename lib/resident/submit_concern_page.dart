import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:e_barangay_mo/services/appwrite_service.dart';
import 'package:e_barangay_mo/auth/auth_gate.dart';
import 'package:e_barangay_mo/resident/request_options.dart';

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
    final preview = requirementPreviews[key];
    final done = preview != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: isSubmitting ? null : () => pickRequirement(key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
                color: done ? Colors.green : Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: done
                    ? Image.memory(preview, width: 64, height: 64,
                        fit: BoxFit.cover)
                    : Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.add_a_photo,
                            color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(requirementLabels[key]!,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      done ? "Uploaded • tap to change" : "Tap to upload a photo",
                      style: TextStyle(
                          fontSize: 12,
                          color: done ? Colors.green : Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(done ? Icons.check_circle : Icons.upload,
                  color: done ? Colors.green : Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget feeNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade900),
              const SizedBox(width: 8),
              Text("Notice of Fee",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900)),
            ],
          ),
          const SizedBox(height: 8),
          Text("$requestType: ${requestFees[requestType]}",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            "• Pay the fee at the Barangay Treasurer's Office when you claim your document.\n"
            "• Bring the original copies of your valid ID and Cedula for verification.\n"
            "• An official receipt is issued for every payment. Fees follow the barangay ordinance and may change.",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Community Concern"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AppwriteService.account.deleteSession(sessionId: 'current');
              if (context.mounted) goToAuthGate(context);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "Concern Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                DropdownButtonFormField(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: "Concern Type",
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ["Complaint", "Request", "Suggestion"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: 10),

                if (!isRequest) ...[
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: "Concern Title",
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: description,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                ],

                if (isRequest) ...[
                  DropdownButtonFormField(
                    initialValue: requestType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Document Requested",
                      prefixIcon: Icon(Icons.article),
                    ),
                    items: requestFees.keys
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => requestType = v!),
                  ),
                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "General Requirements",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final key in requirementLabels.keys) requirementTile(key),

                  TextField(
                    controller: purpose,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Purpose of Request",
                      hintText: "e.g. Employment, school requirement, bank account",
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                  ),
                  const SizedBox(height: 20),

                  feeNotice(),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(isSubmitting ? "SUBMITTING..." : "SUBMIT"),
                    onPressed: isSubmitting ? null : submit,
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

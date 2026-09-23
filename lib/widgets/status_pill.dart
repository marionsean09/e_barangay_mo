import 'package:flutter/material.dart';

import 'package:e_barangay_mo/theme/app_colors.dart';
import 'package:e_barangay_mo/theme/app_tokens.dart';

/// A short status label. Always shows the word, never just a color.
///   Pending     → primary-soft with primary text
///   In Progress → primary with on-primary text
///   Resolved    → success with on-primary text
///   Rejected    → danger with on-primary text
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color background, Color foreground) = switch (status) {
      'Resolved' => (c.success, c.onPrimary),
      'In Progress' => (c.primary, c.onPrimary),
      'Rejected' => (c.danger, c.onPrimary),
      _ => (c.primarySoft, c.primary),
    };

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: foreground),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";
import "../../../../shared/widgets/outline_panel.dart";

import "../../domain/supplier_evidence.dart";
import "../../../../shared/formatters.dart";

class ImpactPanel extends StatelessWidget {
  const ImpactPanel({super.key, required this.evidence});

  final SupplierEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final impact = evidence.monthlyCostImpact;
    return OutlinePanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            evidence.impactCaption,
            style: const TextStyle(fontSize: 10, color: muted),
          ),
          const SizedBox(height: 8),
          Text(
            impact == null
                ? '월 비용 영향 확정 불가'
                : "월 비용 영향 ${impact > 0 ? "+" : ""}${formatNumber(impact)}원",
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            evidence.impactNote,
            style: const TextStyle(fontSize: 11, color: muted, height: 1.6),
          ),
        ],
      ),
    );
  }
}

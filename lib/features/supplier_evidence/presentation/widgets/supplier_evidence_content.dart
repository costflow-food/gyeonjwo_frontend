import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

import "../../domain/supplier_evidence.dart";
import 'cost_line.dart';
import 'evidence_block.dart';
import 'impact_panel.dart';

class SupplierEvidenceContent extends StatelessWidget {
  const SupplierEvidenceContent({super.key, required this.evidence});

  final SupplierEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final lines = evidence.costLines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImpactPanel(evidence: evidence),
        const SizedBox(height: 12),
        for (var i = 0; i < lines.length; i++)
          CostLine(lines[i], divider: i < lines.length - 1),
        if (evidence.crossCheckFormulas.isNotEmpty) ...[
          const SizedBox(height: 28),
          EvidenceBlock(
            '차액 교차 확인',
            body: evidence.crossCheckNote,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 0, 18),
                child: Text(
                  evidence.crossCheckFormulas.join("\n"),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.9,
                    fontFamily: 'monospace',
                    fontFamilyFallback: ['Consolas', 'Courier New'],
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          evidence.disclaimer,
          style: const TextStyle(fontSize: 9, color: muted, height: 1.6),
        ),
        for (final section in evidence.sections) ...[
          const SizedBox(height: 26),
          EvidenceBlock(section.title, body: section.body, tag: section.tag),
        ],
      ],
    );
  }
}

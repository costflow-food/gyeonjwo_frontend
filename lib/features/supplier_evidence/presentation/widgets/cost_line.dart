import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

import "../../domain/supplier_evidence.dart";

class CostLine extends StatelessWidget {
  const CostLine(this.data, {super.key, this.divider = true});
  final EvidenceLine data;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        border: divider ? const Border(bottom: BorderSide(color: line)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              data.label,
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              data.value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                height: 1.7,
                fontWeight: data.emphasized
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

import "../../domain/supplier_evidence.dart";

class CostLine extends StatelessWidget {
  const CostLine(this.data, {super.key, this.divider = true});
  final EvidenceLine data;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final unconfirmed = data.unconfirmed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: unconfirmed ? blush : null,
        border: divider ? const Border(bottom: BorderSide(color: line)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (unconfirmed) ...[
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: accent,
                    semanticLabel: '확인 필요',
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: unconfirmed ? accent : muted,
                      fontWeight: unconfirmed
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
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
                color: unconfirmed ? accent : null,
                fontWeight: data.emphasized || unconfirmed
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

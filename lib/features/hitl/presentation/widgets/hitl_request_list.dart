import 'package:flutter/material.dart';

import '../../../../shared/lds_colors.dart';
import '../../domain/hitl_request.dart';

class HitlRequestList extends StatelessWidget {
  const HitlRequestList({
    super.key,
    required this.requests,
    required this.selectedId,
    required this.onSelect,
  });
  final List<HitlRequest> requests;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('조건에 맞는 검토 요청이 없습니다.', textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = requests[index];
        final selected = request.id == selectedId;
        return Semantics(
          selected: selected,
          child: Material(
            color: selected ? LdsColors.primarySoft : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: selected ? LdsColors.primary : LdsColors.line,
              ),
            ),
            child: InkWell(
              onTap: () => onSelect(request.id),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          request.kind.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: LdsColors.label,
                          ),
                        ),
                        Text(
                          request.status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: request.status == HitlStatus.waiting
                                ? LdsColors.primary
                                : LdsColors.label,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${request.supplier} · ${request.item}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: LdsColors.label,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.reason,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: LdsColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

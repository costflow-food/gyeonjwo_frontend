import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

enum ReviewStepState { done, active, waiting }

class ReviewProgressStep extends StatelessWidget {
  const ReviewProgressStep({
    super.key,
    required this.number,
    required this.label,
    required this.state,
    required this.demo,
  });

  final int number;
  final String label;
  final ReviewStepState state;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final active = state == ReviewStepState.active;
    final status = switch (state) {
      ReviewStepState.done => '완료',
      ReviewStepState.active => demo ? '시연 중' : '진행 중',
      ReviewStepState.waiting => '대기',
    };
    final marker = Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? ink : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: state == ReviewStepState.waiting
              ? const Color(0xFFCDD0D5)
              : ink,
        ),
      ),
      child: state == ReviewStepState.done
          ? const Icon(Icons.check, size: 14, color: ink)
          : Text(
              '$number',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : muted,
              ),
            ),
    );
    return MergeSemantics(
      child: Semantics(
        label: '$number단계',
        liveRegion: active,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: line)),
          ),
          child: Row(
            children: [
              ExcludeSemantics(child: marker),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: state == ReviewStepState.waiting ? muted : ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: state == ReviewStepState.waiting ? muted : ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

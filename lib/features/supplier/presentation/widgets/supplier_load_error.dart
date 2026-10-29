import "package:flutter/material.dart";

import "../../domain/supplier.dart";

/// Shows the server message for a [SupplierFailure], otherwise [fallback].
class SupplierLoadError extends StatelessWidget {
  const SupplierLoadError({
    super.key,
    required this.error,
    required this.fallback,
    required this.onRetry,
  });

  final Object error;
  final String fallback;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            failure is SupplierFailure ? failure.message : fallback,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text("다시 시도")),
        ],
      ),
    );
  }
}

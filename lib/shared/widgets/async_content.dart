import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: false,
      data: builder,
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("데이터를 불러오지 못했습니다. 다시 시도해 주세요."),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text("다시 시도")),
          ],
        ),
      ),
    );
  }
}

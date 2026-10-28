import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../auth_session_view_model.dart";

/// Ends the Supabase session, then returns to the login screen.
Future<void> signOutAndLeave(BuildContext context, WidgetRef ref) async {
  await ref.read(authSessionViewModelProvider.notifier).signOut();
  if (context.mounted) context.go("/login");
}

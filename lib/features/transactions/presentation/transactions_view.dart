import "package:flutter/material.dart";

import "../../../shared/widgets/workspace_shell.dart";

/// Transactions (`/transactions`, SSOT 7.12). 내용은 KAN-323에서 채우고,
/// 지금은 메뉴 선택만 보이는 빈 화면입니다.
class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) =>
      const WorkspaceShell(child: SizedBox.shrink());
}

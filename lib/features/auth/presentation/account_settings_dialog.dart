import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../shared/widgets/lds/lds.dart';
import '../../../shared/widgets/mobile_scaffold.dart';
import '../../../shared/widgets/workspace_button_styles.dart';
import 'account_view.dart';

/// 계정 메뉴의 '계정 설정'을 팝업으로 엽니다(접수·연결 확인 팝업과 같은 틀).
/// 휴대폰 아래 탭의 '계정 설정'은 지금처럼 화면(`/account`)입니다.
///
/// [returnTo]: 권한 화면에서 휴대폰 뒤로 가기가 돌아올 곳. 없으면 [context]의
/// 화면(라우트 밖의 context로 열 때는 꼭 넘깁니다).
Future<void> showAccountSettingsDialog(
  BuildContext context, {
  String? returnTo,
}) {
  returnTo ??= GoRouterState.of(context).uri.toString();
  return showDialog<void>(
    context: context,
    // Full screen on a phone: the dialog paints behind the system bars and
    // LdsDialog's own SafeArea keeps the content clear of them.
    useSafeArea: !isCompactLayout(context),
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: AccountSettingsDialog(returnTo: returnTo!),
    ),
  );
}

class AccountSettingsDialog extends StatefulWidget {
  const AccountSettingsDialog({super.key, required this.returnTo});

  final String returnTo;

  /// 탭을 바꿔도 팝업 높이가 덜 바뀌도록 내용 칸의 최소 높이(화면이 낮으면 스크롤).
  static const minBodyHeight = 520.0;

  @override
  State<AccountSettingsDialog> createState() => _AccountSettingsDialogState();
}

class _AccountSettingsDialogState extends State<AccountSettingsDialog> {
  /// 메일 발송 설정 탭에 저장하지 않은 변경이 있는지.
  bool _dirty = false;

  /// 메일 발송 설정을 저장하는 중인지. 결과를 받을 때까지 닫지 않습니다.
  bool _saving = false;
  bool _closing = false;

  /// 저장하지 않은 설정이 있으면 버릴지 묻고 닫습니다. 닫았으면 true.
  Future<bool> _requestClose() async {
    if (_closing || _saving) return false;
    if (_dirty) {
      _closing = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("변경한 설정을 버리시겠습니까?"),
          content: const Text("저장하지 않은 설정은 적용되지 않습니다."),
          actions: [
            TextButton(
              style: WorkspaceButtonStyles.text(context),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("계속 설정"),
            ),
            FilledButton(
              style: WorkspaceButtonStyles.filled(context),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("변경사항 버리기"),
            ),
          ],
        ),
      );
      _closing = false;
      if (discard != true || !mounted || _saving) return false;
    }
    // pop() closes even while PopScope is blocking (that is what we want here).
    Navigator.of(context).pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Every close (Esc, outside click, back) goes through _requestClose, which
    // reads the current state; canPop would only update on the next frame.
    final dialog = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: LdsDialog(
        title: '계정 설정',
        maxWidth: 760,
        onClose: _requestClose,
        footerNote: AppConfig.buildRevision.isEmpty
            ? null
            : '빌드 ${AppConfig.buildRevision}',
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AccountSettingsDialog.minBodyHeight,
          ),
          child: AccountSettings(
            inDialog: true,
            returnTo: widget.returnTo,
            requestClose: _requestClose,
            onDirtyChanged: (dirty) => _dirty = dirty,
            onSavingChanged: (saving) => _saving = saving,
          ),
        ),
      ),
    );
    // Its own messenger, so '발송 설정을 저장했습니다.' shows above the blur
    // instead of on the page behind it. The see-through area outside the
    // popup still closes it like the barrier.
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            dialog,
          ],
        ),
      ),
    );
  }
}

import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/supplier.dart";

/// 인증 라벨(4.1 weak). 확인 안 됨과 미충족은 색만이 아니라 글자·아이콘도
/// 다르게 둡니다.
class CertificationBadge extends StatelessWidget {
  const CertificationBadge(this.certification, {super.key});
  final Certification certification;

  @override
  Widget build(BuildContext context) {
    final (tone, icon, foreground) = switch (certification.status) {
      CertificationStatus.confirmed => (
        LdsTagTone.success,
        Icons.check,
        LdsColors.successText,
      ),
      CertificationStatus.unconfirmed => (
        LdsTagTone.warning,
        Icons.help_outline,
        LdsColors.cautionText,
      ),
      CertificationStatus.notMet => (
        LdsTagTone.error,
        Icons.warning_amber_rounded,
        null,
      ),
    };
    return LdsTag(
      "${certification.name} · ${certification.status.label}",
      tone: tone,
      icon: icon,
      foreground: foreground,
    );
  }
}

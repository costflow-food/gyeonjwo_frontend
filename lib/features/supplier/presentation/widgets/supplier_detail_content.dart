import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../../source_document/presentation/source_document_dialog.dart";
import "../../domain/supplier.dart";
import "../supplier_evidence_dialog.dart";
import "../supplier_register_dialog.dart";
import "supplier_item_card.dart";
import "supplier_source_badge.dart";

/// 거래처 상세 (`docs/design-ssot.md` 7.11, 7.15, 9.1).
///
/// 이름 · 출처 라벨 · 수정, '업체 정보' 이름표-값 표(넓으면 두 칸) + 맨 아래
/// 전체 폭 기준자료 줄, '취급 품목' 접고 펼치는 카드(첫 품목만 펼침).
class SupplierDetailContent extends StatelessWidget {
  const SupplierDetailContent({super.key, required this.supplier});
  final SupplierDetail supplier;

  /// 이보다 넓으면 업체 정보를 두 칸으로 나란히 둡니다.
  static const twoColumnWidth = 560.0;

  static const _labelWidth = 96.0;

  @override
  Widget build(BuildContext context) {
    LdsKeyValueRow row(String label, String? value) => value == null
        ? LdsKeyValueRow(label, child: const _Missing("미확인"))
        : LdsKeyValueRow(label, text: value);
    final left = [
      row("사업자번호", supplier.businessRegistrationNo),
      row("이메일", supplier.contactEmail),
      row("위치", supplier.location),
    ];
    final right = [
      row("담당자", supplier.contact.name),
      row("전화", supplier.contact.phone),
    ];
    final source = LdsKeyValueTable(
      labelWidth: _labelWidth,
      rows: [
        LdsKeyValueRow(
          "기준자료",
          child: _SourceDocument(evidence: supplier.evidence),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              supplier.name,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: LdsColors.ink,
              ),
            ),

            // The server edits only suppliers registered by hand
            // (SUPPLIER_NOT_EDITABLE for web-verified ones).
            if (supplier.sourceType == SupplierSourceType.registered)
              LdsIconButton(
                icon: Icons.edit_outlined,
                tooltip: "거래처 수정",
                onPressed: () =>
                    showSupplierRegisterDialog(context, initial: supplier),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SupplierSourceBadge(supplier.sourceType),
            if (supplier.location != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: LdsColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    supplier.location!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LdsColors.label,
                    ),
                  ),
                ],
              ),
            if (supplier.contact.name != null)
              Text(
                '담당 ${supplier.contact.name}',
                style: const TextStyle(fontSize: 13, color: LdsColors.label),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const _Title("업체 정보"),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < twoColumnWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LdsKeyValueTable(
                    labelWidth: _labelWidth,
                    rows: [...left, ...right],
                  ),
                  const SizedBox(height: 8),
                  source,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LdsKeyValueTable(
                        labelWidth: _labelWidth,
                        rows: left,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: LdsKeyValueTable(
                        labelWidth: _labelWidth,
                        rows: right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                source,
              ],
            );
          },
        ),
        // 업체 정보와 취급 품목 사이 구분선(시안 divider16).
        const SizedBox(height: 16),
        const Divider(height: 16, thickness: 1, color: LdsColors.line),
        const SizedBox(height: 16),
        _Title("취급 품목 ${supplier.items.length}"),
        const SizedBox(height: 12),
        if (supplier.items.isEmpty)
          const Text(
            "등록된 취급 품목이 없습니다. 품목이 없으면 후보 선정의 취급 근거로 쓰이지 않습니다.",
            style: TextStyle(fontSize: 15, color: LdsColors.mutedStrong),
          )
        else
          for (final (index, item) in supplier.items.indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            SupplierItemCard(
              key: ValueKey(item.id),
              item: item,
              // 첫 품목만 펼쳐서 시작합니다(7.15).
              initiallyExpanded: index == 0,
              onOpenEvidence: () => showSupplierEvidenceDialog(
                context,
                supplier: supplier,
                item: item,
              ),
            ),
          ],
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: LdsColors.ink,
      ),
    ),
  );
}

class _Missing extends StatelessWidget {
  const _Missing(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      height: 1.6,
      color: LdsColors.mutedStrong,
    ),
  );
}

/// 기준자료 줄의 값: 문서명만(7.11). 원문 메일이 있으면 누르면 원문을 열고,
/// 확인 시각·메모는 마우스를 올리면 보입니다. 없으면 '등록된 기준자료 없음'.
/// 밑줄은 연회색 `#B1B8C0`, 마우스를 올리면 글자색으로 진해집니다.
class _SourceDocument extends StatefulWidget {
  const _SourceDocument({required this.evidence});

  final SourceEvidence? evidence;

  @override
  State<_SourceDocument> createState() => _SourceDocumentState();
}

class _SourceDocumentState extends State<_SourceDocument> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final value = widget.evidence;
    if (value == null) return const _Missing("등록된 기준자료 없음");
    final detail = [
      if (value.checkedAt != null)
        "${formatSeoulDateTime(value.checkedAt!)} 확인",
      ?value.memo,
    ];
    const style = TextStyle(fontSize: 15, height: 1.6, color: LdsColors.ink);
    final mailId = value.sourceMailId;
    final name = mailId == null
        ? Text(value.label, style: style)
        : LdsFocusRing(
            radius: 4,
            child: InkWell(
              onTap: () => showSourceDocument(context, requestId: mailId),
              onHover: (hover) => setState(() => _hover = hover),
              hoverColor: Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              child: Text(
                value.label,
                style: style.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: _hover ? LdsColors.ink : LdsColors.disabled,
                ),
              ),
            ),
          );
    return Semantics(
      button: mailId != null,
      label: mailId == null ? value.label : "기준자료 ${value.label}, 원문 보기",
      excludeSemantics: mailId != null,
      child: detail.isEmpty
          ? name
          : Tooltip(message: detail.join(" · "), child: name),
    );
  }
}

import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/supplier.dart";
import "supplier_source_badge.dart";

/// 거래처 목록 카드 한 장 (시안 Suppliers).
///
/// 왼쪽 = 업체명(17/700) → 취급 품목 칩(높이 28, 검색어와 맞으면 주황) → 위치
/// 아이콘 + 지역(13 `#6B7583`). 오른쪽 = 출처 라벨(빈 정보가 있으면 '정보 부족
/// · N개 미확인'), 카드 세로 가운데. 카드: 흰 바탕, 1px `#E5E7EA`, 모서리 8, 안쪽
/// 14·16. 고른 카드는 주황 2px 테두리 + 연한 주황 그림자.
class SupplierListRow extends StatefulWidget {
  const SupplierListRow({
    super.key,
    required this.supplier,
    required this.selected,
    required this.onTap,
    this.query = "",
  });

  final SupplierSummary supplier;
  final bool selected;
  final VoidCallback onTap;

  /// 검색어. 맞는 품목 칩을 강조합니다.
  final String query;

  @override
  State<SupplierListRow> createState() => _SupplierListRowState();
}

class _SupplierListRowState extends State<SupplierListRow> {
  bool _hover = false;

  static const _radius = 8.0;

  /// 서버 검색처럼 대소문자·공백을 무시하고 비교합니다.
  static String _fold(String text) =>
      text.replaceAll(RegExp(r"\s+"), "").toLowerCase();

  @override
  Widget build(BuildContext context) {
    final supplier = widget.supplier;
    final selected = widget.selected;
    final items = supplier.itemNames;
    final itemsText = items.isEmpty ? "취급 품목 미등록" : items.join(", ");
    final location = supplier.location ?? "위치 미확인";
    final missing = supplier.missingInfoCount;
    final needle = _fold(widget.query);
    final border = selected
        ? const BorderSide(color: LdsColors.primary, width: 2)
        : BorderSide(color: _hover ? LdsColors.borderStrong : LdsColors.line);
    return Semantics(
      selected: selected,
      button: true,
      label:
          "${supplier.name} 거래처, "
          "${missing > 0 ? "정보 부족 $missing개 미확인" : supplier.sourceType.label}, "
          "$itemsText, $location",
      excludeSemantics: true,
      onTap: widget.onTap,
      child: LdsFocusRing(
        radius: _radius,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.fromBorderSide(border),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1FFF6000), // rgba(255,96,0,.12)
                      offset: Offset(0, 4),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              onHover: (hover) => setState(() => _hover = hover),
              borderRadius: BorderRadius.circular(_radius),
              hoverColor: Colors.transparent,
              child: Padding(
                // 고른 카드는 테두리가 1px 두꺼운 만큼 안쪽을 줄여 내용 자리가 같습니다.
                padding: selected
                    ? const EdgeInsets.symmetric(horizontal: 15, vertical: 13)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            supplier.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              letterSpacing: -.3,
                              color: LdsColors.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (items.isEmpty)
                            const Text(
                              "취급 품목 미등록",
                              style: TextStyle(
                                fontSize: 13,
                                color: LdsColors.outline,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final item in items)
                                  _ItemChip(
                                    item,
                                    hit:
                                        needle.isNotEmpty &&
                                        _fold(item).contains(needle),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: LdsColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: LdsColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 라벨은 카드 세로 가운데.
                    if (missing > 0)
                      SupplierMissingInfoBadge(missing)
                    else
                      SupplierSourceBadge(supplier.sourceType),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 품목 칩: 높이 28, 좌우 10, 1px `#E5E7EA`, 모서리 4, `#F9FAFB`, 13px
/// `#333D4B`. 검색어와 맞으면 주황 테두리 + `#FFEFE5` + `#993A00`.
class _ItemChip extends StatelessWidget {
  const _ItemChip(this.label, {required this.hit});

  final String label;
  final bool hit;

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: hit ? LdsColors.primarySoft : LdsColors.canvas,
      border: Border.all(color: hit ? LdsColors.primary : LdsColors.line),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: TextStyle(
        fontSize: 13,
        height: 1.2,
        color: hit ? LdsColors.primaryText : LdsColors.title,
      ),
    ),
  );
}

/// 목록 카드의 '정보 부족 · N개 미확인' 라벨(4.1 weak warning).
class SupplierMissingInfoBadge extends StatelessWidget {
  const SupplierMissingInfoBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) => LdsTag(
    "정보 부족 · $count개 미확인",
    tone: LdsTagTone.warning,
    icon: Icons.error_outline,
    foreground: LdsColors.cautionText,
  );
}

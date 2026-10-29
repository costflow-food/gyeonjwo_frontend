import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier_form_rules.dart";
import "../supplier_form_controllers.dart";
import "supplier_field_grid.dart";
import "supplier_form_field.dart";

class SupplierItemForm extends StatelessWidget {
  const SupplierItemForm({
    super.key,
    required this.index,
    required this.fields,
    required this.onRemove,
  });

  final int index;
  final SupplierItemFields fields;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "품목 ${index + 1}",
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: "품목 ${index + 1} 삭제",
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SupplierFieldGrid(
                  children: [
                    SupplierFormField(
                      label: "품목명 *",
                      hint: "예: 냉동 딸기",
                      controller: fields.name,
                      validator: SupplierFormRules.validateItemName,
                    ),
                    SupplierFormField(
                      label: "규격",
                      hint: "예: IQF 홀 / 10kg 박스",
                      controller: fields.specification,
                    ),
                    SupplierFormField(
                      label: "단위",
                      hint: "예: kg, box, EA",
                      controller: fields.unit,
                    ),
                    SupplierFormField(
                      label: "박스당 수량",
                      controller: fields.unitsPerBox,
                      validator: SupplierFormRules.validatePositiveDecimal,
                      keyboardType: decimal,
                    ),
                    SupplierFormField(
                      label: "박스당 중량 (kg)",
                      controller: fields.weightPerBox,
                      validator: SupplierFormRules.validatePositiveDecimal,
                      keyboardType: decimal,
                    ),
                    SupplierFormField(
                      label: "원산지",
                      hint: "예: 국산(충남 논산)",
                      controller: fields.origin,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SupplierFormField(
                  label: "인증",
                  hint: "쉼표로 구분. 예: HACCP, 유기농",
                  controller: fields.certifications,
                ),
                const SizedBox(height: 12),
                SupplierFormField(
                  label: "품목 비고",
                  hint: "특이사항 메모. 후보를 자동으로 제외하는 규칙으로 쓰이지 않습니다.",
                  controller: fields.notes,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

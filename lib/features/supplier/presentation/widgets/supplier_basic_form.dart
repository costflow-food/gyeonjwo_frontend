import "package:flutter/material.dart";

import "../../domain/supplier_form_rules.dart";
import "../supplier_form_controllers.dart";
import "supplier_field_grid.dart";
import "supplier_form_field.dart";
import "supplier_form_group_title.dart";

/// Supplier fields. Only the name is required; blanks are stored as unknown.
class SupplierBasicForm extends StatelessWidget {
  const SupplierBasicForm({
    super.key,
    required this.fields,
    this.editing = false,
  });
  final bool editing;
  final SupplierBasicFields fields;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SupplierFormGroupTitle(
          "업체 정보",
          "필수는 업체명뿐이며 모르는 값은 비워 두면 미확인으로 저장됩니다.",
        ),
        const SizedBox(height: 14),
        SupplierFieldGrid(
          children: [
            SupplierFormField(
              label: "업체명 *",
              controller: fields.name,
              validator: SupplierFormRules.validateName,
              autofocus: true,
            ),
            // The update API does not take these; shown for reference only.
            if (editing)
              SupplierFormField(
                label: "사업자번호",
                controller: fields.registrationNo,
                readOnly: true,
              ),
            SupplierFormField(
              label: "견적 요청 이메일",
              hint: "sales@example.com",
              controller: fields.email,
              validator: SupplierFormRules.validateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            SupplierFormField(label: "담당자", controller: fields.contactName),
            SupplierFormField(
              label: "전화",
              controller: fields.phone,
              validator: SupplierFormRules.validatePhone,
              keyboardType: TextInputType.phone,
            ),
            SupplierFormField(
              label: "위치",
              hint: "예: 경기 이천시",
              controller: fields.location,
            ),
          ],
        ),
        if (editing) const SizedBox(height: 12),
        if (editing)
          SupplierFormField(
            label: "기준자료 출처 메모",
            controller: fields.evidenceMemo,
            maxLines: 2,
            readOnly: true,
            helper: "사업자번호와 출처 메모는 여기서 바꿀 수 없습니다.",
          ),
      ],
    );
  }
}

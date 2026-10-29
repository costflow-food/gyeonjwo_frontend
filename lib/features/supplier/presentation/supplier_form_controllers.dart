import "package:flutter/widgets.dart";

import "../domain/supplier.dart";
import "../domain/supplier_form_rules.dart";

/// Text controllers for the supplier part of the register form.
class SupplierBasicFields {
  final name = TextEditingController();
  final registrationNo = TextEditingController();
  final email = TextEditingController();
  final contactName = TextEditingController();
  final phone = TextEditingController();
  final location = TextEditingController();
  final evidenceMemo = TextEditingController();

  List<TextEditingController> get controllers => [
    name,
    registrationNo,
    email,
    contactName,
    phone,
    location,
    evidenceMemo,
  ];

  /// Call only after the form validated; the name is required there.
  SupplierDraft toDraft(List<SupplierItemDraft> items) {
    final registration = SupplierFormRules.optional(registrationNo.text);
    return SupplierDraft(
      name: SupplierFormRules.optional(name.text)!,
      businessRegistrationNo: registration == null
          ? null
          : SupplierFormRules.formatBusinessRegistrationNo(registration),
      contactEmail: SupplierFormRules.optional(email.text),
      contactName: SupplierFormRules.optional(contactName.text),
      contactPhone: SupplierFormRules.optional(phone.text),
      location: SupplierFormRules.optional(location.text),
      evidenceMemo: SupplierFormRules.optional(evidenceMemo.text),
      items: items,
    );
  }

  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}

/// Text controllers for one handled item. The server derives the item key.
class SupplierItemFields {
  final name = TextEditingController();
  final specification = TextEditingController();
  final unit = TextEditingController();
  final unitsPerBox = TextEditingController();
  final weightPerBox = TextEditingController();
  final origin = TextEditingController();
  final certifications = TextEditingController();
  final notes = TextEditingController();

  List<TextEditingController> get controllers => [
    name,
    specification,
    unit,
    unitsPerBox,
    weightPerBox,
    origin,
    certifications,
    notes,
  ];

  SupplierItemDraft toDraft() => SupplierItemDraft(
    itemName: SupplierFormRules.optional(name.text)!,
    specification: SupplierFormRules.optional(specification.text),
    unit: SupplierFormRules.optional(unit.text),
    unitsPerBox: SupplierFormRules.optional(unitsPerBox.text),
    weightPerBox: SupplierFormRules.optional(weightPerBox.text),
    origin: SupplierFormRules.optional(origin.text),
    certifications: SupplierFormRules.parseCertifications(certifications.text),
    notes: SupplierFormRules.optional(notes.text),
  );

  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}

import "supplier.dart";
import "supplier_form_rules.dart";

/// Builds the `PATCH /api/v1/suppliers/{supplier_id}` body (KAN-288).
///
/// Only changed keys are sent: the server leaves missing keys as they are and
/// clears a key sent as null (except `name`). Saved items stay unless listed
/// and cannot be deleted; a listed item with `supplier_item_id` updates only
/// the attributes sent, one without it is added. Business registration number
/// and evidence memo are not part of the API.
///
/// Returns an empty map when nothing changed (the server rejects that).
abstract final class SupplierUpdate {
  static Map<String, Object?> body(
    SupplierDetail initial,
    SupplierDraft draft,
  ) {
    final body = <String, Object?>{};
    void put(String key, String? before, String? after) {
      final next = SupplierFormRules.optional(after);
      if (SupplierFormRules.optional(before) != next) body[key] = next;
    }

    put("name", initial.name, draft.name);
    put("contact_email", initial.contactEmail, draft.contactEmail);
    put("contact_name", initial.contact.name, draft.contactName);
    put("contact_phone", initial.contact.phone, draft.contactPhone);
    put("location", initial.location, draft.location);

    final saved = {for (final item in initial.items) item.id: item};
    final items = [
      for (final item in draft.items)
        if (item.supplierItemId case final id?)
          if (saved[id] case final before?) _changed(before, item),
      for (final item in draft.items)
        if (item.supplierItemId == null) _added(item),
    ].where((item) => item.isNotEmpty).toList();
    if (items.isNotEmpty) body["items"] = items;
    return body;
  }

  static Map<String, Object?> _changed(
    SupplierItem before,
    SupplierItemDraft after,
  ) {
    final changes = <String, Object?>{};
    void put(String key, String? previous, String? next) {
      final value = SupplierFormRules.optional(next);
      if (SupplierFormRules.optional(previous) != value) changes[key] = value;
    }

    put("item_name", before.itemName, after.itemName);
    put("specification", before.specification, after.specification);
    put("unit", before.unit, after.unit);
    put("units_per_box", before.unitsPerBox, after.unitsPerBox);
    put("weight_per_box", before.weightPerBox, after.weightPerBox);
    put("origin", before.origin, after.origin);
    put("notes", before.notes, after.notes);
    final certifications = [
      for (final certification in before.certifications) certification.name,
    ];
    if (!_sameList(certifications, after.certifications)) {
      changes["certifications"] = after.certifications;
    }
    if (changes.isEmpty) return const {};
    return {"supplier_item_id": before.id, ...changes};
  }

  static Map<String, Object?> _added(SupplierItemDraft item) => {
    "item_name": item.itemName,
    "specification": ?item.specification,
    "unit": ?item.unit,
    "units_per_box": ?item.unitsPerBox,
    "weight_per_box": ?item.weightPerBox,
    "origin": ?item.origin,
    "notes": ?item.notes,
    if (item.certifications.isNotEmpty) "certifications": item.certifications,
  };

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

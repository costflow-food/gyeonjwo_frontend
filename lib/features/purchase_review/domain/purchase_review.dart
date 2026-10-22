/// Temporary app models; these do not prescribe database tables.
class PurchaseReview {
  PurchaseReview({
    required this.requestId,
    required this.title,
    required this.supplierName,
    required this.specification,
    required this.effectiveDate,
    required this.periodLabel,
    required this.existingUnitPrice,
    required this.requestedUnitPrice,
    required this.reviewQuantity,
    required this.plannedQuantity,
    required this.fixedQuantity,
    required this.monthlyCostImpact,
    required this.impactNote,
    required this.costNote,
    required this.sourceNote,
    required List<SupplierQuote> suppliers,
  }) : suppliers = List.unmodifiable(suppliers);

  final String requestId,
      title,
      supplierName,
      specification,
      effectiveDate,
      periodLabel,
      impactNote,
      costNote,
      sourceNote;
  final int existingUnitPrice,
      requestedUnitPrice,
      reviewQuantity,
      plannedQuantity,
      fixedQuantity,
      monthlyCostImpact;
  final List<SupplierQuote> suppliers;
}

class SupplierQuote {
  const SupplierQuote({
    required this.letter,
    required this.unitPrice,
    required this.minimum,
    required this.leadTime,
    required this.shippingMonthlyCost,
    required this.logisticsMonthlyCost,
    required this.purchaseAmount,
    required this.monthlyTotalCost,
    required this.existing,
    required this.specification,
    required this.stock,
    required this.monthlyCostNote,
  });

  final String letter, minimum, leadTime, specification, stock, monthlyCostNote;
  final int unitPrice, purchaseAmount;
  final int? shippingMonthlyCost, logisticsMonthlyCost, monthlyTotalCost;
  final bool existing;
}

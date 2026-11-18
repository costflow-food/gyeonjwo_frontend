import "purchase_record.dart";

/// 정렬할 수 있는 열 (`docs/design-ssot.md` 7.12).
enum TransactionSort { date, quantity, unitPrice, total }

/// Suppliers 품목 카드 '마지막 실거래'에서 넘어온 조건 (7.12).
class TransactionsEntry {
  const TransactionsEntry({this.supplierItemId, this.itemName, this.date});

  /// `supplier_items.id`. 거래처와 품목을 함께 정합니다.
  final String? supplierItemId;

  /// id로 못 찾을 때 품목 이름 + [date]로 찾습니다.
  final String? itemName;

  /// YYYY-MM-DD. 있으면 그 거래를 선택합니다.
  final String? date;

  bool get isEmpty => supplierItemId == null && itemName == null;

  @override
  bool operator ==(Object other) =>
      other is TransactionsEntry &&
      other.supplierItemId == supplierItemId &&
      other.itemName == itemName &&
      other.date == date;

  @override
  int get hashCode => Object.hash(supplierItemId, itemName, date);
}

/// 화면의 필터·정렬·선택 상태.
class TransactionsFilter {
  const TransactionsFilter({
    this.items = const {},
    this.suppliers = const {},
    this.methods = const {},
    this.selectedId,
    this.fromSuppliers = false,
    this.sort = TransactionSort.date,
    this.descending = true,
  });

  final Set<String> items;
  final Set<String> suppliers;
  final Set<String> methods;
  final String? selectedId;

  /// Suppliers에서 넘어와 그 조건으로 걸러 보는 중. 필터를 바꾸면 꺼집니다.
  final bool fromSuppliers;
  final TransactionSort sort;
  final bool descending;

  bool get hasFilters =>
      items.isNotEmpty || suppliers.isNotEmpty || methods.isNotEmpty;

  TransactionsFilter copyWith({
    Set<String>? items,
    Set<String>? suppliers,
    Set<String>? methods,
    String? Function()? selectedId,
    bool? fromSuppliers,
    TransactionSort? sort,
    bool? descending,
  }) => TransactionsFilter(
    items: items ?? this.items,
    suppliers: suppliers ?? this.suppliers,
    methods: methods ?? this.methods,
    selectedId: selectedId == null ? this.selectedId : selectedId(),
    fromSuppliers: fromSuppliers ?? this.fromSuppliers,
    sort: sort ?? this.sort,
    descending: descending ?? this.descending,
  );
}

/// 같은 품목의 바로 이전 거래와 비교한 단가 변화.
class PriceChange {
  const PriceChange(this.previous, this.difference, this.percent);

  /// null이면 첫 거래.
  final PurchaseRecord? previous;
  final num difference;

  /// 소수 1자리로 반올림한 %.
  final num percent;

  bool get isFirst => previous == null;
}

/// 목록 한 줄.
class TransactionRow {
  const TransactionRow(this.record, this.change);

  final PurchaseRecord record;
  final PriceChange change;
}

/// 필터 선택지: 값 + 건수, 최근 거래순.
typedef FilterChoice = ({String value, int count});

/// 걸러진 목록과 표 머리·필터 선택지.
class TransactionListing {
  const TransactionListing({
    required this.rows,
    required this.totalAmount,
    required this.itemChoices,
    required this.supplierChoices,
    this.methodChoices = const [],
    required this.selected,
    required this.flow,
  });

  final List<TransactionRow> rows;
  final num totalAmount;
  final List<FilterChoice> itemChoices;
  final List<FilterChoice> supplierChoices;
  final List<FilterChoice> methodChoices;

  /// 고른 거래가 지금 목록에 있을 때만.
  final TransactionRow? selected;

  /// 고른 거래와 같은 품목의 거래, 오래된 순(단가 흐름).
  final List<PurchaseRecord> flow;

  static TransactionListing build(
    List<PurchaseRecord> records,
    TransactionsFilter filter, {
    required DateTime from,
    required DateTime to,
  }) {
    final newestFirst = [...records]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    PriceChange changeOf(PurchaseRecord record) {
      final previous = newestFirst
          .where(
            (other) =>
                other.itemName == record.itemName &&
                other.transactionDate.compareTo(record.transactionDate) < 0,
          )
          .firstOrNull;
      if (previous == null) return const PriceChange(null, 0, 0);
      final difference = record.unitPrice - previous.unitPrice;
      final percent = previous.unitPrice == 0
          ? 0
          : (difference / previous.unitPrice * 1000).round() / 10;
      return PriceChange(previous, difference, percent);
    }

    final rows = [
      for (final record in records)
        if ((filter.methods.isEmpty ||
                filter.methods.contains(record.confirmationMethod)) &&
            (filter.items.isEmpty || filter.items.contains(record.itemName)) &&
            (filter.suppliers.isEmpty ||
                filter.suppliers.contains(record.supplierName)) &&
            !record.date.isBefore(from) &&
            !record.date.isAfter(to))
          TransactionRow(record, changeOf(record)),
    ];
    num key(PurchaseRecord record) => switch (filter.sort) {
      TransactionSort.date => record.date.millisecondsSinceEpoch,
      TransactionSort.quantity => record.quantity,
      TransactionSort.unitPrice => record.unitPrice,
      TransactionSort.total => record.totalAmount,
    };
    rows.sort((a, b) {
      final byKey = key(a.record).compareTo(key(b.record));
      final ordered = filter.descending ? -byKey : byKey;
      // 같은 값은 날짜 최신순.
      return ordered != 0
          ? ordered
          : b.record.transactionDate.compareTo(a.record.transactionDate);
    });

    List<FilterChoice> choices(String Function(PurchaseRecord) of) {
      final counts = <String, int>{};
      for (final record in newestFirst) {
        counts.update(of(record), (n) => n + 1, ifAbsent: () => 1);
      }
      return [
        for (final MapEntry(:key, :value) in counts.entries)
          (value: key, count: value),
      ];
    }

    final selected = rows
        .where((row) => row.record.id == filter.selectedId)
        .firstOrNull;
    return TransactionListing(
      rows: List.unmodifiable(rows),
      totalAmount: rows.fold<num>(
        0,
        (sum, row) => sum + row.record.totalAmount,
      ),
      itemChoices: choices((record) => record.itemName),
      supplierChoices: choices((record) => record.supplierName),
      methodChoices: choices((record) => record.confirmationMethod ?? "")
          .where((c) => c.value.isNotEmpty)
          .toList(),
      selected: selected,
      flow: selected == null
          ? const []
          : newestFirst.reversed
                .where((record) => record.itemName == selected.record.itemName)
                .toList(),
    );
  }
}

/// Suppliers에서 넘어온 조건에 맞는 거래. 못 찾으면 null.
PurchaseRecord? findEntryRecord(
  List<PurchaseRecord> records,
  TransactionsEntry entry,
) {
  final newestFirst = [...records]
    ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  bool onDate(PurchaseRecord record) =>
      entry.date == null || record.transactionDate == entry.date;
  return newestFirst
          .where(
            (record) =>
                record.supplierItemId == entry.supplierItemId && onDate(record),
          )
          .firstOrNull ??
      (entry.itemName == null || entry.date == null
          ? null
          : newestFirst
                .where(
                  (record) =>
                      record.itemName == entry.itemName && onDate(record),
                )
                .firstOrNull);
}

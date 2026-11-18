import "package:flutter/material.dart";

import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/transaction_listing.dart";

/// 정렬 선택지 하나: 이름 + 기준 열 + 큰 값부터인지.
typedef TransactionSortChoice = ({
  String label,
  TransactionSort sort,
  bool descending,
});

/// 목록 위 오른쪽 정렬 선택 '최신순 ▾' (표 열 머리 정렬을 대신합니다).
/// 같은 값은 날짜 최신순([TransactionListing.build]). 모양은 [LdsSortButton].
class TransactionSortButton extends StatelessWidget {
  const TransactionSortButton({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final TransactionsFilter filter;
  final void Function(TransactionSort sort, {required bool descending})
  onChanged;

  static const List<TransactionSortChoice> choices = [
    (label: "최신순", sort: TransactionSort.date, descending: true),
    (label: "오래된순", sort: TransactionSort.date, descending: false),
    (label: "단가 높은순", sort: TransactionSort.unitPrice, descending: true),
    (label: "단가 낮은순", sort: TransactionSort.unitPrice, descending: false),
    (label: "총액 높은순", sort: TransactionSort.total, descending: true),
    (label: "총액 낮은순", sort: TransactionSort.total, descending: false),
    (label: "수량 많은순", sort: TransactionSort.quantity, descending: true),
    (label: "수량 적은순", sort: TransactionSort.quantity, descending: false),
  ];

  /// 지금 정렬의 이름.
  static String labelOf(TransactionsFilter filter) => choiceOf(filter).label;

  /// 지금 정렬에 맞는 선택지.
  static TransactionSortChoice choiceOf(TransactionsFilter filter) =>
      choices.firstWhere(
        (choice) =>
            choice.sort == filter.sort &&
            choice.descending == filter.descending,
        orElse: () => choices.first,
      );

  @override
  Widget build(BuildContext context) => LdsSortButton<TransactionSortChoice>(
    choices: [
      for (final choice in choices) LdsSortChoice(choice, choice.label),
    ],
    selected: choiceOf(filter),
    onChanged: (choice) =>
        onChanged(choice.sort, descending: choice.descending),
  );
}

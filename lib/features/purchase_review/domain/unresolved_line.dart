/// 검토 카드의 `unresolved`(서버가 남긴 미확인·보류 사유)를 담당자가 읽을 줄로
/// 바꿉니다. 서버 값에는 문장과 내부 표기가 섞여 옵니다:
///
/// - `COUNTER_OFFER HOLD: <사유 문장>` (드물게 `INFO_EXTRACTOR HOLD: …`)
/// - `<메일 ID> <파일명>: <읽지 못한 사유>`
/// - 필드 이름(`tax_terms`), `<업체 ID>.<필드>`, `<업체 ID>.cost:<비용 종류>`
/// - 에이전트가 직접 쓴 값: 한국어 문장, `S1.운송비`처럼 업체 이름표가 남은 표기
library;

import "purchase_review.dart";

class UnresolvedLine {
  const UnresolvedLine(this.text, {this.label, this.inCounterOffer = false});

  /// What the line is about: "역제안 보류", a supplier, a file name.
  final String? label;

  /// The sentence. Empty when [label] says it all.
  final String text;

  /// The counter-offer panel shows this very reason, so the notice only names
  /// it and points there.
  final bool inCounterOffer;

  @override
  String toString() =>
      "UnresolvedLine(${[?label, text].join(" | ")}"
      "${inCounterOffer ? ", inCounterOffer" : ""})";
}

final _hold = RegExp(r"^([A-Z][A-Z_]*) HOLD:\s*(.*)$", dotAll: true);
final _attachment = RegExp(
  r"^[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12} (.+): (.+)$",
  dotAll: true,
);
final _token = RegExp(r"^(?:([^\s.]+)\.)?(?:cost:([A-Z_]+)|([a-z_]+))$");

/// "<업체>.<한국어 항목>": the agent named the field itself.
final _named = RegExp(r"^([^\s.]+)\.([^\s.]*[가-힣][^\s.]*)$");

/// A supplier the card does not name: a UUID, or the agent's S1, S2 handle.
final _anonymous = RegExp(
  r"^(?:[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}|S\d+)$",
);
final _korean = RegExp("[가-힣]");

const _holdLabels = {"COUNTER_OFFER": "역제안 보류", "INFO_EXTRACTOR": "견적 읽기 보류"};

/// The card's unresolved entries as lines for the notice, in the server's
/// order. Fields left unknown are gathered per supplier; entries that are
/// neither a sentence nor a name this app knows are only counted.
List<UnresolvedLine> unresolvedLines(
  ReviewCard card, {
  List<QuoteVersion> quotes = const [],
}) {
  // Later entries win: the quote's own name over a card's fallback name.
  final suppliers = {
    if (card.counterOffer?.target case final target?)
      target.supplierId.toLowerCase(): target.supplierName,
    for (final plan in card.plans)
      for (final allocation in plan.allocations)
        allocation.supplierId.toLowerCase(): allocation.supplierName,
    for (final quote in quotes)
      quote.supplierId.toLowerCase(): quote.supplierName,
  };
  final offer = card.counterOffer;
  // In the server's order: a line, the fields unknown for one supplier
  // (_Fields), or one unread file (_File).
  final slots = <Object>[];
  final fields = <String, _Fields>{};
  final files = <String, _File>{};
  final seen = <String>{};
  var unreadable = 0;

  void add(UnresolvedLine line) {
    if (seen.add("${line.label}\n${line.text}")) slots.add(line);
  }

  // [prefix] is the part before the dot; null for a field of the request.
  void unknown(String? prefix, String field) {
    final supplier = prefix == null
        ? ""
        : suppliers[prefix.toLowerCase()] ??
              (_anonymous.hasMatch(prefix) ? "업체 미확인" : prefix);
    final group = fields.putIfAbsent(supplier, () {
      final group = _Fields(supplier);
      slots.add(group);
      return group;
    });
    if (!group.names.contains(field)) group.names.add(field);
  }

  for (final raw in card.unresolved) {
    final entry = raw.trim();
    if (entry.isEmpty) continue;

    final hold = _hold.firstMatch(entry);
    if (hold != null) {
      final reason = hold[2]!.trim();
      final shown =
          hold[1] == "COUNTER_OFFER" &&
          offer != null &&
          offer.onHold &&
          reason.isNotEmpty &&
          offer.reason?.trim() == reason;
      add(
        UnresolvedLine(
          shown ? "" : reason,
          label: _holdLabels[hold[1]] ?? "검토 보류",
          inCounterOffer: shown,
        ),
      );
      continue;
    }

    final attachment = _attachment.firstMatch(entry);
    if (attachment != null) {
      final name = attachment[1]!.trim();
      // The server writes None for a file without a name.
      final label = name.isEmpty || name == "None" ? "첨부 파일" : name;
      final reason = attachment[2]!.trim();
      // The same file name and reason from another mail is another file.
      files.putIfAbsent("$label\n$reason", () {
        final file = _File(label, reason);
        slots.add(file);
        return file;
      }).count++;
      continue;
    }

    final token = _token.firstMatch(entry);
    if (token != null) {
      final label = token[2] != null
          ? knownCostLabel(token[2]!)
          : knownFieldLabel(token[3]!);
      if (label == null) {
        unreadable++;
      } else {
        unknown(token[1], label);
      }
      continue;
    }

    final named = _named.firstMatch(entry);
    if (named != null) {
      unknown(named[1], named[2]!);
      continue;
    }

    if (_korean.hasMatch(entry)) {
      add(UnresolvedLine(entry));
    } else {
      unreadable++;
    }
  }

  return [
    for (final slot in slots)
      switch (slot) {
        _Fields(:final supplier, :final names) => UnresolvedLine(
          "${names.join(", ")} 미확인",
          label: supplier.isEmpty ? null : supplier,
        ),
        _File(:final label, :final reason, :final count) => UnresolvedLine(
          reason,
          label: count > 1 ? "$label $count건" : label,
        ),
        _ => slot as UnresolvedLine,
      },
    if (unreadable > 0) UnresolvedLine("그 밖에 확인하지 못한 항목 $unreadable건"),
  ];
}

class _Fields {
  _Fields(this.supplier);

  /// Empty for fields of the request itself.
  final String supplier;
  final names = <String>[];
}

class _File {
  _File(this.label, this.reason);

  final String label, reason;
  var count = 0;
}

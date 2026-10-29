/// Temporary app model; independent of the eventual database schema.
class RequestItem {
  const RequestItem({
    required this.id,
    required this.title,
    required this.supplier,
    required this.attachments,
    required this.status,
    required this.date,
    required this.time,
    required this.action,
  });

  final String id, title, supplier, status, date, time, action;
  final int attachments;

  RequestItem copyWith({String? status, String? action}) => RequestItem(
    id: id,
    title: title,
    supplier: supplier,
    attachments: attachments,
    status: status ?? this.status,
    date: date,
    time: time,
    action: action ?? this.action,
  );
}

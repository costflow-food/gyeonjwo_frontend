/// 화면용 원문 계약. API-25 메일 원문을 담습니다.
class SourceDocument {
  const SourceDocument({
    required this.title,
    required this.sender,
    required this.recipient,
    required this.receivedAt,
    required this.documentType,
    required this.paragraphs,
    this.highlights = const [],
    this.attachments = const [],
  });

  final String title, sender, recipient, receivedAt, documentType;
  final List<String> paragraphs, highlights, attachments;
}

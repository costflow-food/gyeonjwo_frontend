/// 화면용 원문 계약. 실제 메일/PDF 연결 전에는 합성 자료만 표시합니다.
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

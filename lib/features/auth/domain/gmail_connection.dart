enum GmailConnectionStatus {
  connected,
  partial,
  needsReconnect,
  failed,
  notConnected,
}

enum GmailConnectionPhase {
  connecting,
  connected,
  readDenied,
  sendDenied,
  bothDenied,
  failed,
  reconnect,
}

class GmailConnection {
  const GmailConnection({
    required this.status,
    this.email,
    this.canRead = false,
    this.canSend = false,
    this.watchStarted = false,
  });

  const GmailConnection.notConnected()
    : this(status: GmailConnectionStatus.notConnected);

  final GmailConnectionStatus status;
  final String? email;

  final bool canRead;

  final bool canSend;

  final bool watchStarted;

  bool get hasConnection =>
      status == GmailConnectionStatus.connected ||
      status == GmailConnectionStatus.partial;

  GmailConnectionPhase get phase => switch (status) {
    GmailConnectionStatus.failed => GmailConnectionPhase.failed,
    GmailConnectionStatus.needsReconnect ||
    GmailConnectionStatus.notConnected => GmailConnectionPhase.reconnect,
    GmailConnectionStatus.connected ||
    GmailConnectionStatus.partial => switch ((canRead, canSend)) {
      (true, true) => GmailConnectionPhase.connected,
      (false, true) => GmailConnectionPhase.readDenied,
      (true, false) => GmailConnectionPhase.sendDenied,
      (false, false) => GmailConnectionPhase.bothDenied,
    },
  };
}

class GmailCapabilities {
  const GmailCapabilities({
    required this.canRead,
    required this.canSend,
    this.isKnown = true,
  });

  static const none = GmailCapabilities(canRead: false, canSend: false);

  /// Server result not loaded yet; features stay off without a warning.
  static const unknown = GmailCapabilities(
    canRead: false,
    canSend: false,
    isKnown: false,
  );

  final bool canRead;
  final bool canSend;
  final bool isKnown;

  /// Show "permission missing" guidance only for a confirmed denial.
  bool get readDenied => isKnown && !canRead;
  bool get sendDenied => isKnown && !canSend;
}

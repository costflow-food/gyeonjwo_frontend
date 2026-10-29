/// Connection result decided by the server after checking the Google token.
enum GmailConnectionStatus { connected, partial, needsReconnect, failed, notConnected }

/// What the connection screen shows. Derived here, not in the View.
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

  /// Server-verified `gmail.readonly` grant.
  final bool canRead;

  /// Server-verified `gmail.send` grant. Separate from send approval settings.
  final bool canSend;

  /// Whether the server started automatic Gmail receiving.
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

/// Mail features the UI may enable. The server re-checks every request.
class GmailCapabilities {
  const GmailCapabilities({
    required this.canRead,
    required this.canSend,
    this.isKnown = true,
  });

  /// UI preview without Supabase settings keeps existing screens usable.
  static const preview = GmailCapabilities(canRead: true, canSend: true);
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

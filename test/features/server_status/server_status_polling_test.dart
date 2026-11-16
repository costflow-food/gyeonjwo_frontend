import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/server_status/data/server_status_repository_impl.dart";
import "package:gyeonjwo_frontend/features/server_status/domain/server_status.dart";
import "package:gyeonjwo_frontend/features/server_status/domain/server_status_repository.dart";
import "package:gyeonjwo_frontend/features/server_status/presentation/server_status_view_model.dart";
import "package:gyeonjwo_frontend/shared/app_visibility.dart";

class _Visible extends AppVisible {
  @override
  bool build() => true;

  void set(bool visible) => state = visible;
}

class _Repository implements ServerStatusRepository {
  int calls = 0;
  ServerStatus next = const ServerStatus(degraded: {});

  @override
  Future<ServerStatus> getStatus() async {
    calls++;
    return next;
  }
}

void main() {
  late _Repository repository;
  late ProviderContainer container;

  void open() {
    repository = _Repository();
    container = ProviderContainer(
      overrides: [
        serverStatusRepositoryProvider.overrideWithValue(repository),
        appVisibleProvider.overrideWith(_Visible.new),
      ],
    );
    // Stands in for the settings tile that watches the status.
    container.listen(serverStatusViewModelProvider, (_, _) {});
  }

  _Visible visibility() =>
      container.read(appVisibleProvider.notifier) as _Visible;

  testWidgets("reads once on entry, then once per three minutes", (
    tester,
  ) async {
    open();
    await tester.pump();
    expect(repository.calls, 1);

    await tester.pump(const Duration(seconds: 179));
    expect(repository.calls, 1);

    repository.next = const ServerStatus(degraded: {ServerFeature.rfqDispatch});
    await tester.pump(const Duration(seconds: 1));
    expect(repository.calls, 2);
    expect(container.read(serverStatusViewModelProvider).value?.degraded, {
      ServerFeature.rfqDispatch,
    });

    await tester.pump(const Duration(minutes: 3));
    expect(repository.calls, 3);
    container.dispose();
  });

  testWidgets("a hidden tab does not read; it catches up once when shown", (
    tester,
  ) async {
    open();
    await tester.pump();
    visibility().set(false);

    await tester.pump(const Duration(minutes: 30));
    expect(repository.calls, 1);

    visibility().set(true);
    await tester.pump();
    expect(repository.calls, 2);

    // Back on the normal schedule, not one read per visibility change.
    visibility().set(false);
    visibility().set(true);
    await tester.pump();
    expect(repository.calls, 2);
    await tester.pump(const Duration(minutes: 3));
    expect(repository.calls, 3);
    container.dispose();
  });

  testWidgets("showing the tab before a check is due reads nothing", (
    tester,
  ) async {
    open();
    await tester.pump();
    visibility().set(false);
    await tester.pump(const Duration(minutes: 1));
    visibility().set(true);
    await tester.pump();
    expect(repository.calls, 1);
    container.dispose();
  });

  testWidgets("an unreachable server is retried on the same schedule only", (
    tester,
  ) async {
    open();
    repository.next = ServerStatus.unknown;
    await tester.pump();
    await tester.pump(const Duration(minutes: 9));
    expect(repository.calls, 4);
    container.dispose();
  });

  testWidgets("stops reading when nothing watches the status", (tester) async {
    open();
    await tester.pump();
    container.dispose();
    await tester.pump(const Duration(minutes: 30));
    expect(repository.calls, 1);
  });
}

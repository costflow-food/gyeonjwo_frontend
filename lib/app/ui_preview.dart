import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/analysis_stop/presentation/analysis_stop_dialog.dart';
import '../features/analysis_stop/data/analysis_stop_data_source.dart';
import '../features/auth/data/auth_session_data_source.dart';
import '../features/auth/domain/gmail_connection.dart';
import '../features/auth/presentation/account_view.dart';
import '../features/auth/presentation/auth_connection_view.dart';
import '../features/auth/presentation/auth_permissions_view.dart';
import '../features/auth/presentation/login_view.dart';
import '../features/mail_draft/data/mail_draft_data_source.dart';
import '../features/mail_draft/presentation/mail_draft_dialog.dart';
import '../features/mail_intake/data/mail_intake_data_source.dart';
import '../features/mail_intake/presentation/mail_intake_dialog.dart';
import '../features/purchase_review/presentation/purchase_review_view.dart';
import '../features/purchase_review/data/purchase_review_data_source.dart';
import '../features/review_progress/presentation/review_progress_view.dart';
import '../features/send_settings/data/send_settings_data_source.dart';
import '../features/send_settings/presentation/send_settings_dialog.dart';
import '../features/source_document/data/source_document_data_source.dart';
import '../features/source_document/presentation/source_document_dialog.dart';
import '../features/supplier/domain/supplier_repository.dart';
import '../features/supplier/data/supplier_repository_impl.dart';
import '../features/supplier/data/supplier_data_source.dart';
import '../features/supplier/presentation/supplier_evidence_dialog.dart';
import '../features/supplier/presentation/supplier_view.dart';
import '../features/work_queue/data/work_queue_data_source.dart';
import '../features/work_queue/presentation/work_queue_view.dart';
import '../features/workflow_log/presentation/workflow_log_view.dart';
import '../features/workflow_log/data/workflow_log_data_source.dart';
import '../shared/app_font_sizes.dart';
import '../shared/preview_workspace.dart';
import '../shared/widgets/outline_panel.dart';
import '../shared/widgets/workspace_button_styles.dart';
import '../shared/workspace_colors.dart';

const _sampleCase = 'REQ-2026-1019-003';

/// A separate router and provider container keep UI checks out of the user's
/// session and preserve the normal navigation behavior of the real widgets.
class UiPreviewApp extends StatefulWidget {
  const UiPreviewApp({super.key, this.parameters = const {}, this.theme});
  final Map<String, String> parameters;
  final ThemeData? theme;

  @override
  State<UiPreviewApp> createState() => _UiPreviewAppState();
}

class _UiPreviewAppState extends State<UiPreviewApp> {
  late ProviderContainer _container;
  late GoRouter _router;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _initialize(widget.parameters);
  }

  void _initialize(Map<String, String> parameters) {
    final store = PreviewWorkspace();
    _container = ProviderContainer(
      overrides: [
        authSessionDataSourceProvider.overrideWithValue(
          const UnconfiguredAuthSessionDataSource(),
        ),
        previewWorkspaceProvider.overrideWith((ref) => store),
        workQueueDataSourceProvider.overrideWith(
          (ref) => PreviewWorkQueueDataSource(
            workspace: store,
            latency: Duration.zero,
          ),
        ),
        sourceDocumentDataSourceProvider.overrideWith(
          (ref) => PreviewSourceDocumentDataSource(workspace: store),
        ),
        mailDraftDataSourceProvider.overrideWith(
          (ref) => PreviewMailDraftDataSource(
            workspace: store,
            latency: Duration.zero,
          ),
        ),
        sendSettingsDataSourceProvider.overrideWith(
          (ref) => PreviewSendSettingsDataSource(
            workspace: store,
            latency: Duration.zero,
          ),
        ),
        mailIntakeDataSourceProvider.overrideWith(
          (ref) => PreviewMailIntakeDataSource(
            workspace: store,
            latency: Duration.zero,
          ),
        ),
        purchaseReviewDataSourceProvider.overrideWithValue(
          const PreviewPurchaseReviewDataSource(latency: Duration.zero),
        ),
        analysisStopDataSourceProvider.overrideWithValue(
          const PreviewAnalysisStopDataSource(latency: Duration.zero),
        ),
        supplierDataSourceProvider.overrideWith(
          (ref) => PreviewSupplierDataSource(latency: Duration.zero),
        ),
        workflowLogDataSourceProvider.overrideWithValue(
          const PreviewWorkflowLogDataSource(latency: Duration.zero),
        ),
      ],
    );
    _router = _createRouter(parameters);
  }

  GoRouter _createRouter(Map<String, String> parameters) {
    return GoRouter(
      initialLocation: _initialLocation(parameters),
      overridePlatformDefaultLocation: true,
      routerNeglect: true,
      routes: [
        ShellRoute(
          builder: (context, state, child) => Column(
            children: [
              Material(
                color: canvas,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'UI 확인 · 시연 데이터',
                          style: TextStyle(
                            fontSize: AppFontSizes.body,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton.icon(
                          style: WorkspaceButtonStyles.text,
                          onPressed: () => _router.go('/ui-preview'),
                          icon: const Icon(Icons.grid_view, size: 16),
                          label: const Text('화면 목록'),
                        ),
                        TextButton.icon(
                          style: WorkspaceButtonStyles.text,
                          onPressed: _reset,
                          icon: const Icon(Icons.restart_alt, size: 16),
                          label: const Text('시연 초기화'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
          routes: [
            GoRoute(
              path: '/ui-preview',
              builder: (context, state) => _PreviewCatalog(
                key: ValueKey(state.uri.toString()),
                modal: state.uri.queryParameters['modal'],
                draftId: state.uri.queryParameters['draftId'],
              ),
            ),
            GoRoute(
              path: '/',
              builder: (context, state) => const WorkQueueView(),
            ),
            GoRoute(
              path: '/review',
              builder: (context, state) => PurchaseReviewView(
                requestId:
                    state.uri.queryParameters['requestId'] ?? _sampleCase,
              ),
            ),
            GoRoute(
              path: '/logs',
              builder: (context, state) => const WorkflowLogView(),
            ),
            GoRoute(
              path: '/suppliers',
              builder: (context, state) => const SupplierView(),
            ),
            GoRoute(
              path: '/account',
              builder: (context, state) => const AccountView(),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginView(),
            ),
            GoRoute(
              path: '/login/permissions',
              builder: (context, state) => const AuthPermissionsView(),
            ),
            GoRoute(
              path: '/login/connection',
              builder: (context, state) => AuthConnectionView(
                previewPhase:
                    GmailConnectionPhase.values
                        .where(
                          (phase) =>
                              phase.name == state.uri.queryParameters['state'],
                        )
                        .firstOrNull ??
                    GmailConnectionPhase.connected,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _initialLocation(Map<String, String> parameters) =>
      switch (parameters['screen']) {
        'queue' => '/',
        'review' => '/review',
        'logs' => '/logs',
        'suppliers' => '/suppliers',
        'account' => '/account',
        'login' => '/login',
        'permissions' => '/login/permissions',
        'connection' => Uri(
          path: '/login/connection',
          queryParameters: {'state': parameters['state'] ?? 'connected'},
        ).toString(),
        _ => Uri(
          path: '/ui-preview',
          queryParameters: {
            if (parameters['screen'] != null) 'modal': parameters['screen']!,
            if (parameters['draftId'] != null)
              'draftId': parameters['draftId']!,
          },
        ).toString(),
      };

  void _reset() {
    final previousRouter = _router;
    final previousContainer = _container;
    setState(() {
      _generation++;
      _initialize(const {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousRouter.dispose();
      previousContainer.dispose();
    });
  }

  @override
  void didUpdateWidget(UiPreviewApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.parameters, widget.parameters)) {
      final previous = _router;
      _generation++;
      _router = _createRouter(widget.parameters);
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  @override
  void dispose() {
    _router.dispose();
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
    key: ValueKey(_generation),
    container: _container,
    child: MaterialApp.router(
      title: '견줘 · UI 확인',
      debugShowCheckedModeBanner: false,
      theme: widget.theme ?? Theme.of(context),
      routerConfig: _router,
    ),
  );
}

class _PreviewCatalog extends ConsumerStatefulWidget {
  const _PreviewCatalog({super.key, this.modal, this.draftId});
  final String? modal;
  final String? draftId;

  @override
  ConsumerState<_PreviewCatalog> createState() => _PreviewCatalogState();
}

class _PreviewCatalogState extends ConsumerState<_PreviewCatalog> {
  @override
  void initState() {
    super.initState();
    if (widget.modal != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openModal(widget.modal!);
      });
    }
  }

  Future<void> _openModal(String modal) async {
    switch (modal) {
      case 'source':
        await showSourceDocument(context, requestId: _sampleCase);
      case 'progress':
        await showReviewProgressDialog(
          context,
          requestId: _sampleCase,
          supplier: 'A사',
        );
      case 'needs-info':
        await showAnalysisStopDialog(
          context,
          requestId: 'REQ-2026-1018-003',
          onOpenSource: () =>
              showSourceDocument(context, requestId: 'REQ-2026-1018-003'),
        );
      case 'mail-draft':
        await showMailDraftDialog(
          context,
          caseId: _sampleCase,
          draftId: widget.draftId,
        );
      case 'send-settings':
        await showSendSettingsDialog(context);
      case 'case-settings':
        await showSendSettingsDialog(context, caseId: _sampleCase);
      case 'intake':
        await showMailIntakeDialog(context);
      case 'supplier-evidence':
        final SupplierRepository repository = ref.read(
          supplierRepositoryProvider,
        );
        final supplier = await repository.getSupplier(
          'bfe4fb8c-eaf8-45e3-8eb7-7def7777a001',
        );
        if (!mounted) return;
        await showSupplierEvidenceDialog(
          context,
          supplier: supplier,
          item: supplier.items.first,
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '화면·모달 미리보기',
                style: TextStyle(
                  fontSize: AppFontSizes.pageTitle,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '로그인과 실제 메일 발송 없이 화면을 확인합니다. 시연 초기화를 누르면 변경한 데이터가 원래 상태로 돌아갑니다.',
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  color: muted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              OutlinePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '기본 화면',
                      style: TextStyle(
                        fontSize: AppFontSizes.cardTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final (label, path) in const [
                          ('업무 큐', '/'),
                          ('구매 검토', '/review'),
                          ('실행 로그', '/logs'),
                          ('거래처', '/suppliers'),
                          ('로그인', '/login'),
                          ('권한 안내', '/login/permissions'),
                          ('Gmail 연결 상태', '/login/connection'),
                          ('계정 설정', '/account'),
                        ])
                          OutlinedButton(
                            style: WorkspaceButtonStyles.outlined,
                            onPressed: () => context.go(path),
                            child: Text(label),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '모달',
                      style: TextStyle(
                        fontSize: AppFontSizes.cardTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final (label, modal) in const [
                          ('원문·첨부', 'source'),
                          ('검토 진행', 'progress'),
                          ('확인 필요', 'needs-info'),
                          ('거래처·가격 근거', 'supplier-evidence'),
                          ('메일 초안·발송', 'mail-draft'),
                          ('메일함 발송 설정', 'send-settings'),
                          ('업무별 발송 설정', 'case-settings'),
                          ('접수·연결 확인', 'intake'),
                        ])
                          OutlinedButton(
                            style: WorkspaceButtonStyles.outlined,
                            onPressed: () => _openModal(modal),
                            child: Text(label),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '메일 초안에서 업체별 초안·발송됨·실패·확인 중 상태를, Gmail 연결 화면에서 권한별 상태를 선택할 수 있습니다.',
                      style: TextStyle(
                        fontSize: AppFontSizes.secondary,
                        color: muted,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

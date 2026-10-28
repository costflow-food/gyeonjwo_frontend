import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_font_sizes.dart';
import '../../features/auth/presentation/widgets/sign_out_action.dart';
import '../workspace_colors.dart';
import 'brand_logo.dart';

class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({super.key, required this.onCollapse});
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final isAccount = GoRouterState.of(context).uri.path == '/account';
    return Material(
      color: canvas,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(child: BrandLogo()),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: '사이드바 접기',
                                onPressed: onCollapse,
                                icon: const Icon(Icons.chevron_left, size: 20),
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(36, 36),
                                  maximumSize: const Size(36, 36),
                                  padding: const EdgeInsets.all(6),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  side: const BorderSide(color: line),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'PURCHASING WORKSPACE',
                            style: TextStyle(
                              fontSize: 9,
                              color: muted,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 36),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.layers_outlined,
                                  size: 17,
                                  color: muted,
                                ),
                                SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    '구매 검토',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            minLeadingWidth: 18,
                            selected: !isAccount,
                            selectedColor: accent,
                            selectedTileColor: blush,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                            leading: const Icon(Icons.inbox_outlined, size: 19),
                            title: const Text(
                              '업무 큐',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                '6',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            onTap: () {
                              context.go('/');
                            },
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: line),
                          const SizedBox(height: 14),
                          const Text(
                            '판단에 필요한 근거를 한곳에.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final (index, text) in [
                            '요청 내용 확인',
                            '구매 근거와 거래처 비교',
                            '비용 영향 검토',
                          ].indexed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 11),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: muted,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      text,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 14),
                          const Divider(color: line),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => context.go('/account'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isAccount ? blush : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: canvas,
                                    foregroundColor: muted,
                                    child: Icon(Icons.person_outline, size: 20),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '구매담당자',
                                          style: TextStyle(
                                            fontSize: AppFontSizes.body,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          '계정 설정',
                                          style: TextStyle(
                                            fontSize: AppFontSizes.secondary,
                                            color: muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.settings_outlined,
                                    size: 16,
                                    color: muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) => TextButton.icon(
                              onPressed: () => signOutAndLeave(context, ref),
                              icon: const Icon(Icons.logout, size: 16),
                              label: const Text(
                                '로그아웃',
                                style: TextStyle(fontSize: AppFontSizes.button),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

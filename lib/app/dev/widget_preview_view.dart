import 'package:flutter/material.dart';

import '../../shared/lds_colors.dart';
import '../../shared/widgets/lds/lds.dart';

/// LDS 공통 위젯 미리보기 (KAN-320). debug 빌드에서만 `/dev/widgets`로 열리고
/// 로그인 없이 볼 수 있습니다. 예시 값은 SSOT 문서의 예시를 그대로 씁니다.
class WidgetPreviewView extends StatefulWidget {
  const WidgetPreviewView({super.key});

  @override
  State<WidgetPreviewView> createState() => _WidgetPreviewViewState();
}

class _WidgetPreviewViewState extends State<WidgetPreviewView> {
  bool _toggleMedium = true;
  bool _toggleSmall = false;
  String _radio = '격식체';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: LdsColors.canvas,
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LDS 공통 위젯 미리보기',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '기준: docs/design-ssot.md · KAN-320 · debug 빌드 전용',
                style: TextStyle(fontSize: 13, color: LdsColors.muted),
              ),
              _Section(
                title: '버튼 (7.4)',
                children: [
                  for (final size in LdsButtonSize.values)
                    _Row(
                      label: size.name,
                      children: [
                        for (final variant in LdsButtonVariant.values)
                          LdsButton(
                            label: variant == LdsButtonVariant.filled
                                ? '승인 후 발송'
                                : '보내지 않음',
                            variant: variant,
                            size: size,
                            onPressed: () {},
                          ),
                        LdsButton(
                          label: '거래처 등록',
                          icon: Icons.add,
                          size: size,
                          onPressed: () {},
                        ),
                        LdsButton(label: '비활성', size: size, onPressed: null),
                        LdsButton(
                          label: '비활성',
                          variant: LdsButtonVariant.outlined,
                          size: size,
                          onPressed: null,
                        ),
                        LdsButton(
                          label: '설정 저장',
                          size: size,
                          loading: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  _Row(
                    label: '아이콘 (7.4.4)',
                    children: [
                      LdsIconButton(
                        icon: Icons.search,
                        tooltip: '검색',
                        onPressed: () {},
                      ),
                      LdsIconButton(
                        icon: Icons.notifications_none,
                        tooltip: '알림',
                        onPressed: () {},
                      ),
                      const LdsIconButton(
                        icon: Icons.refresh,
                        tooltip: '새로고침',
                        onPressed: null,
                      ),
                    ],
                  ),
                ],
              ),
              _Section(
                title: '라벨 (4.1)',
                children: [
                  for (final style in LdsTagStyle.values)
                    for (final size in LdsTagSize.values)
                      _Row(
                        label: '${style.name} · ${size.name}',
                        children: [
                          for (final tone in LdsTagTone.values)
                            LdsTag(
                              _toneLabel(tone),
                              tone: tone,
                              style: style,
                              size: size,
                            ),
                          LdsTag(
                            '첨부',
                            icon: Icons.attach_file,
                            style: style,
                            size: size,
                          ),
                        ],
                      ),
                ],
              ),
              _Section(
                title: '숫자 배지 (4.2)',
                children: [
                  _Row(
                    label: 'primary · dark · neutral',
                    children: [
                      for (final tone in LdsBadgeTone.values) ...[
                        LdsBadge(3, tone: tone),
                        LdsBadge(16, tone: tone),
                        LdsBadge(128, tone: tone),
                      ],
                    ],
                  ),
                ],
              ),
              _Section(
                title: '토글 (5) · 라디오 (6.2)',
                children: [
                  _Row(
                    label: '토글',
                    children: [
                      LdsToggle(
                        value: _toggleMedium,
                        semanticLabel: '자동 발송',
                        onChanged: (v) => setState(() => _toggleMedium = v),
                      ),
                      LdsToggle(
                        value: _toggleSmall,
                        size: LdsToggleSize.small,
                        semanticLabel: '자동 발송 (small)',
                        onChanged: (v) => setState(() => _toggleSmall = v),
                      ),
                      const LdsToggle(value: true, onChanged: null),
                      const LdsToggle(value: false, onChanged: null),
                    ],
                  ),
                  _Row(
                    label: '라디오',
                    children: [
                      for (final tone in ['격식체', '부드러운 존댓말'])
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LdsRadio<String>(
                              value: tone,
                              groupValue: _radio,
                              semanticLabel: tone,
                              onChanged: (v) => setState(() => _radio = v),
                            ),
                            const SizedBox(width: 8),
                            Text(tone, style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      const LdsRadio<String>(
                        value: '비활성',
                        groupValue: null,
                        onChanged: null,
                      ),
                    ],
                  ),
                ],
              ),
              _Section(
                title: '진행 단계 (8.2)',
                children: [
                  for (final current in [3, 5, null])
                    LdsStepBar(
                      current: current,
                      steps: const [
                        LdsStep('요청 확인', caption: '10.19 11:10'),
                        LdsStep('후보 찾기'),
                        LdsStep('견적 요청'),
                        LdsStep('회신'),
                        LdsStep('검토 카드'),
                      ],
                    ),
                ],
              ),
              _Section(
                title: '모달 틀 (8.1)',
                children: [
                  LdsButton(
                    label: '모달 열기',
                    variant: LdsButtonVariant.outlinedNeutral,
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => LdsDialog(
                        title: '메일 초안·발송',
                        subtitle: '[단가변경] 11월 냉동 딸기 공급단가 조정 안내',
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('보내지 않음'),
                          ),
                          LdsButton(
                            label: '승인 후 발송',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                        child: const LdsKeyValueTable(
                          rows: [
                            LdsKeyValueRow(
                              '받는 사람',
                              text: 'sales@a-supplier.example.com',
                            ),
                            LdsKeyValueRow(
                              '제목',
                              text: '[견줘] 11월 냉동 딸기 공급단가 조정 관련 회신',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const _Section(
                title: '이름표-값 표 (9.1 · 7.11)',
                children: [
                  LdsKeyValueTable(
                    rows: [
                      LdsKeyValueRow('사업자번호', text: '214-81-00001'),
                      LdsKeyValueRow('담당자', text: '김영업'),
                      LdsKeyValueRow(
                        '이메일',
                        text: 'sales@a-supplier.example.com',
                      ),
                      LdsKeyValueRow(
                        '기준자료',
                        text: '기존 거래 계약서',
                        trailing: LdsTag('확인됨', tone: LdsTagTone.success),
                      ),
                    ],
                  ),
                ],
              ),
              const _Section(
                title: '목록 표 (9.2)',
                children: [
                  LdsListTable(
                    columns: [
                      LdsColumn('적용일'),
                      LdsColumn('단가'),
                      LdsColumn('조건', flex: 2, alignStart: true),
                      LdsColumn('출처', flex: 2, alignStart: true),
                    ],
                    rows: [
                      LdsListRow(latest: true, [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('2026.11.01'),
                            SizedBox(width: 6),
                            LdsLatestTag(),
                          ],
                        ),
                        LdsNumberUnit('5,500', '원/kg'),
                        Text('월 1,000kg 기준'),
                        Text('단가변경 안내 메일'),
                      ]),
                      LdsListRow([
                        Text('2026.05.01'),
                        LdsNumberUnit('5,000', '원/kg'),
                        Text('기본 조건'),
                        Text('상반기 견적 메일'),
                      ]),
                    ],
                  ),
                ],
              ),
              const _Section(
                title: '비교 표 (9.3)',
                children: [
                  LdsCompareTable(
                    options: [
                      LdsCompareOption('한라푸드'),
                      LdsCompareOption('바른채소', recommended: true),
                      LdsCompareOption('남도청과'),
                    ],
                    rows: [
                      LdsCompareRow('단가', [
                        LdsNumberUnit('5,800', '원/kg'),
                        LdsNumberUnit('5,400', '원/kg'),
                        LdsNumberUnit('5,300', '원/kg'),
                      ]),
                      LdsCompareRow('운송비', [
                        Text('단가에 포함'),
                        Text('단가에 포함'),
                        Text('확인 필요'),
                      ]),
                      LdsCompareRow('공급 가능량', [
                        Text('1,000kg'),
                        Text('1,000kg'),
                        Text('확인 필요'),
                      ]),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  static String _toneLabel(LdsTagTone tone) => switch (tone) {
    LdsTagTone.enabled => '대기',
    LdsTagTone.error => '실패',
    LdsTagTone.progressing => '진행 중',
    LdsTagTone.warning => '확인 필요',
    LdsTagTone.success => '완료',
  };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        for (final child in children) ...[child, const SizedBox(height: 12)],
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: 160,
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: LdsColors.muted),
        ),
      ),
      Expanded(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ),
      ),
    ],
  );
}

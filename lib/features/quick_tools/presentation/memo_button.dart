import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../../shared/lds_colors.dart";
import "../../../shared/preferences.dart";
import "../../../shared/widgets/lds/lds.dart";
import "../../auth/presentation/auth_session_view_model.dart";

/// 상단 바 메모. 브라우저 저장소에 남겨 새로고침해도 유지합니다(이 브라우저
/// 에서만 보이고 서버에는 보내지 않습니다).
class QuickMemo extends Notifier<String> {
  /// 저장 이름. 같은 브라우저를 여러 계정이 써도 섞이지 않게 계정별로 둡니다.
  static String keyFor(String? email) =>
      email == null || email.isEmpty ? "quick_memo" : "quick_memo:$email";

  late String _key;

  /// 적을 수 있는 글자 수.
  static const maxLength = 5000;

  SharedPreferences? get _preferences {
    try {
      return ref.read(sharedPreferencesProvider);
    } on Object {
      // 저장소를 못 쓰는 환경(테스트 등)은 메모리에만 둡니다.
      return null;
    }
  }

  @override
  String build() {
    // 계정이 바뀌면(로그아웃·다른 계정 로그인) 그 계정의 메모로 바꿉니다.
    _key = keyFor(
      ref.watch(
        authSessionViewModelProvider.select((s) => s.asData?.value.email),
      ),
    );
    return _preferences?.getString(_key) ?? "";
  }

  /// 다른 탭에서 고친 메모를 다시 읽습니다. 바뀌었으면 true.
  Future<bool> reload() async {
    final preferences = _preferences;
    if (preferences == null) return false;
    final key = _key;
    await preferences.reload();
    if (!ref.mounted || key != _key) return false;
    final saved = preferences.getString(key) ?? "";
    if (saved == state) return false;
    state = saved;
    return true;
  }

  /// 적을 때마다 바로 저장합니다.
  void save(String text) {
    if (text == state) return;
    state = text;
    if (text.isEmpty) {
      _preferences?.remove(_key);
    } else {
      _preferences?.setString(_key, text);
    }
  }
}

final quickMemoProvider = NotifierProvider<QuickMemo, String>(QuickMemo.new);

/// 상단 바 메모 단추: 누르면 단추 오른쪽 끝에 맞춘 팝오버(폭 320)에 메모
/// 칸. 적어 둔 메모가 있으면 오른쪽 위 주황 점. Esc·바깥 누르기로 닫습니다.
class MemoButton extends ConsumerWidget {
  const MemoButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMemo = ref.watch(
      quickMemoProvider.select((memo) => memo.trim().isNotEmpty),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Builder(
          builder: (context) => LdsIconButton(
            icon: Icons.sticky_note_2_outlined,
            tooltip: hasMemo ? "메모, 적어 둔 메모 있음" : "메모",
            onPressed: () => Navigator.of(context).push(
              LdsPopoverRoute<void>(
                anchor: LdsPopoverRoute.anchorOf(context),
                label: "메모 닫기",
                child: const MemoPanel(),
              ),
            ),
          ),
        ),
        if (hasMemo)
          const Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: SizedBox.square(
                dimension: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: LdsColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MemoPanel extends ConsumerStatefulWidget {
  const MemoPanel({super.key});

  static const width = 320.0;
  static const hint = "전화 메모, 확인할 것 등을 적어 두세요";
  static const note = "적는 대로 이 브라우저에 저장돼요";

  @override
  ConsumerState<MemoPanel> createState() => _MemoPanelState();
}

class _MemoPanelState extends ConsumerState<MemoPanel> {
  late final _text = TextEditingController(text: ref.read(quickMemoProvider));

  @override
  void initState() {
    super.initState();
    // 다른 탭에서 고쳤으면 그 내용으로 엽니다(아직 여기서 적기 전일 때만).
    final opened = _text.text;
    ref.read(quickMemoProvider.notifier).reload().then((changed) {
      if (changed && mounted && _text.text == opened) {
        _text.text = ref.read(quickMemoProvider);
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(LdsRadius.button),
      borderSide: BorderSide(color: color),
    );
    final length = ref.watch(quickMemoProvider).characters.length;
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: "메모",
      child: SizedBox(
        width: MemoPanel.width,
        // 창이 낮으면 넘치지 않고 스크롤합니다.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "메모",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: LdsColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: TextField(
                  controller: _text,
                  autofocus: true,
                  expands: true,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(QuickMemo.maxLength),
                  ],
                  onChanged: ref.read(quickMemoProvider.notifier).save,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: LdsColors.ink,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: MemoPanel.hint,
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: LdsColors.disabled,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    filled: true,
                    fillColor: Colors.white,
                    border: border(LdsColors.borderStrong),
                    enabledBorder: border(LdsColors.borderStrong),
                    focusedBorder: border(LdsColors.title),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      MemoPanel.note,
                      style: TextStyle(fontSize: 12, color: LdsColors.muted),
                    ),
                  ),
                  Text(
                    "$length/${QuickMemo.maxLength}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: LdsColors.muted,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

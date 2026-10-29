import "dart:convert";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/workspace_colors.dart";
import "../domain/supplier.dart";
import "supplier_form_controllers.dart";
import "supplier_view_model.dart";
import "widgets/supplier_basic_form.dart";
import "widgets/supplier_item_form_list.dart";
import "widgets/supplier_register_footer.dart";
import "widgets/supplier_register_header.dart";

/// 거래처 등록 모달을 엽니다. Returns the created supplier on success.
///
/// The server stores the record, decides the owner, and derives item keys;
/// this screen never writes to the database directly.
Future<SupplierDetail?> showSupplierRegisterDialog(BuildContext context) {
  return showDialog<SupplierDetail>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (context) => const SupplierRegisterDialog(),
  );
}

class SupplierRegisterDialog extends ConsumerStatefulWidget {
  const SupplierRegisterDialog({super.key});

  @override
  ConsumerState<SupplierRegisterDialog> createState() =>
      _SupplierRegisterDialogState();
}

class _SupplierRegisterDialogState
    extends ConsumerState<SupplierRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _random = Random.secure();
  final _basic = SupplierBasicFields();
  final List<SupplierItemFields> _items = [SupplierItemFields()];

  bool _dirty = false;
  bool _submitting = false;
  String? _error;

  // Same body retries with the same key; a changed body gets a new key.
  String? _pendingKey;
  String? _pendingBody;

  @override
  void dispose() {
    _basic.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  String _newKey() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, "0")).join();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = _basic.toDraft([for (final item in _items) item.toDraft()]);
    final body = jsonEncode(draft.toJson());
    if (_pendingBody != body) {
      _pendingKey = _newKey();
      _pendingBody = body;
    }
    setState(() => _submitting = true);
    try {
      final created = await ref
          .read(supplierListViewModelProvider.notifier)
          .register(draft, idempotencyKey: _pendingKey!);
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on SupplierFailure catch (failure) {
      if (!mounted) return;
      // A request still in progress may only be checked with the same key.
      if (failure.code != "REQUEST_IN_PROGRESS") {
        _pendingKey = null;
        _pendingBody = null;
      }
      setState(() {
        _submitting = false;
        _error = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      // Unknown outcome: keep the key so a retry cannot create a duplicate.
      setState(() {
        _submitting = false;
        _error = "등록 결과를 확인하지 못했습니다. 다시 등록을 누르면 같은 요청으로 확인합니다.";
      });
    }
  }

  Future<void> _close() async {
    if (_submitting) return;
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("입력한 내용을 버릴까요?"),
        content: const Text("등록하지 않은 거래처 정보는 저장되지 않습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("계속 입력"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("변경사항 버리기"),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  void _addItem() {
    setState(() {
      _items.add(SupplierItemFields());
      _dirty = true;
    });
  }

  void _removeItem(SupplierItemFields item) {
    setState(() {
      _items.remove(item);
      _dirty = true;
    });
    // Dispose after the removed fields have left the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => item.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty && !_submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Dialog(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: line),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            onChanged: _markDirty,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SupplierRegisterHeader(onClose: _close),
                const Divider(height: 1, color: line),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: AbsorbPointer(
                      absorbing: _submitting,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SupplierBasicForm(fields: _basic),
                          const SizedBox(height: 28),
                          SupplierItemFormList(
                            items: _items,
                            onAdd: _addItem,
                            onRemove: _removeItem,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: line),
                SupplierRegisterFooter(
                  error: _error,
                  submitting: _submitting,
                  onCancel: _close,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

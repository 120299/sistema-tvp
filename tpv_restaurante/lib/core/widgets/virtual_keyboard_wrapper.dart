import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/providers.dart';
import 'virtual_keyboard.dart';

final _keyboardControllerProvider = StateProvider<TextEditingController?>(
  (ref) => null,
);
final _keyboardVisibleProvider = StateProvider<bool>((ref) => false);

class VirtualKeyboardWrapper extends ConsumerWidget {
  final Widget child;

  const VirtualKeyboardWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceInfoAsync = ref.watch(deviceInputInfoProvider);
    final keyboardHeight = MediaQuery.of(context).size.height * 0.28;

    final shouldShow = deviceInfoAsync.maybeWhen(
      data: (info) => info.shouldShowVirtualKeyboard,
      orElse: () => false,
    );

    if (!shouldShow) {
      return child;
    }

    return Column(
      children: [
        Expanded(child: child),
        ref.watch(_keyboardVisibleProvider)
            ? VirtualKeyboard(
                controller:
                    ref.read(_keyboardControllerProvider) ??
                    TextEditingController(),
                height: keyboardHeight,
                onClose: () {
                  ref.read(_keyboardVisibleProvider.notifier).state = false;
                },
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}

class VirtualKeyboardTrigger extends ConsumerStatefulWidget {
  final Widget child;
  final TextEditingController controller;

  const VirtualKeyboardTrigger({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  ConsumerState<VirtualKeyboardTrigger> createState() =>
      _VirtualKeyboardTriggerState();
}

class _VirtualKeyboardTriggerState
    extends ConsumerState<VirtualKeyboardTrigger> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    final deviceInfoAsync = ref.read(deviceInputInfoProvider);
    final shouldShow = deviceInfoAsync.maybeWhen(
      data: (info) => info.shouldShowVirtualKeyboard,
      orElse: () => false,
    );

    if (shouldShow) {
      final selection = widget.controller.selection;
      if (selection.isValid) {
        ref.read(_keyboardControllerProvider.notifier).state =
            widget.controller;
        ref.read(_keyboardVisibleProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfoAsync = ref.watch(deviceInputInfoProvider);
    final shouldShow = deviceInfoAsync.maybeWhen(
      data: (info) => info.shouldShowVirtualKeyboard,
      orElse: () => false,
    );

    return GestureDetector(
      onTap: () {
        if (shouldShow) {
          widget.controller.selection = TextSelection.collapsed(
            offset: widget.controller.text.length,
          );
          ref.read(_keyboardControllerProvider.notifier).state =
              widget.controller;
          ref.read(_keyboardVisibleProvider.notifier).state = true;
        }
      },
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}

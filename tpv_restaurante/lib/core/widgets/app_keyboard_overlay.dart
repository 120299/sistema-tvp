import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/providers.dart';
import 'tpv_keyboard.dart';

class AppKeyboardOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const AppKeyboardOverlay({super.key, required this.child});

  @override
  ConsumerState<AppKeyboardOverlay> createState() => _AppKeyboardOverlayState();
}

class _AppKeyboardOverlayState extends ConsumerState<AppKeyboardOverlay> {
  FocusNode? _lastFocusedNode;
  TextEditingController? _currentController;
  bool _isProcessingFocus = false;

  @override
  Widget build(BuildContext context) {
    final keyboardSettings = ref.watch(keyboardSettingsProvider);
    final isKeyboardVisible =
        _lastFocusedNode != null &&
        _currentController != null &&
        keyboardSettings.useVirtualKeyboard;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        _checkForTextFieldFocus();
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          Future.delayed(const Duration(milliseconds: 100), () {
            _checkForTextFieldFocus();
          });
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            widget.child,
            if (isKeyboardVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: TPVKeyboard(
                  controller: _currentController!,
                  onClose: () {
                    setState(() {
                      _lastFocusedNode = null;
                      _currentController = null;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _checkForTextFieldFocus() {
    if (_isProcessingFocus) return;
    _isProcessingFocus = true;

    try {
      final primaryFocus = FocusManager.instance.primaryFocus;
      final keyboardSettings = ref.read(keyboardSettingsProvider);

      if (primaryFocus == null || !keyboardSettings.useVirtualKeyboard) {
        if (_lastFocusedNode != null) {
          setState(() {
            _lastFocusedNode = null;
            _currentController = null;
          });
        }
        return;
      }

      final context = primaryFocus.context;
      if (context == null) return;

      final widget = context.widget;

      TextEditingController? controller;

      if (widget is TextField) {
        controller = widget.controller;
      } else if (widget is TextFormField) {
        controller = widget.controller;
      } else if (widget is EditableText) {
        controller = widget.controller;
      } else {
        controller = _findControllerInElement(context as Element);
      }

      if (controller != null && controller != _currentController) {
        setState(() {
          _lastFocusedNode = primaryFocus;
          _currentController = controller;
        });
      }
    } finally {
      _isProcessingFocus = false;
    }
  }

  TextEditingController? _findControllerInElement(Element element) {
    final widget = element.widget;
    if (widget is TextField) {
      return widget.controller;
    }
    if (widget is TextFormField) {
      return widget.controller;
    }
    if (widget is EditableText) {
      return widget.controller;
    }

    TextEditingController? result;
    element.visitChildElements((child) {
      if (result != null) return;
      result = _findControllerInElement(child);
    });

    return result;
  }
}

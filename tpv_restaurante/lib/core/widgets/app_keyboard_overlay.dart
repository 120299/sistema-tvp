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

      final focusedWidget = context.widget;

      TextEditingController? controller;

      if (focusedWidget is TextField) {
        final textField = focusedWidget as TextField;
        if (textField.readOnly == true || textField.enabled == false) {
          return;
        }
        controller = textField.controller;
      } else if (focusedWidget is TextFormField) {
        final formField = focusedWidget as TextFormField;
        if (formField.enabled == false) {
          return;
        }
        controller = formField.controller;
      } else if (focusedWidget is EditableText) {
        final editable = focusedWidget as EditableText;
        if (editable.readOnly == true) {
          return;
        }
        controller = editable.controller;
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
      final tf = widget as TextField;
      if (tf.readOnly == true || tf.enabled == false) return null;
      return tf.controller;
    }
    if (widget is TextFormField) {
      final tff = widget as TextFormField;
      if (tff.enabled == false) return null;
      return tff.controller;
    }
    if (widget is EditableText) {
      final et = widget as EditableText;
      if (et.readOnly == true) return null;
      return et.controller;
    }

    TextEditingController? result;
    element.visitChildElements((child) {
      if (result != null) return;
      result = _findControllerInElement(child);
    });

    return result;
  }
}

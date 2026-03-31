import 'package:flutter/material.dart';

enum VirtualKeyboardKeyType { character, action, modifier }

enum VirtualKeyboardModifier { shift, ctrl, alt, fn }

enum VirtualKeyboardAction {
  backspace,
  enter,
  space,
  tab,
  capsLock,
  escape,
  arrowLeft,
  arrowRight,
  arrowUp,
  arrowDown,
  home,
  end,
  pageUp,
  pageDown,
  insert,
  delete,
  f1,
  f2,
  f3,
  f4,
  f5,
  f6,
  f7,
  f8,
  f9,
  f10,
  f11,
  f12,
}

class VirtualKeyboardKey {
  final String label;
  final String? shiftedLabel;
  final VirtualKeyboardKeyType type;
  final VirtualKeyboardAction? action;
  final VirtualKeyboardModifier? modifier;
  final String? actionLabel;

  const VirtualKeyboardKey({
    required this.label,
    this.shiftedLabel,
    required this.type,
    this.action,
    this.modifier,
    this.actionLabel,
  });
}

class VirtualKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onClose;
  final Color backgroundColor;
  final Color keyColor;
  final Color keyTextColor;
  final Color specialKeyColor;
  final double height;

  const VirtualKeyboard({
    super.key,
    required this.controller,
    this.focusNode,
    this.onClose,
    this.backgroundColor = const Color(0xFF2D2D2D),
    this.keyColor = const Color(0xFF3D3D3D),
    this.keyTextColor = Colors.white,
    this.specialKeyColor = const Color(0xFF4D4D4D),
    this.height = 280,
  });

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
  bool _isShiftActive = false;
  bool _isCapsLockActive = false;
  bool _isCtrlActive = false;
  bool _isAltActive = false;

  final List<List<VirtualKeyboardKey>> _keyboardLayout = [
    // Row 1
    const [
      VirtualKeyboardKey(
        label: 'ESC',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.escape,
        actionLabel: 'Esc',
      ),
      VirtualKeyboardKey(
        label: '1',
        shiftedLabel: '!',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '2',
        shiftedLabel: '"',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '3',
        shiftedLabel: '·',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '4',
        shiftedLabel: '\$',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '5',
        shiftedLabel: '%',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '6',
        shiftedLabel: '&',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '7',
        shiftedLabel: '/',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '8',
        shiftedLabel: '(',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '9',
        shiftedLabel: ')',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '0',
        shiftedLabel: '=',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: "'",
        shiftedLabel: '?',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '¡',
        shiftedLabel: '¿',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: 'DEL',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.backspace,
        actionLabel: '⌫',
      ),
    ],
    // Row 2
    const [
      VirtualKeyboardKey(
        label: 'TAB',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.tab,
        actionLabel: 'Tab',
      ),
      VirtualKeyboardKey(label: 'Q', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'W', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'E', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'R', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'T', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'Y', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'U', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'I', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'O', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'P', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(
        label: '`',
        shiftedLabel: '^',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '+',
        shiftedLabel: '*',
        type: VirtualKeyboardKeyType.character,
      ),
    ],
    // Row 3
    const [
      VirtualKeyboardKey(
        label: 'MAYÚS',
        type: VirtualKeyboardKeyType.modifier,
        modifier: VirtualKeyboardModifier.shift,
        actionLabel: 'Shift',
      ),
      VirtualKeyboardKey(label: 'A', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'S', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'D', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'F', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'G', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'H', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'J', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'K', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'L', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'Ñ', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(
        label: '{',
        shiftedLabel: '[',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '}',
        shiftedLabel: ']',
        type: VirtualKeyboardKeyType.character,
      ),
    ],
    // Row 4
    const [
      VirtualKeyboardKey(
        label: 'CTRL',
        type: VirtualKeyboardKeyType.modifier,
        modifier: VirtualKeyboardModifier.ctrl,
        actionLabel: 'Ctrl',
      ),
      VirtualKeyboardKey(
        label: 'ALT',
        type: VirtualKeyboardKeyType.modifier,
        modifier: VirtualKeyboardModifier.alt,
        actionLabel: 'Alt',
      ),
      VirtualKeyboardKey(label: 'Z', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'X', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'C', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'V', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'B', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'N', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(label: 'M', type: VirtualKeyboardKeyType.character),
      VirtualKeyboardKey(
        label: ',',
        shiftedLabel: ';',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '.',
        shiftedLabel: ':',
        type: VirtualKeyboardKeyType.character,
      ),
      VirtualKeyboardKey(
        label: '-',
        shiftedLabel: '_',
        type: VirtualKeyboardKeyType.character,
      ),
    ],
    // Row 5 - Function keys
    const [
      VirtualKeyboardKey(
        label: 'F1',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f1,
      ),
      VirtualKeyboardKey(
        label: 'F2',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f2,
      ),
      VirtualKeyboardKey(
        label: 'F3',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f3,
      ),
      VirtualKeyboardKey(
        label: 'F4',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f4,
      ),
      VirtualKeyboardKey(
        label: 'F5',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f5,
      ),
      VirtualKeyboardKey(
        label: 'F6',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f6,
      ),
      VirtualKeyboardKey(
        label: 'F7',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f7,
      ),
      VirtualKeyboardKey(
        label: 'F8',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f8,
      ),
      VirtualKeyboardKey(
        label: 'F9',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f9,
      ),
      VirtualKeyboardKey(
        label: 'F10',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f10,
      ),
      VirtualKeyboardKey(
        label: 'F11',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f11,
      ),
      VirtualKeyboardKey(
        label: 'F12',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.f12,
      ),
    ],
    // Row 6 - Bottom row
    const [
      VirtualKeyboardKey(
        label: 'INICIO',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.home,
        actionLabel: 'Inicio',
      ),
      VirtualKeyboardKey(
        label: 'AV PÁG',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.pageUp,
        actionLabel: 'Re Pág',
      ),
      VirtualKeyboardKey(
        label: 'RE PÁG',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.pageDown,
        actionLabel: 'Av Pág',
      ),
      VirtualKeyboardKey(
        label: '⇥',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.tab,
        actionLabel: 'Tab',
      ),
      VirtualKeyboardKey(
        label: ' ',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.space,
        actionLabel: 'ESPACIO',
      ),
      VirtualKeyboardKey(
        label: '↵',
        type: VirtualKeyboardKeyType.action,
        action: VirtualKeyboardAction.enter,
        actionLabel: 'Enter',
      ),
    ],
  ];

  void _onKeyPressed(VirtualKeyboardKey key) {
    switch (key.type) {
      case VirtualKeyboardKeyType.character:
        _handleCharacter(key);
        break;
      case VirtualKeyboardKeyType.action:
        _handleAction(key.action!);
        break;
      case VirtualKeyboardKeyType.modifier:
        _handleModifier(key.modifier!);
        break;
    }
  }

  void _handleCharacter(VirtualKeyboardKey key) {
    String char = _isShiftActive || _isCapsLockActive
        ? (key.shiftedLabel ?? key.label.toUpperCase())
        : key.label.toLowerCase();

    final controller = widget.controller;
    final text = controller.text;
    final selection = controller.selection;

    String newText;
    int newCursorPosition;

    if (selection.isCollapsed) {
      newText =
          text.substring(0, selection.start) +
          char +
          text.substring(selection.end);
      newCursorPosition = selection.start + char.length;
    } else {
      newText =
          text.substring(0, selection.start) +
          char +
          text.substring(selection.end);
      newCursorPosition = selection.start + char.length;
    }

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    if (_isShiftActive && !_isCapsLockActive) {
      setState(() => _isShiftActive = false);
    }
  }

  void _handleAction(VirtualKeyboardAction action) {
    final controller = widget.controller;
    final text = controller.text;
    final selection = controller.selection;

    switch (action) {
      case VirtualKeyboardAction.backspace:
        if (selection.start > 0) {
          String newText;
          int newPosition;

          if (selection.isCollapsed) {
            newText =
                text.substring(0, selection.start - 1) +
                text.substring(selection.end);
            newPosition = selection.start - 1;
          } else {
            newText =
                text.substring(0, selection.start) +
                text.substring(selection.end);
            newPosition = selection.start;
          }

          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newPosition),
          );
        }
        break;

      case VirtualKeyboardAction.enter:
        _insertText('\n');
        break;

      case VirtualKeyboardAction.space:
        _insertText(' ');
        break;

      case VirtualKeyboardAction.tab:
        _insertText('\t');
        break;

      case VirtualKeyboardAction.escape:
        widget.focusNode?.unfocus();
        widget.onClose?.call();
        break;

      case VirtualKeyboardAction.arrowLeft:
        _moveCursor(-1);
        break;

      case VirtualKeyboardAction.arrowRight:
        _moveCursor(1);
        break;

      case VirtualKeyboardAction.home:
        controller.selection = TextSelection.collapsed(offset: 0);
        break;

      case VirtualKeyboardAction.end:
        controller.selection = TextSelection.collapsed(offset: text.length);
        break;

      default:
        break;
    }
  }

  void _handleModifier(VirtualKeyboardModifier modifier) {
    switch (modifier) {
      case VirtualKeyboardModifier.shift:
        if (_isCapsLockActive) {
          setState(() {
            _isCapsLockActive = false;
            _isShiftActive = false;
          });
        } else {
          setState(() {
            _isShiftActive = !_isShiftActive;
          });
        }
        break;

      case VirtualKeyboardModifier.ctrl:
        setState(() => _isCtrlActive = !_isCtrlActive);
        break;

      case VirtualKeyboardModifier.alt:
        setState(() => _isAltActive = !_isAltActive);
        break;

      case VirtualKeyboardModifier.fn:
        break;
    }
  }

  void _insertText(String text) {
    final controller = widget.controller;
    final currentText = controller.text;
    final selection = controller.selection;

    final newText =
        currentText.substring(0, selection.start) +
        text +
        currentText.substring(selection.end);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  void _moveCursor(int offset) {
    final controller = widget.controller;
    final newPosition = (controller.selection.start + offset).clamp(
      0,
      controller.text.length,
    );
    controller.selection = TextSelection.collapsed(offset: newPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      color: widget.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _keyboardLayout.map((row) => _buildRow(row)).toList(),
      ),
    );
  }

  Widget _buildRow(List<VirtualKeyboardKey> row) {
    return Expanded(child: Row(children: row.map(_buildKey).toList()));
  }

  Widget _buildKey(VirtualKeyboardKey key) {
    final isSpecial = key.type != VirtualKeyboardKeyType.character;
    final isActive =
        (key.modifier == VirtualKeyboardModifier.shift && _isShiftActive) ||
        (key.modifier == VirtualKeyboardModifier.ctrl && _isCtrlActive) ||
        (key.modifier == VirtualKeyboardModifier.alt && _isAltActive);

    double widthFactor = 1.0;
    String displayText = key.actionLabel ?? key.label;

    if (key.action == VirtualKeyboardAction.backspace) {
      widthFactor = 1.5;
    } else if (key.action == VirtualKeyboardAction.tab) {
      widthFactor = 1.3;
    } else if (key.action == VirtualKeyboardAction.enter) {
      widthFactor = 2.0;
    } else if (key.action == VirtualKeyboardAction.space) {
      widthFactor = 5.0;
    } else if (key.modifier == VirtualKeyboardModifier.shift ||
        key.modifier == VirtualKeyboardModifier.ctrl ||
        key.modifier == VirtualKeyboardModifier.alt) {
      widthFactor = 1.2;
    } else if (key.action != null &&
        key.action.toString().startsWith('VirtualKeyboardAction.f')) {
      widthFactor = 1.0;
    }

    return Expanded(
      flex: (widthFactor * 100).toInt(),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: isSpecial
              ? (isActive ? const Color(0xFF6D6D6D) : widget.specialKeyColor)
              : (isActive ? const Color(0xFF5D5D5D) : widget.keyColor),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => _onKeyPressed(key),
            child: Center(
              child: Text(
                displayText,
                style: TextStyle(
                  color: widget.keyTextColor,
                  fontSize: _getFontSize(key),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getFontSize(VirtualKeyboardKey key) {
    if (key.action == VirtualKeyboardAction.space) {
      return 12;
    } else if (key.type == VirtualKeyboardKeyType.character &&
        key.label.length > 1) {
      return 10;
    } else if (key.action != null &&
        key.action.toString().startsWith('VirtualKeyboardAction.f')) {
      return 11;
    }
    return 14;
  }
}

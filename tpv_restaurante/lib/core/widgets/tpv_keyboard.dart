import 'package:flutter/material.dart';

class TPVKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onClose;
  final VoidCallback? onEnter;

  const TPVKeyboard({
    super.key,
    required this.controller,
    required this.onClose,
    this.onEnter,
  });

  @override
  State<TPVKeyboard> createState() => _TPVKeyboardState();
}

class _TPVKeyboardState extends State<TPVKeyboard> {
  bool _isShiftActive = false;
  bool _isCapsLockActive = false;

  final List<List<String>> _numberRows = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
  ];

  final List<List<String>> _letterRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ñ'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  final List<String> _symbols = [
    '\'',
    '¡',
    '+',
    '-',
    '*',
    '/',
    '(',
    ')',
    '.',
    ',',
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = screenHeight * 0.28;

    return Container(
      height: keyboardHeight,
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          _buildNumberRow(),
          _buildLetterRow(0),
          _buildLetterRow(1),
          _buildLetterRow(2),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildNumberRow() {
    return Container(
      height: 42,
      color: const Color(0xFF2A2A2A),
      child: Row(
        children: [..._numberRows[0].map((key) => _buildKey(key, flex: 1))],
      ),
    );
  }

  Widget _buildLetterRow(int rowIndex) {
    return Container(
      height: 42,
      child: Row(
        children: [
          if (rowIndex == 2) _buildKey('⇧', isSpecial: true, flex: 1.5),
          Expanded(
            child: Row(
              children: _letterRows[rowIndex]
                  .map((key) => _buildKey(key, flex: 1))
                  .toList(),
            ),
          ),
          if (rowIndex == 2) _buildKey('⌫', isSpecial: true, flex: 1.5),
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    return Container(
      height: 42,
      child: Row(
        children: [
          _buildKey('123', isSpecial: true, flex: 1.5),
          _buildKey('ABC', isSpecial: true, flex: 1.5),
          const Spacer(flex: 1),
          Expanded(flex: 6, child: _buildKey('ESPACIO', isSpecial: true)),
          const Spacer(flex: 1),
          _buildKey('ENTER', isSpecial: true, flex: 2),
        ],
      ),
    );
  }

  Widget _buildKey(String key, {bool isSpecial = false, double flex = 1}) {
    final isShiftOn = _isShiftActive || _isCapsLockActive;
    final isActive = key == '⇧' && isShiftOn;

    String displayKey = key;
    if (!isSpecial && isShiftOn) {
      displayKey = key.toUpperCase();
    }

    return Expanded(
      flex: flex.toInt(),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: isActive
              ? Colors.blue.shade700
              : (isSpecial ? const Color(0xFF3A3A3A) : const Color(0xFF4A4A4A)),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => _onKeyPressed(key),
            child: Center(
              child: Text(
                displayKey,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: key.length > 2 ? 12 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onKeyPressed(String key) {
    if (key == '⇧') {
      setState(() {
        if (_isShiftActive) {
          _isShiftActive = false;
          _isCapsLockActive = !_isCapsLockActive;
        } else {
          _isShiftActive = true;
        }
      });
      return;
    }

    if (key == '⌫') {
      _handleBackspace();
      return;
    }

    if (key == 'ESPACIO') {
      _insertText(' ');
      return;
    }

    if (key == 'ENTER') {
      if (widget.onEnter != null) {
        widget.onEnter!();
      }
      widget.onClose();
      return;
    }

    if (key == '123' || key == 'ABC') {
      return;
    }

    String char = _isShiftActive || _isCapsLockActive
        ? key.toUpperCase()
        : key.toLowerCase();
    _insertText(char);

    if (_isShiftActive && !_isCapsLockActive) {
      setState(() => _isShiftActive = false);
    }
  }

  void _handleBackspace() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (selection.isCollapsed && selection.start > 0) {
      final newText =
          text.substring(0, selection.start - 1) +
          text.substring(selection.end);
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start - 1),
      );
    } else if (!selection.isCollapsed) {
      final newText =
          text.substring(0, selection.start) + text.substring(selection.end);
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    }
  }

  void _insertText(String text) {
    final textValue = widget.controller.text;
    final selection = widget.controller.selection;

    final newText =
        textValue.substring(0, selection.start) +
        text +
        textValue.substring(selection.end);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }
}

class TPVKeyboardOverlay extends StatelessWidget {
  final bool isVisible;
  final TextEditingController? controller;
  final VoidCallback onClose;
  final double height;

  const TPVKeyboardOverlay({
    super.key,
    required this.isVisible,
    this.controller,
    required this.onClose,
    this.height = 0.28,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || controller == null) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SizedBox(
        height: screenHeight * height,
        child: TPVKeyboard(controller: controller!, onClose: onClose),
      ),
    );
  }
}

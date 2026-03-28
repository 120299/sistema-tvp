import 'package:flutter/material.dart';

void showUnfocusableDialog({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _UnfocusableDialogWrapper(child: Builder(builder: builder));
    },
  );
}

class _UnfocusableDialogWrapper extends StatelessWidget {
  final Widget child;

  const _UnfocusableDialogWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Dialog(
        child: GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: child,
        ),
      ),
    );
  }
}

void showUnfocusableDialogWithChild({
  required BuildContext context,
  required Widget child,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: child,
          ),
        ),
      );
    },
  );
}

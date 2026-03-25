import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class UiSectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const UiSectionHeader(this.title, {this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color ?? AppColors.primary,
      ),
    );
  }
}

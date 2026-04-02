import 'dart:io';
import 'package:window_manager/window_manager.dart';

Future<void> initializeDesktop() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setFullScreen(true);
    await windowManager.show();
    await windowManager.focus();
  }
}

export 'desktop_main_stub.dart'
    if (dart.library.io) 'desktop_main.dart'
    if (dart.library.html) 'web_main_stub.dart';

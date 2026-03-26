import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'data/services/database_service.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/mesas_screen.dart';
import 'presentation/screens/configuracion_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1920, 1080),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'TPV Restaurante',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final dbService = DatabaseService();
  await dbService.initialize();

  runApp(
    ProviderScope(
      overrides: [databaseServiceProvider.overrideWithValue(dbService)],
      child: const TPVRestauranteApp(),
    ),
  );
}

class TPVRestauranteApp extends ConsumerWidget {
  const TPVRestauranteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return MaterialApp(
      title: 'TPV Restaurante',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      themeMode: ThemeMode.light,
      home: isLoggedIn
          ? const AppShell()
          : LoginScreen(
              onLoginSuccess: () {
                ref.read(isLoggedInProvider.notifier).state = true;
              },
            ),
      routes: {
        '/mesas': (context) => const MesasScreen(),
        '/configuracion': (context) => const ConfiguracionScreen(),
      },
    );
  }
}

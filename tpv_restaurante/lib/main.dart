import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'data/services/database_service.dart';
import 'presentation/screens/app_shell.dart';
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
    await windowManager.maximize();
  });

  runApp(const TPVRestauranteApp());
}

class TPVRestauranteApp extends ConsumerStatefulWidget {
  const TPVRestauranteApp({super.key});

  @override
  ConsumerState<TPVRestauranteApp> createState() => _TPVRestauranteAppState();
}

class _TPVRestauranteAppState extends ConsumerState<TPVRestauranteApp> {
  late final DatabaseService _dbService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _dbService.initialize();
      if (mounted) setState(() => _isInitialized = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ProviderScope(
        overrides: [databaseServiceProvider.overrideWithValue(_dbService)],
        child: MaterialApp(
          title: 'TPV Restaurante',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.light,
          home: const _AppWithAuth(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class _AppWithAuth extends ConsumerStatefulWidget {
  const _AppWithAuth();

  @override
  ConsumerState<_AppWithAuth> createState() => _AppWithAuthState();
}

class _AppWithAuthState extends ConsumerState<_AppWithAuth> {
  void _onLoginSuccess() {
    ref.read(isLoggedInProvider.notifier).state = true;
  }

  void _onLogout() {
    ref.read(isLoggedInProvider.notifier).state = false;
    ref.read(cajeroActualProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    if (!isLoggedIn) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }

    return AppShell(onLogout: _onLogout);
  }
}

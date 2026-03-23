import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/services/database_service.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/mesas_screen.dart';
import 'presentation/screens/productos_screen.dart';
import 'presentation/screens/informes_screen.dart';
import 'presentation/screens/configuracion_screen.dart';
import 'presentation/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'TPV Restaurante',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/mesas': (context) => const MesasScreen(),
        '/productos': (context) => const ProductosScreen(),
        '/informes': (context) => const InformesScreen(),
        '/configuracion': (context) => const ConfiguracionScreen(),
      },
    );
  }
}

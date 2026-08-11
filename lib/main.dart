import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/theme/theme_provider.dart';
import 'src/core/router/app_router.dart';
import 'src/core/widgets/inactivity_tracker.dart';
import 'src/core/localization/app_localizations.dart';
import 'src/core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint("Firebase no inicializado: $e");
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider); // 🎨 Tema dinámico

    return MaterialApp.router(
      title: 'FisioApp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // Controlado por el usuario
      locale: Locale(currentLocale),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        return InactivityTracker(child: child!);
      },
    );
  }
}

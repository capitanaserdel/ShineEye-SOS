import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'core/network/router.dart';
import 'features/auth/presentation/controllers/auth_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ShineEyeApp(),
    ),
  );
}

class ShineEyeApp extends ConsumerWidget {
  const ShineEyeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionManager = ref.read(sessionManagerProvider);
    final appRouter = AppRouter(sessionManager);

    return MaterialApp.router(
      title: 'ShineEye SOS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Responsive to OS preferences
      routerConfig: appRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}

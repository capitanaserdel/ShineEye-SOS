import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/emergency/presentation/screens/report_incident_screen.dart';
import '../../features/emergency/presentation/screens/map_screen.dart';
import '../../features/survival/presentation/screens/survival_academy_screen.dart';
import '../../features/emergency/presentation/screens/ice_profile_screen.dart';
import 'session_manager.dart';

class AppRouter {
  final SessionManager _sessionManager;

  AppRouter(this._sessionManager);

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final loggedIn = await _sessionManager.isLoggedIn();
      final goingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!loggedIn && !goingToAuth) {
        // Force authentication by default (except for guest reporting)
        return '/login';
      }

      if (loggedIn && goingToAuth) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportIncidentScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const InteractiveMapScreen(),
      ),
      GoRoute(
        path: '/survival',
        builder: (context, state) => const SurvivalAcademyScreen(),
      ),
      GoRoute(
        path: '/ice',
        builder: (context, state) => const IceProfileScreen(),
      ),
    ],
  );
}

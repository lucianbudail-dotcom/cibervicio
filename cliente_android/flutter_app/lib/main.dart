import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/reservation_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/password_recovery_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/points_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final GoRouter router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final bool loggedIn = authProvider.isAuthenticated;
        final bool loggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/password-recovery' ||
            state.matchedLocation == '/password-reset';

        if (!loggedIn && !loggingIn) return '/login';
        if (loggedIn && loggingIn) return '/calendar';

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(
            successMessage: state.extra as String?,
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/password-recovery',
          builder: (context, state) => const PasswordRecoveryScreen(),
        ),
        GoRoute(
          path: '/password-reset',
          builder: (context, state) => PasswordResetScreen(
            phone: state.extra as String?,
          ),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/points',
          builder: (context, state) => const PointsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'CiberVicio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6750A4),
        scaffoldBackgroundColor: const Color(0xFF2B2B2B),
        textTheme: GoogleFonts.fustatTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: router,
    );
  }
}

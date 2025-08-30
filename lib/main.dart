import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/dashboard/screens/app_shell.dart';
import 'widgets/kyc_guard.dart';

import 'features/leads/screens/leads_screen.dart';
import 'features/customers/screens/customers_screen.dart';
import 'features/referrals/screens/referrals_screen.dart';
import 'features/transactions/screens/transactions_screen.dart';
import 'features/visits/screens/visits_screen.dart';
import 'features/profile/screens/profile_screen.dart';

import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Temporarily disable App Check to fix ReCAPTCHA errors
  // await FirebaseAppCheck.instance.activate(
  //   webProvider: ReCaptchaV3Provider('6LfGVikqAAAAACoXlsVRRGD7_0wqUNgQIKSJXF7m'),
  //   androidProvider: AndroidProvider.debug,
  //   appleProvider: AppleProvider.debug,
  // );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'CibilFixer Partner',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: _createRouter(authProvider),
          );
        },
      ),
    );
  }
}

// Create router based on authentication state
GoRouter _createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: authProvider.isAuthenticated ? '/dashboard' : '/login',
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isInitialized = authProvider.isInitialized;
      final isOnLoginPage = state.uri.path == '/login';
      final isOnForgotPasswordPage = state.uri.path == '/forgot-password';
      final isOnAuthPage = isOnLoginPage || isOnForgotPasswordPage;
      final isOnProfilePage = state.uri.path == '/profile';
      final requiresKyc = authProvider.requiresKyc;

      // Show loading screen while initializing
      if (!isInitialized) {
        return '/loading';
      }

      // If not logged in and not on auth pages, redirect to login
      if (!isLoggedIn && !isOnAuthPage) {
        return '/login';
      }

      // If logged in and on auth pages, redirect to dashboard
      if (isLoggedIn && isOnAuthPage) {
        return '/dashboard';
      }

      // If logged in but KYC is required and not on profile page, redirect to KYC screen
      if (isLoggedIn && requiresKyc && !isOnProfilePage) {
        return '/kyc-required';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/kyc-required',
        builder: (context, state) => const KycCompletionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          GoRoute(
            path: '/leads',
            builder: (context, state) => const LeadsScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/referrals',
            builder: (context, state) => const ReferralsScreen(),
          ),
          GoRoute(
            path: '/visits',
            builder: (context, state) => const VisitsScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),

          GoRoute(
            path: '/reports',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Reports Page - Coming Soon')),
                ),
          ),
          GoRoute(
            path: '/analytics',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Analytics Page - Coming Soon')),
                ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

// Loading screen while auth is initializing
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              size: 80,
              color: AppColors.primary500,
            ),
            const SizedBox(height: 24),
            Text(
              'CibilFixer Partner',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

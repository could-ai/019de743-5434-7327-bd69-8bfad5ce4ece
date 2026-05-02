import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/invoice_form_screen.dart';
import 'screens/dashboard_screen.dart';

// Ensure you import the supabase integration config if available
// import 'integrations/supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to initialize Supabase
  try {
     // await SupabaseConfig.ensureInitialized();
  } catch (e) {
     debugPrint('Supabase init failed: $e');
  }

  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/form',
  routes: [
    GoRoute(
      path: '/form',
      builder: (context, state) => const InvoiceFormScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Proforma Invoice Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}
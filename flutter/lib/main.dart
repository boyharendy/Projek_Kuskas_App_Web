import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/routes.dart';
import 'config/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    
    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    debugPrint("Failed to initialize Supabase or load .env: $e");
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const KuskasApp());
}

class KuskasApp extends StatelessWidget {
  const KuskasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KUSKAS',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: KuskasTheme.darkTheme,
      theme: KuskasTheme.darkTheme, // Fallback
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

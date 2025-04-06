import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'domain/entities/subscription.dart';
import 'domain/services/subscription_ai_service.dart';
import 'domain/services/google_auth_service.dart';
import 'domain/services/email_scanning_service.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/sign_in_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void _loadThemeMode() {
    setState(() {
      _isDarkMode = widget.prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      widget.prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Unsub',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainScreen(
        prefs: widget.prefs,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}

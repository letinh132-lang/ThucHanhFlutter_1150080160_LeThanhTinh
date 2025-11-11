import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/reader_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sp = await SharedPreferences.getInstance();
  final dark = sp.getBool('darkMode') ?? false;
  runApp(EBookApp(dark: dark));
}

class EBookApp extends StatefulWidget {
  final bool dark;
  const EBookApp({super.key, required this.dark});

  @override
  State<EBookApp> createState() => _EBookAppState();
}

class _EBookAppState extends State<EBookApp> {
  late bool darkMode;

  @override
  void initState() {
    super.initState();
    darkMode = widget.dark;
  }

  Future<void> _toggleTheme() async {
    setState(() => darkMode = !darkMode);
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('darkMode', darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E‑Book Reader VIP',
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: ReaderScreen(onToggleTheme: _toggleTheme),
    );
  }
}

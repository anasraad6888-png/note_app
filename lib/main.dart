import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'dart:ui';

import 'models/note_document.dart';
import 'screens/main_screen.dart';

void main() async {
  // 1. تهيئة بيئة فلاتر وقاعدة البيانات قبل بدء التطبيق
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // 2. فتح صندوق (جدول) لحفظ بيانات المستندات والمجلدات
  await Hive.openBox('documentsBox');
  await Hive.openBox('foldersBox');
  await Hive.openBox('settingsBox'); // صندوق للإعدادات والألوان المخصصة

  runApp(const NoteApp());
}

class NoteApp extends StatefulWidget {
  const NoteApp({super.key});

  @override
  State<NoteApp> createState() => _NoteAppState();
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _NoteAppState extends State<NoteApp> {
  bool isDarkMode = false;
  final _settingsBox = Hive.box('settingsBox');

  @override
  void initState() {
    super.initState();
    isDarkMode = _settingsBox.get('isDarkMode', defaultValue: false);
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      _settingsBox.put('isDarkMode', isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'Note App',
      builder: FlutterSmartDialog.init(
        builder: (context, child) {
          return Directionality(textDirection: TextDirection.ltr, child: child!);
        },
      ),
      navigatorObservers: [FlutterSmartDialog.observer],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF141414),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainScreen(
        initialDarkMode: isDarkMode,
        onGlobalThemeToggle: _toggleDarkMode,
      ),
    );
  }
}

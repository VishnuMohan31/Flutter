import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/entry_provider.dart';
import 'providers/category_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService.instance.initialize();
  
  runApp(const MindScribeApp());
}

class MindScribeApp extends StatelessWidget {
  const MindScribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => EntryProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..initialize()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Set system UI overlay style based on theme
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeProvider.isDarkMode 
                  ? Brightness.light 
                  : Brightness.dark,
            ),
          );

          return MaterialApp(
            title: 'MindScribe',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}


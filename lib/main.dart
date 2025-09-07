import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'core/file_paths.dart';
import 'features/home/home_page.dart';
import 'providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ensure all required directories exist
  await FilePaths.ensureDirectoriesExist();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textScaleFactor = ref.watch(textScaleFactorProvider);
    
    return MaterialApp(
      title: 'Offline Dictionary',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      
      // Light theme using FlexColorScheme
      theme: FlexThemeData.light(
        scheme: FlexScheme.blueM3,
        useMaterial3: true,
        subThemesData: const FlexSubThemesData(
          inputDecoratorRadius: 8,
          cardRadius: 12,
          dialogRadius: 16,
          textButtonRadius: 4,
          elevatedButtonRadius: 8,
          outlinedButtonRadius: 8,
          chipRadius: 8,
          popupMenuRadius: 8,
        ),
      ),
      
      // Dark theme using FlexColorScheme
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.blueM3,
        useMaterial3: true,
        subThemesData: const FlexSubThemesData(
          inputDecoratorRadius: 8,
          cardRadius: 12,
          dialogRadius: 16,
          textButtonRadius: 4,
          elevatedButtonRadius: 8,
          outlinedButtonRadius: 8,
          chipRadius: 8,
          popupMenuRadius: 8,
        ),
      ),
      
      // Apply text scale factor for accessibility
      builder: (context, child) {
        return MediaQuery(  
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: textScaleFactor,
          ),
          child: child!,
        );
      },
      
      home: const HomePage(),
    );
  }
}

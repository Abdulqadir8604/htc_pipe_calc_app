import 'package:flutter/material.dart';
import 'screens/calculator_screen.dart';
import 'services/hive_service.dart';
import 'services/firebase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase might already be initialized in some cases
    print('Firebase already initialized: $e');
  }
  
  await HiveService.init();
  await FirebaseService.initialize(); // Initialize Firebase Service

  // Ensure default data is available
  if (HiveService.getConfig() == null) {
    print('No config found, initializing default data');
    final defaultConfig = HiveService.getDefaultConfig();
    await HiveService.saveConfig(defaultConfig);
    print('Default config saved with ${defaultConfig.sizes.length} sizes');
  } else {
    print('Config already exists with ${HiveService.getConfig()!.sizes.length} sizes');
    // Even if config exists, if it has no sizes, initialize default data
    if (HiveService.getConfig()!.sizes.isEmpty) {
      print('Config has no sizes, reinitializing with default data');
      final defaultConfig = HiveService.getDefaultConfig();
      await HiveService.saveConfig(defaultConfig);
      print('Default config saved with ${defaultConfig.sizes.length} sizes');
    }
  }

  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTC Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
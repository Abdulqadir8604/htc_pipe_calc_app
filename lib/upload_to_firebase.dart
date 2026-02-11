// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:htc_calc_app/services/hive_service.dart';
// import 'package:htc_calc_app/services/firebase_service.dart';
// import 'package:htc_calc_app/models/calculator_data.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Hive
//   await HiveService.init();

//   // Initialize Firebase
//   await FirebaseService.initialize();

//   // Load the current configuration from Hive
//   CalculatorConfig? config = HiveService.getConfig();

//   if (config != null) {
//     print('Found configuration in Hive. Uploading to Firebase...');
//     print('Number of sizes: ${config.sizes.length}');
//     print('Profit margin: ${(config.profitMargin * 100).toStringAsFixed(2)}%');

//     try {
//       // Upload to Firebase
//       await FirebaseService.uploadConfig(config);
//       print('Configuration successfully uploaded to Firebase under hosePipe!');
//     } catch (e) {
//       print('Error uploading configuration: $e');
//     }
//   } else {
//     print('No configuration found in Hive. Creating and uploading default configuration...');

//     // Create default configuration
//     CalculatorConfig defaultConfig = HiveService.getDefaultConfig();

//     try {
//       // Upload to Firebase
//       await FirebaseService.uploadConfig(defaultConfig);
//       print('Default configuration successfully uploaded to Firebase under hosePipe!');
//     } catch (e) {
//       print('Error uploading default configuration: $e');
//     }
//   }

//   // Exit the app
//   exit(0);
// }
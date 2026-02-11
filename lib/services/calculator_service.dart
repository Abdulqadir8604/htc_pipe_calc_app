import 'dart:async';
import '../models/calculator_data.dart';
import 'hive_service.dart';
import 'firebase_service.dart';

class CalculatorService {
  /// Real-time stream that emits config updates from Firebase.
  /// Each emission is also saved to local Hive for offline access.
  static Stream<CalculatorConfig?> configStream() {
    return FirebaseService.listenToConfig().map((config) {
      if (config != null) {
        // Save to local storage as a side-effect so offline works
        HiveService.saveConfig(config);
      }
      return config;
    });
  }

  static Future<CalculatorConfig?> loadConfig() async {
    // Try to get config from Firebase first, with a timeout
    try {
      CalculatorConfig? firebaseConfig = await FirebaseService.downloadConfig()
          .timeout(const Duration(seconds: 5));
      if (firebaseConfig != null) {
        // Update local storage with Firebase data
        await HiveService.saveConfig(firebaseConfig);
        return firebaseConfig;
      }
    } catch (e) {
      print('Error getting config from Firebase, falling back to local: $e');
    }

    // If Firebase fails or times out, return local config
    return HiveService.getConfig();
  }

  static Future<void> saveConfig(CalculatorConfig config) async {
    // Save to local first
    await HiveService.saveConfig(config);

    // Then try to sync to Firebase
    try {
      await FirebaseService.uploadConfig(config);
    } catch (e) {
      print('Error uploading config to Firebase: $e');
      // Continue even if Firebase upload fails
    }
  }

  static double calculateTotal(
    double sizePrice,
    double fittingPrice,
    double profitMargin,
    double pipeLength,
  ) {
    // Calculate pipe cost (PPM = Price Per Meter)
    double pipeCost = sizePrice * pipeLength;

    // Add fitting cost (fixed cost regardless of length)
    double subtotal = pipeCost + fittingPrice;

    // Apply profit margin
    return subtotal * (1 + profitMargin);
  }

  static Future<void> updateProfitMargin(double profitMargin) async {
    // Update local first
    await HiveService.updateProfitMargin(profitMargin);

    // Then sync to Firebase
    try {
      CalculatorConfig? config = await loadConfig();
      if (config != null) {
        await FirebaseService.uploadConfig(config);
      }
    } catch (e) {
      print('Error syncing profit margin to Firebase: $e');
    }
  }

  static Future<void> updateSizePrice(String sizeName, double newPrice) async {
    // Update local first
    await HiveService.updateSizePrice(sizeName, newPrice);

    // Then sync to Firebase
    try {
      CalculatorConfig? config = await loadConfig();
      if (config != null) {
        await FirebaseService.uploadConfig(config);
      }
    } catch (e) {
      print('Error syncing size price to Firebase: $e');
    }
  }

  static Future<void> updateFittingPrice(
    String sizeName,
    String fittingName,
    double newPrice,
  ) async {
    // Update local first
    await HiveService.updateFittingPrice(sizeName, fittingName, newPrice);

    // Then sync to Firebase
    try {
      CalculatorConfig? config = await loadConfig();
      if (config != null) {
        await FirebaseService.uploadConfig(config);
      }
    } catch (e) {
      print('Error syncing fitting price to Firebase: $e');
    }
  }

  // Firebase methods
  static Future<void> uploadConfigToFirebase(CalculatorConfig config) async {
    await FirebaseService.uploadConfig(config);
  }

  static Future<CalculatorConfig?> downloadConfigFromFirebase() async {
    return await FirebaseService.downloadConfig();
  }

  static Future<void> syncLocalToFirebase() async {
    await FirebaseService.syncLocalToFirebase();
  }

  static Future<void> syncFirebaseToLocal() async {
    await FirebaseService.syncFirebaseToLocal();
  }
}

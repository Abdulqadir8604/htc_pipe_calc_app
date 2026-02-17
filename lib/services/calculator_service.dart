import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/calculator_data.dart';
import 'hive_service.dart';
import 'firebase_service.dart';

class CalculatorService {
  static CalculatorConfig getDefaultConfig() {
    return HiveService.getDefaultConfig();
  }

  /// Real-time stream that emits config updates from Firebase.
  /// Each emission is also saved to local Hive for offline access.
  static Stream<CalculatorConfig?> configStream() {
    if (kDebugMode) {
      // In debug mode, keep local as source-of-truth for safe testing.
      return const Stream<CalculatorConfig?>.empty();
    }
    return FirebaseService.listenToConfig().map((config) {
      if (config != null) {
        HiveService.saveConfig(config);
      }
      return config;
    });
  }

  static Future<CalculatorConfig?> loadConfig() async {
    await HiveService.init();

    final localConfig = HiveService.getConfig();

    if (kDebugMode) {
      // Debug mode: local dataset is authoritative.
      if (localConfig != null) return localConfig;
      final defaultConfig = HiveService.getDefaultConfig();
      await HiveService.saveConfig(defaultConfig);
      return defaultConfig;
    }

    // Release/profile: use Firebase as source-of-truth.
    try {
      final firebaseConfig = await FirebaseService.downloadConfig().timeout(
        const Duration(seconds: 5),
      );
      if (firebaseConfig != null) {
        if (localConfig != null &&
            !_isSameConfig(localConfig, firebaseConfig)) {
          print('Local/Firebase mismatch detected; using Firebase in release.');
        }
        await HiveService.saveConfig(firebaseConfig);
        return firebaseConfig;
      }
    } catch (e) {
      print('Error loading Firebase config, falling back to local: $e');
    }

    if (localConfig != null) return localConfig;

    final defaultConfig = HiveService.getDefaultConfig();
    await HiveService.saveConfig(defaultConfig);
    return defaultConfig;
  }

  static Future<void> saveConfig(CalculatorConfig config) async {
    // Save to local first
    await HiveService.saveConfig(config);

    if (kDebugMode) return;

    // Then sync to Firebase in non-debug builds
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

    if (kDebugMode) return;

    // Then sync to Firebase
    try {
      final config = HiveService.getConfig();
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

    if (kDebugMode) return;

    // Then sync to Firebase
    try {
      final config = HiveService.getConfig();
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

    if (kDebugMode) return;

    // Then sync to Firebase
    try {
      final config = HiveService.getConfig();
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
    if (kDebugMode) {
      // Intentionally no-op in debug mode.
      return;
    }
    await FirebaseService.syncFirebaseToLocal();
  }

  static Future<void> pushLocalTruthToFirebase() async {
    final localConfig = HiveService.getConfig();
    if (localConfig == null) {
      throw Exception('No local configuration found to upload');
    }
    await FirebaseService.uploadConfig(localConfig);
  }

  static bool _isSameConfig(CalculatorConfig a, CalculatorConfig b) {
    if (a.profitMargin != b.profitMargin ||
        a.version != b.version ||
        a.discountPercentage != b.discountPercentage ||
        a.additionalPricePercentage != b.additionalPricePercentage ||
        a.sizes.length != b.sizes.length) {
      return false;
    }
    for (var i = 0; i < a.sizes.length; i++) {
      final sa = a.sizes[i];
      final sb = b.sizes[i];
      if (sa.size != sb.size ||
          sa.price != sb.price ||
          sa.fittings.length != sb.fittings.length) {
        return false;
      }
      for (var j = 0; j < sa.fittings.length; j++) {
        final fa = sa.fittings[j];
        final fb = sb.fittings[j];
        if (fa.fitting != fb.fitting || fa.price != fb.price) {
          return false;
        }
      }
    }
    return true;
  }
}

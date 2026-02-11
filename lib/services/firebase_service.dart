import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import '../models/calculator_data.dart';
import 'hive_service.dart';

class FirebaseService {
  static FirebaseDatabase? _database;

  static Future<void> initialize() async {
    // Explicitly use the database URL to avoid timeouts on non-us regions
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://htc-powerapp-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
  }

  static FirebaseDatabase get database {
    if (_database == null) {
      throw Exception(
        'FirebaseService not initialized. Call initialize() first.',
      );
    }
    return _database!;
  }

  // Upload calculator configuration to Realtime Database
  static Future<void> uploadConfig(CalculatorConfig config) async {
    print('Starting uploadConfig to Firebase...');
    try {
      print('Setting data at hosePipe/current...');
      await database
          .ref('hosePipe/current')
          .set({
            'sizes': config.sizes.map((size) => size.toJson()).toList(),
            'profitMargin': config.profitMargin,
            'version': config.version,
            'discountPercentage': config.discountPercentage,
            'additionalPricePercentage': config.additionalPricePercentage,
            'timestamp': ServerValue.timestamp,
          })
          .timeout(const Duration(seconds: 10));

      print('Configuration uploaded successfully to Firebase');
    } catch (e) {
      print('Error uploading config to Firebase: $e');
      rethrow;
    }
  }

  // Download calculator configuration from Realtime Database
  static Future<CalculatorConfig?> downloadConfig() async {
    try {
      DatabaseEvent event = await database.ref('hosePipe/current').once();
      DataSnapshot snapshot = event.snapshot;

      if (!snapshot.exists) {
        print('No configuration found in Firebase');
        return null;
      }

      // Handle the type conversion properly
      final value = snapshot.value;
      if (value == null) {
        print('No configuration found in Firebase');
        return null;
      }

      // Convert the value to a Map<String, dynamic>
      Map<String, dynamic>? data = _safeConvertToMap(value);
      if (data == null) {
        print('Failed to convert Firebase data to Map<String, dynamic>');
        return null;
      }

      // Extract and validate the sizes list
      final sizesData = data['sizes'];
      if (sizesData is! List) {
        print('Invalid or missing sizes data in Firebase');
        return null;
      }

      // Process the sizes list safely
      List<SizeData> sizes = [];
      for (final sizeItem in sizesData) {
        if (sizeItem is Map<Object?, Object?> ||
            sizeItem is Map<String, dynamic>) {
          final convertedSize = _safeConvertToMap(sizeItem);
          if (convertedSize != null) {
            try {
              sizes.add(SizeData.fromJson(convertedSize));
            } catch (e) {
              print('Error parsing size data: $e');
            }
          }
        }
      }

      // Extract other fields safely
      final profitMargin = (data['profitMargin'] as num?)?.toDouble() ?? 0.0;
      final version = (data['version'] as int?) ?? 1;
      final discountPercentage =
          (data['discountPercentage'] as num?)?.toDouble() ?? 0.0;
      final additionalPricePercentage =
          (data['additionalPricePercentage'] as num?)?.toDouble() ?? 0.0;

      return CalculatorConfig(
        sizes: sizes,
        profitMargin: profitMargin,
        version: version,
        discountPercentage: discountPercentage,
        additionalPricePercentage: additionalPricePercentage,
      );
    } catch (e) {
      print('Error downloading config: $e');
      rethrow;
    }
  }

  /// Real-time listener that emits a new [CalculatorConfig] every time
  /// the Firebase data at 'hosePipe/current' changes.
  static Stream<CalculatorConfig?> listenToConfig() {
    return database.ref('hosePipe/current').onValue.map((event) {
      try {
        final snapshot = event.snapshot;
        if (!snapshot.exists || snapshot.value == null) return null;

        final data = _safeConvertToMap(snapshot.value);
        if (data == null) return null;

        final sizesData = data['sizes'];
        if (sizesData is! List) return null;

        List<SizeData> sizes = [];
        for (final sizeItem in sizesData) {
          if (sizeItem is Map<Object?, Object?> ||
              sizeItem is Map<String, dynamic>) {
            final convertedSize = _safeConvertToMap(sizeItem);
            if (convertedSize != null) {
              try {
                sizes.add(SizeData.fromJson(convertedSize));
              } catch (e) {
                print('Error parsing size in listener: $e');
              }
            }
          }
        }

        final profitMargin = (data['profitMargin'] as num?)?.toDouble() ?? 0.0;
        final version = (data['version'] as int?) ?? 1;
        final discountPercentage =
            (data['discountPercentage'] as num?)?.toDouble() ?? 0.0;
        final additionalPricePercentage =
            (data['additionalPricePercentage'] as num?)?.toDouble() ?? 0.0;

        return CalculatorConfig(
          sizes: sizes,
          profitMargin: profitMargin,
          version: version,
          discountPercentage: discountPercentage,
          additionalPricePercentage: additionalPricePercentage,
        );
      } catch (e) {
        print('Error in config listener: $e');
        return null;
      }
    });
  }

  // Safe conversion method that handles various map types recursively
  static Map<String, dynamic>? _safeConvertToMap(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      Map<String, dynamic> result = {};
      value.forEach((key, val) {
        if (key != null) {
          String keyString = key.toString();
          if (val is Map) {
            result[keyString] = _safeConvertToMap(val);
          } else if (val is List) {
            result[keyString] =
                val.map((item) {
                  if (item is Map) {
                    return _safeConvertToMap(item);
                  }
                  return item;
                }).toList();
          } else {
            result[keyString] = val;
          }
        }
      });
      return result;
    } else if (value is String) {
      // If it's a string representation of JSON, parse it
      try {
        final decoded = json.decode(value);
        return _safeConvertToMap(decoded);
      } catch (e) {
        print('Failed to parse string as JSON: $e');
        return null;
      }
    }

    return null;
  }

  // Helper method to convert objects to Map<String, dynamic>
  static Map<String, dynamic> _convertToMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is Map<Object?, Object?>) {
      Map<String, dynamic> result = {};
      value.forEach((key, val) {
        result[key.toString()] = val;
      });
      return result;
    } else if (value is Map) {
      Map<String, dynamic> result = {};
      value.forEach((key, val) {
        result[key.toString()] = val;
      });
      return result;
    } else {
      return {};
    }
  }

  // Upload all configurations to Realtime Database
  static Future<void> uploadAllConfigs(List<CalculatorConfig> configs) async {
    DatabaseReference ref = database.ref('hosePipe');

    for (int i = 0; i < configs.length; i++) {
      await ref.child('config_$i').set({
        'sizes': configs[i].sizes.map((size) => size.toJson()).toList(),
        'profitMargin': configs[i].profitMargin,
        'version': configs[i].version,
        'timestamp': ServerValue.timestamp,
      });
    }

    print('${configs.length} configurations uploaded successfully');
  }

  // Get all configurations from Realtime Database
  static Stream<List<CalculatorConfig>> getAllConfigs() {
    return database.ref('hosePipe').orderByChild('timestamp').onValue.map((
      event,
    ) {
      List<CalculatorConfig> configs = [];
      final data = event.snapshot.value;
      if (data != null) {
        final mapData = _convertToMap(data);
        mapData.forEach((key, value) {
          if (value is Map) {
            final valueMap = _convertToMap(value);
            configs.add(
              CalculatorConfig(
                sizes:
                    (valueMap['sizes'] as List<dynamic>)
                        .map((size) => SizeData.fromJson(_convertToMap(size)))
                        .toList(),
                profitMargin:
                    (valueMap['profitMargin'] as num?)?.toDouble() ?? 0.0,
                version: (valueMap['version'] as int?) ?? 1,
              ),
            );
          }
        });
      }
      return configs.reversed.toList(); // Reverse to get newest first
    });
  }

  // Sync local config to Firebase
  static Future<void> syncLocalToFirebase() async {
    CalculatorConfig? localConfig = HiveService.getConfig();
    if (localConfig != null) {
      await uploadConfig(localConfig);
    }
  }

  // Sync Firebase config to local
  static Future<void> syncFirebaseToLocal() async {
    CalculatorConfig? firebaseConfig = await downloadConfig();
    if (firebaseConfig != null) {
      await HiveService.saveConfig(firebaseConfig);
    }
  }
}

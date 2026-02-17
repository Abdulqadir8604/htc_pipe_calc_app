import 'package:hive_flutter/hive_flutter.dart';
import '../models/calculator_data.dart';
import '../services/migration_service.dart';

class HiveService {
  static const String _configBoxName = 'calculator_config';
  static const String _configKey = 'config';

  static Box<CalculatorConfig>? _configBox;
  static bool _isInitialized = false;

  static Future<CalculatorConfig?> updateAndGetConfig() async {
    final oldConfig = getConfig();
    final newConfig = getDefaultConfig();

    if (oldConfig != null) {
      final migratedConfig = MigrationService.migrate(oldConfig, newConfig);
      await saveConfig(migratedConfig);
      return migratedConfig;
    }

    await saveConfig(newConfig);
    return newConfig;
  }

  static Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FittingPriceAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SizeDataAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CalculatorConfigAdapter());
    }

    // Open box. If old/corrupt local data fails after app update, rebuild it.
    try {
      _configBox = await Hive.openBox<CalculatorConfig>(_configBoxName);
    } catch (e) {
      print('Failed to open Hive box, recreating it: $e');
      await Hive.deleteBoxFromDisk(_configBoxName);
      _configBox = await Hive.openBox<CalculatorConfig>(_configBoxName);
    }

    // Initialize with default data if empty or if config has no sizes
    if (_configBox!.isEmpty) {
      await _initializeDefaultData();
    } else {
      final oldConfig = _configBox!.get(_configKey);
      if (oldConfig != null) {
        // If the config exists but has no sizes, replace it with default config
        if (oldConfig.sizes.isEmpty) {
          await _initializeDefaultData();
        } else {
          final newConfig = getDefaultConfig();
          if (oldConfig.version < newConfig.version) {
            final migratedConfig = MigrationService.migrate(
              oldConfig,
              newConfig,
            );
            await saveConfig(migratedConfig);
          }
        }
      }
    }
    _isInitialized = true;
  }

  static Future<void> _initializeDefaultData() async {
    final defaultConfig = getDefaultConfig();
    await saveConfig(defaultConfig);
  }

  static CalculatorConfig getDefaultConfig() {
    return CalculatorConfig(
      profitMargin: 0.50,
      version: 11,
      sizes: [
        // 1/4" Size
        SizeData(
          size: '1/4"',
          price: 101.0,
          fittings: [
            // BSP Fittings
            FittingPrice(fitting: '1/4 BSP ST+ST', price: 50.0),
            FittingPrice(fitting: '1/4 BSP ST+90', price: 65.0),
            FittingPrice(fitting: '1/4 BSP 90+90', price: 80.0),
            FittingPrice(fitting: '1/8 BSP ST+ST', price: 50.0),
            FittingPrice(fitting: '1/8 BSP ST+90', price: 65.0),
            FittingPrice(fitting: '1/8 BSP 90+90', price: 80.0),
            // Metric Fittings
            FittingPrice(fitting: 'M12x1.5 ST+ST', price: 60.0),
            FittingPrice(fitting: 'M12x1.5 ST+90', price: 80.0),
            FittingPrice(fitting: 'M12x1.5 90+90', price: 100.0),
            FittingPrice(fitting: 'M14x1.5 ST+ST', price: 62.0),
            FittingPrice(fitting: 'M14x1.5 ST+90', price: 82.0),
            FittingPrice(fitting: 'M14x1.5 90+90', price: 102.0),
            FittingPrice(fitting: 'M16x1.5 ST+ST', price: 78.0),
            FittingPrice(fitting: 'M16x1.5 ST+90', price: 98.0),
            FittingPrice(fitting: 'M16x1.5 90+90', price: 118.0),
            FittingPrice(fitting: 'M18x1.5 ST+ST', price: 82.0),
            FittingPrice(fitting: 'M18x1.5 ST+90', price: 103.0),
            FittingPrice(fitting: 'M18x1.5 90+90', price: 124.0),
            // CR/ORFS Fittings
            FittingPrice(fitting: 'CR/ORFS 9/16" ST+ST', price: 116.0),
            FittingPrice(fitting: 'CR/ORFS 9/16" ST+90', price: 138.0),
            FittingPrice(fitting: 'CR/ORFS 9/16" 90+90', price: 160.0),
            // CR/UNF Fittings
            FittingPrice(fitting: 'CR/UNF 7/16" ST+ST', price: 98.0),
            FittingPrice(fitting: 'CR/UNF 7/16" ST+90', price: 129.0),
            FittingPrice(fitting: 'CR/UNF 7/16" 90+90', price: 160.0),
            FittingPrice(fitting: 'CR/UNF 9/16" ST+ST', price: 114.0),
            FittingPrice(fitting: 'CR/UNF 9/16" ST+90', price: 141.0),
            FittingPrice(fitting: 'CR/UNF 9/16" 90+90', price: 168.0),
            // Male Fittings
            FittingPrice(fitting: 'Male 1/4 BSP x BLANK', price: 35.0),
            FittingPrice(fitting: 'Male 1/8 BSP x BLANK', price: 35.0),
            // Benjo Fittings
            FittingPrice(fitting: 'Benjo M10 x BLANK', price: 60.0),
            FittingPrice(fitting: 'Benjo M12 x BLANK', price: 60.0),
            FittingPrice(fitting: 'Benjo M13 x BLANK', price: 77.0),
            FittingPrice(fitting: 'Benjo M14 x BLANK', price: 68.0),
          ],
        ),
        // 5/16" Size
        SizeData(
          size: '5/16"',
          price: 125.0,
          fittings: [
            // BSP Fittings
            FittingPrice(fitting: '3/8 BSP ST+ST', price: 62.0),
            FittingPrice(fitting: '3/8 BSP ST+90', price: 83.0),
            FittingPrice(fitting: '3/8 BSP 90+90', price: 104.0),
            // Metric Fittings
            FittingPrice(fitting: 'M16x1.5 ST+ST', price: 76.0),
            FittingPrice(fitting: 'M16x1.5 ST+90', price: 98.0),
            FittingPrice(fitting: 'M16x1.5 90+90', price: 120.0),
            FittingPrice(fitting: 'M18x1.5 ST+ST', price: 82.0),
            FittingPrice(fitting: 'M18x1.5 ST+90', price: 105.0),
            FittingPrice(fitting: 'M18x1.5 90+90', price: 122.0),
            // Benjo Fitting
            FittingPrice(fitting: 'Benjo 14MM x BLANK', price: 68.0),
          ],
        ),
        // 3/8" Size
        SizeData(
          size: '3/8"',
          price: 140.0,
          fittings: [
            // BSP Fittings
            FittingPrice(fitting: '3/8 BSP ST+ST', price: 64.0),
            FittingPrice(fitting: '3/8 BSP ST+90', price: 84.0),
            FittingPrice(fitting: '3/8 BSP 90+90', price: 104.0),
            FittingPrice(fitting: '1/2 BSP ST+ST', price: 66.0),
            FittingPrice(fitting: '1/2 BSP ST+90', price: 91.0),
            FittingPrice(fitting: '1/2 BSP 90+90', price: 116.0),
            // Metric Fittings
            FittingPrice(fitting: '16 x 1.5 ST+ST', price: 80.0),
            FittingPrice(fitting: '16 x 1.5 ST+90', price: 101.0),
            FittingPrice(fitting: '16 x 1.5 90+90', price: 122.0),
            FittingPrice(fitting: '18 x 1.5 ST+ST', price: 82.0),
            FittingPrice(fitting: '18 x 1.5 ST+90', price: 105.0),
            FittingPrice(fitting: '18 x 1.5 90+90', price: 128.0),
            FittingPrice(fitting: '20 x 1.5 ST+ST', price: 94.0),
            FittingPrice(fitting: '20 x 1.5 ST+90', price: 117.0),
            FittingPrice(fitting: '20 x 1.5 90+90', price: 140.0),
            FittingPrice(fitting: '22 x 1.5 ST+ST', price: 98.0),
            FittingPrice(fitting: '22 x 1.5 ST+90', price: 127.0),
            FittingPrice(fitting: '22 x 1.5 90+90', price: 156.0),
            // CR/ORFS Fittings
            FittingPrice(fitting: 'CR/ORFS 9/16" ST+ST', price: 122.0),
            FittingPrice(fitting: 'CR/ORFS 9/16" ST+90', price: 141.0),
            FittingPrice(fitting: 'CR/ORFS 9/16" 90+90', price: 160.0),
            FittingPrice(fitting: 'CR/ORFS 11/16" ST+ST', price: 134.0),
            FittingPrice(fitting: 'CR/ORFS 11/16" ST+90', price: 154.0),
            FittingPrice(fitting: 'CR/ORFS 11/16" 90+90', price: 174.0),
            FittingPrice(fitting: 'CR/ORFS 13/16" ST+ST', price: 174.0),
            FittingPrice(fitting: 'CR/ORFS 13/16" ST+90', price: 187.0),
            FittingPrice(fitting: 'CR/ORFS 13/16" 90+90', price: 200.0),
            // CR/UNF Fittings
            FittingPrice(fitting: 'CR/UNF 9/16" ST+ST', price: 114.0),
            FittingPrice(fitting: 'CR/UNF 9/16" ST+90', price: 141.0),
            FittingPrice(fitting: 'CR/UNF 9/16" 90+90', price: 168.0),
            FittingPrice(fitting: 'CR/UNF 3/4" ST+ST', price: 122.0),
            FittingPrice(fitting: 'CR/UNF 3/4" ST+90', price: 160.0),
            FittingPrice(fitting: 'CR/UNF 3/4" 90+90', price: 198.0),
            // Male Fittings
            FittingPrice(fitting: 'Male 3/8 BSP TT x BLANK', price: 37.0),
            FittingPrice(fitting: 'Male 3/8 BSP x BLANK', price: 47.0),
            // Benjo Fittings
            FittingPrice(fitting: 'Benjo M12 x BLANK', price: 70.0),
            FittingPrice(fitting: 'Benjo M14 x BLANK', price: 70.0),
            FittingPrice(fitting: 'Benjo M16 x BLANK', price: 82.0),
            FittingPrice(fitting: 'Benjo M18 x BLANK', price: 95.0),
            FittingPrice(fitting: 'Benjo M22 x BLANK', price: 170.0),
          ],
        ),
        // 1/2" Size
        SizeData(
          size: '1/2"',
          price: 151.0,
          fittings: [
            // BSP Fittings
            FittingPrice(fitting: '1/2 BSP ST+ST', price: 72.0),
            FittingPrice(fitting: '1/2 BSP ST+90', price: 96.0),
            FittingPrice(fitting: '1/2 BSP 90+90', price: 120.0),
            // Metric Fittings
            FittingPrice(fitting: '20 x 1.5 ST+ST', price: 98.0),
            FittingPrice(fitting: '20 x 1.5 ST+90', price: 121.0),
            FittingPrice(fitting: '20 x 1.5 90+90', price: 144.0),
            FittingPrice(fitting: '22 x 1.5 ST+ST', price: 106.0),
            FittingPrice(fitting: '22 x 1.5 ST+90', price: 135.0),
            FittingPrice(fitting: '22 x 1.5 90+90', price: 164.0),
            FittingPrice(fitting: '24 x1.5 ST+ST', price: 128.0),
            FittingPrice(fitting: '24 x1.5 ST+90', price: 162.0),
            FittingPrice(fitting: '24 x1.5 90+90', price: 196.0),
            FittingPrice(fitting: '26 x 1.5 ST+ST', price: 146.0),
            FittingPrice(fitting: '26 x 1.5 ST+90', price: 184.0),
            FittingPrice(fitting: '26 x 1.5 90+90', price: 222.0),
            // ORFS Fittings
            FittingPrice(fitting: 'ORFS 13/16" ST+ST', price: 104.0),
            FittingPrice(fitting: 'ORFS 13/16" ST+90', price: 144.0),
            FittingPrice(fitting: 'ORFS 13/16" 90+90', price: 184.0),
            FittingPrice(fitting: 'ORFS 1" ST+ST', price: 150.0),
            FittingPrice(fitting: 'ORFS 1" ST+90', price: 198.0),
            FittingPrice(fitting: 'ORFS 1" 90+90', price: 246.0),
            // CR/UNF Fittings
            FittingPrice(fitting: 'CR/UNF 3/4" ST+ST', price: 132.0),
            FittingPrice(fitting: 'CR/UNF 3/4" ST+90', price: 169.0),
            FittingPrice(fitting: 'CR/UNF 3/4" 90+90', price: 206.0),
            FittingPrice(fitting: 'CR/UNF 7/8" ST+ST', price: 220.0),
            FittingPrice(fitting: 'CR/UNF 7/8" ST+90', price: 227.0),
            FittingPrice(fitting: 'CR/UNF 7/8" 90+90', price: 234.0),
            // Male Fittings
            FittingPrice(fitting: 'Male 1/2 BSP x BLANK', price: 52.0),
            FittingPrice(fitting: 'Long Male 1/2 BSP x BLANK', price: 75.0),
            FittingPrice(fitting: 'Long Male B90 x BLANK', price: 200.0),
            FittingPrice(fitting: 'Male 3/8BSP TT x BLANK', price: 4.0),
            // Female Fittings
            FittingPrice(fitting: 'LB Female 1/2 BSP x BLANK', price: 168.0),
            // Benjo Fittings
            FittingPrice(fitting: 'Benjo M18 x BLANK', price: 97.0),
            FittingPrice(fitting: 'Benjo M20 x BLANK', price: 173.0),
            FittingPrice(fitting: 'Benjo M22 x BLANK', price: 173.0),
          ],
        ),
        // 5/8" Size
        SizeData(
          size: '5/8"',
          price: 200.0,
          fittings: [
            // BSP Fittings
            FittingPrice(fitting: '3/4 BSP ST+ST', price: 126.0),
            FittingPrice(fitting: '3/4 BSP ST+90', price: 163.0),
            FittingPrice(fitting: '3/4 BSP 90+90', price: 200.0),
            // Metric Fittings
            FittingPrice(fitting: '26 X 1.5 ST+ST', price: 158.0),
            FittingPrice(fitting: '26 X 1.5 ST+90', price: 197.0),
            FittingPrice(fitting: '26 X 1.5 90+90', price: 236.0),
            FittingPrice(fitting: '30 X 2 ST+ST', price: 204.0),
            FittingPrice(fitting: '30 X 2 ST+90', price: 271.0),
            FittingPrice(fitting: '30 X 2 90+90', price: 338.0),
            // ORFS Fittings
            FittingPrice(fitting: 'ORFS 1" ST+ST', price: 162.0),
            FittingPrice(fitting: 'ORFS 1" ST+90', price: 209.0),
            FittingPrice(fitting: 'ORFS 1" 90+90', price: 256.0),
            // CR/ORFS Fittings
            FittingPrice(fitting: 'CR/ORFS 1.3/16" ST+ST', price: 320.0),
            FittingPrice(fitting: 'CR/ORFS 1.3/16" ST+90', price: 409.0),
            FittingPrice(fitting: 'CR/ORFS 1.3/16" 90+90', price: 498.0),
            // CR/UNF Fittings
            FittingPrice(fitting: 'CR/UNF 7/8" ST+ST', price: 230.0),
            FittingPrice(fitting: 'CR/UNF 7/8" ST+90', price: 237.0),
            FittingPrice(fitting: 'CR/UNF 7/8" 90+90', price: 244.0),
            FittingPrice(fitting: 'CR/UNF 1.1/16" ST+ST', price: 294.0),
            FittingPrice(fitting: 'CR/UNF 1.1/16" ST+90', price: 315.0),
            FittingPrice(fitting: 'CR/UNF 1.1/16" 90+90', price: 336.0),
            // Male Fitting
            FittingPrice(fitting: 'Male Long Male x BLANK', price: 84.0),
          ],
        ),
        // 3/4" Size
        SizeData(
          size: '3/4"',
          price: 240.0,
          fittings: [
            // BSP Fittings
            FittingPrice(fitting: '3/4 BSP ST+ST', price: 128.0),
            FittingPrice(fitting: '3/4 BSP ST+90', price: 165.0),
            FittingPrice(fitting: '3/4 BSP 90+90', price: 202.0),
            FittingPrice(fitting: '1 BSP ST+ST', price: 210.0),
            FittingPrice(fitting: '1 BSP ST+90', price: 269.0),
            FittingPrice(fitting: '1 BSP 90+90', price: 328.0),
            // Metric Fittings
            FittingPrice(fitting: '26 x 1.5 ST+ST', price: 196.0),
            FittingPrice(fitting: '26 x 1.5 ST+90', price: 236.0),
            FittingPrice(fitting: '26 x 1.5 90+90', price: 276.0),
            FittingPrice(fitting: '30 x 1.5 ST+ST', price: 244.0),
            FittingPrice(fitting: '30 x 1.5 ST+90', price: 0.0),
            FittingPrice(fitting: '30 x 1.5 90+90', price: 0.0),
            FittingPrice(fitting: '30 x 2 ST+ST', price: 244.0),
            FittingPrice(fitting: '30 x 2 ST+90', price: 310.0),
            FittingPrice(fitting: '30 x 2 90+90', price: 376.0),
            FittingPrice(fitting: '36 x 1.5 ST+ST', price: 328.0),
            FittingPrice(fitting: '36 x 1.5 ST+90', price: 0.0),
            FittingPrice(fitting: '36 x 1.5 90+90', price: 0.0),
            FittingPrice(fitting: '36 x 2 ST+ST', price: 372.0),
            FittingPrice(fitting: '36 x 2 ST+90', price: 519.0),
            FittingPrice(fitting: '36 x 2 90+90', price: 666.0),
            // CR/ORFS Fittings
            FittingPrice(fitting: 'CR/ORFS 1.3/16" ST+ST', price: 356.0),
            FittingPrice(fitting: 'CR/ORFS 1.3/16" ST+90', price: 445.0),
            FittingPrice(fitting: 'CR/ORFS 1.3/16" 90+90', price: 534.0),
            // CR/UNF Fittings
            FittingPrice(fitting: 'CR/UNF 1.1/16" ST+ST', price: 356.0),
            FittingPrice(fitting: 'CR/UNF 1.1/16" ST+90', price: 388.0),
            FittingPrice(fitting: 'CR/UNF 1.1/16" 90+90', price: 420.0),
            // Male Fitting
            FittingPrice(fitting: 'Male 3/4BSP x BLANK', price: 134.0),
          ],
        ),
        // 1" Size
        SizeData(
          size: '1"',
          price: 340.0,
          fittings: [
            // BSP Fittings
            FittingPrice(fitting: '1 BSP ST+ST', price: 208.0),
            FittingPrice(fitting: '1 BSP ST+90', price: 279.0),
            FittingPrice(fitting: '1 BSP 90+90', price: 350.0),
            FittingPrice(fitting: '1.1/4 BSP ST+ST', price: 480.0),
            // Metric Fittings
            FittingPrice(fitting: '36 X 2 ST+ST', price: 404.0),
            FittingPrice(fitting: '36 X 2 ST+90', price: 558.0),
            FittingPrice(fitting: '36 X 2 90+90', price: 712.0),
            FittingPrice(fitting: '42 X 2 ST+ST', price: 520.0),
            FittingPrice(fitting: '42 X 2 ST+90', price: 800.0),
            FittingPrice(fitting: '42 X 2 90+90', price: 1080.0),
            // CR/ORFS Fittings
            FittingPrice(fitting: 'CR/ORFS 1.7/16" ST+ST', price: 532.0),
            FittingPrice(fitting: 'CR/ORFS 1.7/16" ST+90', price: 618.0),
            FittingPrice(fitting: 'CR/ORFS 1.7/16" 90+90', price: 704.0),
            // CR/UNF Fittings
            FittingPrice(fitting: 'CR/UNF 1.5/16" ST+ST', price: 528.0),
            FittingPrice(fitting: 'CR/UNF 1.5/16" ST+90', price: 580.0),
            FittingPrice(fitting: 'CR/UNF 1.5/16" 90+90', price: 632.0),
            // Male Fitting
            FittingPrice(fitting: 'Male 1 BSP x BLANK', price: 186.0),
          ],
        ),
        // 3/4" R4 Size
        SizeData(
          size: '3/4" R4',
          price: 545.0,
          fittings: [
            // BSP Fittings
            FittingPrice(fitting: '3/4 BSP ST+ST', price: 256.0),
            FittingPrice(fitting: '3/4 BSP ST+90', price: 306.0),
            FittingPrice(fitting: '3/4 BSP 90+90', price: 356.0),
            // Metric Fittings
            FittingPrice(fitting: '36 X 2 ST+ST', price: 584.0),
            FittingPrice(fitting: '36 X 2 ST+90', price: 790.0),
            FittingPrice(fitting: '36 X 2 90+90', price: 996.0),
            // CR/ORFS Fittings
            FittingPrice(fitting: 'CR/ORFS 1.3/16" ST+ST', price: 482.0),
            FittingPrice(fitting: 'CR/ORFS 1.3/16" ST+90', price: 553.0),
            FittingPrice(fitting: 'CR/ORFS 1.3/16" 90+90', price: 624.0),
            // CR/UNF Fittings
            FittingPrice(fitting: 'CR/UNF 1.5/16" ST+ST', price: 622.0),
            FittingPrice(fitting: 'CR/UNF 1.5/16" ST+90', price: 633.0),
            FittingPrice(fitting: 'CR/UNF 1.5/16" 90+90', price: 644.0),
          ],
        ),
        // 1" R4 Size
        SizeData(
          size: '1" R4',
          price: 640.0,
          fittings: [
            // BSP Fittings
            FittingPrice(fitting: '1 BSP ST+ST', price: 416.0),
            FittingPrice(fitting: '1 BSP ST+90', price: 500.0),
            FittingPrice(fitting: '1 BSP 90+90', price: 580.0),
            // Metric Fittings
            FittingPrice(fitting: '42 X 2 ST+ST', price: 700.0),
            FittingPrice(fitting: '42 X 2 ST+90', price: 1016.0),
            FittingPrice(fitting: '42 X 2 90+90', price: 1332.0),
            // CR/ORFS Fittings
            FittingPrice(fitting: 'CR/ORFS 1.7/16" ST+ST', price: 650.0),
            FittingPrice(fitting: 'CR/ORFS 1.7/16" ST+90', price: 720.0),
            FittingPrice(fitting: 'CR/ORFS 1.7/16" 90+90', price: 790.0),
            // CR/UNF Fittings
            FittingPrice(fitting: 'CR/UNF 1.5/8" ST+ST', price: 710.0),
            FittingPrice(fitting: 'CR/UNF 1.5/8" ST+90', price: 821.0),
            FittingPrice(fitting: 'CR/UNF 1.5/8" 90+90', price: 932.0),
          ],
        ),
      ],
    );
  }

  static CalculatorConfig? getConfig() {
    return _configBox?.get(_configKey);
  }

  static Future<void> saveConfig(CalculatorConfig config) async {
    await _configBox?.put(_configKey, config);
  }

  static Future<void> updateProfitMargin(double profitMargin) async {
    final config = getConfig();
    if (config != null) {
      config.profitMargin = profitMargin;
      await saveConfig(config);
    }
  }

  static Future<void> updateSizePrice(String sizeName, double newPrice) async {
    final config = getConfig();
    if (config != null) {
      final sizeIndex = config.sizes.indexWhere((s) => s.size == sizeName);
      if (sizeIndex != -1) {
        config.sizes[sizeIndex].price = newPrice;
        await saveConfig(config);
      }
    }
  }

  static Future<void> updateFittingPrice(
    String sizeName,
    String fittingName,
    double newPrice,
  ) async {
    final config = getConfig();
    if (config != null) {
      final sizeIndex = config.sizes.indexWhere((s) => s.size == sizeName);
      if (sizeIndex != -1) {
        final fittingIndex = config.sizes[sizeIndex].fittings.indexWhere(
          (f) => f.fitting == fittingName,
        );
        if (fittingIndex != -1) {
          config.sizes[sizeIndex].fittings[fittingIndex].price = newPrice;
          await saveConfig(config);
        }
      }
    }
  }

  static Future<void> addSize(SizeData newSize) async {
    final config = getConfig();
    if (config != null) {
      config.sizes.add(newSize);
      await saveConfig(config);
    }
  }

  static Future<void> removeSize(String sizeName) async {
    final config = getConfig();
    if (config != null) {
      config.sizes.removeWhere((s) => s.size == sizeName);
      await saveConfig(config);
    }
  }

  static Future<void> addFitting(
    String sizeName,
    FittingPrice newFitting,
  ) async {
    final config = getConfig();
    if (config != null) {
      final sizeIndex = config.sizes.indexWhere((s) => s.size == sizeName);
      if (sizeIndex != -1) {
        config.sizes[sizeIndex].fittings.add(newFitting);
        await saveConfig(config);
      }
    }
  }

  static Future<void> removeFitting(String sizeName, String fittingName) async {
    final config = getConfig();
    if (config != null) {
      final sizeIndex = config.sizes.indexWhere((s) => s.size == sizeName);
      if (sizeIndex != -1) {
        config.sizes[sizeIndex].fittings.removeWhere(
          (f) => f.fitting == fittingName,
        );
        await saveConfig(config);
      }
    }
  }

  static Future<void> clearConfig() async {
    await _configBox?.clear();
  }

  static Future<void> resetToDefault() async {
    await clearConfig();
    await _initializeDefaultData();
  }
}

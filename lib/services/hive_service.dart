import 'package:hive_flutter/hive_flutter.dart';
import '../models/calculator_data.dart';

class HiveService {
  static const String _configBoxName = 'calculator_config';
  static const String _configKey = 'config';
  
  static Box<CalculatorConfig>? _configBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(FittingPriceAdapter());
    Hive.registerAdapter(SizeDataAdapter());
    Hive.registerAdapter(CalculatorConfigAdapter());
    
    // Open boxes
    _configBox = await Hive.openBox<CalculatorConfig>(_configBoxName);
    
    // Initialize with default data if empty
    if (_configBox!.isEmpty) {
      await _initializeDefaultData();
    }
  }

  static Future<void> _initializeDefaultData() async {
    final defaultConfig = CalculatorConfig(
      profitMargin: 0.50,
      sizes: [
        SizeData(
          size: '1/4"',
          price: 101.0,
          fittings: [
            FittingPrice(fitting: '1/4 BSP ST+ST', price: 42.0),
            FittingPrice(fitting: '1/4 BSP ST+90', price: 55.0),
            FittingPrice(fitting: '1/4 BSP 90+90', price: 68.0),
          ],
        ),
        SizeData(
          size: '3/8"',
          price: 140.0,
          fittings: [
            FittingPrice(fitting: '3/8 BSP ST+ST', price: 54.0),
            FittingPrice(fitting: '3/8 BSP ST+90', price: 74.0),
            FittingPrice(fitting: '3/8 BSP 90+90', price: 94.0),
            FittingPrice(fitting: '1/2 BSP ST+ST', price: 60.0),
            FittingPrice(fitting: '1/2 BSP ST+90', price: 82.0),
            FittingPrice(fitting: '1/2 BSP 90+90', price: 104.0),
            FittingPrice(fitting: '3/8" ST+ST 16 X 1.5', price: 72.0),
            FittingPrice(fitting: '3/8" ST+ST 20 X 1.5', price: 84.0),
            FittingPrice(fitting: '3/8" ST+ST 22 X 1.5', price: 88.0),
          ],
        ),
        SizeData(
          size: '1/2"',
          price: 151.0,
          fittings: [
            FittingPrice(fitting: '1/2 BSP ST+ST', price: 66.0),
            FittingPrice(fitting: '1/2 BSP ST+90', price: 86.0),
            FittingPrice(fitting: '1/2 BSP 90+90', price: 106.0),
            FittingPrice(fitting: '1/2" ST+ST 20 X 1.5', price: 88.0),
            FittingPrice(fitting: '1/2" ST+ST 22 X 1.5', price: 96.0),
            FittingPrice(fitting: '1/2" ST+ST 24 X 1.5', price: 114.0),
            FittingPrice(fitting: '1/2" ST+ST 26 X 1.5', price: 132.0),
          ],
        ),
        SizeData(
          size: '5/8"',
          price: 200.0,
          fittings: [
            FittingPrice(fitting: '3/4 BSP ST+ST', price: 126.0),
            FittingPrice(fitting: '3/4 BSP ST+90', price: 163.0),
            FittingPrice(fitting: '3/4 BSP 90+90', price: 200.0),
          ],
        ),
        SizeData(
          size: '3/4"',
          price: 240.0,
          fittings: [
            FittingPrice(fitting: '3/4 BSP ST+ST', price: 128.0),
            FittingPrice(fitting: '3/4 BSP ST+90', price: 165.0),
            FittingPrice(fitting: '3/4 BSP 90+90', price: 202.0),
            FittingPrice(fitting: '3/4" ST+ST 26 X 1.5', price: 196.0),
            FittingPrice(fitting: '3/4" ST+ST 30 X 1.5', price: 244.0),
            FittingPrice(fitting: '3/4" ST+ST 36 X 1.5', price: 328.0),
          ],
        ),
        SizeData(
          size: '1"',
          price: 340.0,
          fittings: [
            FittingPrice(fitting: '1 BSP ST+ST', price: 208.0),
            FittingPrice(fitting: '1 BSP ST+90', price: 279.0),
            FittingPrice(fitting: '1 BSP 90+90', price: 350.0),
            FittingPrice(fitting: '1.1/4 BSP ST+ST', price: 480.0),
            FittingPrice(fitting: '1" ST+ST 36 X 2', price: 356.0),
            FittingPrice(fitting: '1" ST+ST 42 X 2', price: 460.0),
          ],
        ),
        SizeData(
          size: '3/4" R4',
          price: 545.0,
          fittings: [
            FittingPrice(fitting: '3/4 BSP ST+ST', price: 256.0),
            FittingPrice(fitting: '3/4 BSP ST+90', price: 306.0),
            FittingPrice(fitting: '3/4 BSP 90+90', price: 356.0),
          ],
        ),
        SizeData(
          size: '1" R4',
          price: 640.0,
          fittings: [
            FittingPrice(fitting: '1 BSP ST+ST', price: 416.0),
            FittingPrice(fitting: '1 BSP ST+90', price: 500.0),
            FittingPrice(fitting: '1 BSP 90+90', price: 580.0),
          ],
        ),
      ],
    );
    
    await saveConfig(defaultConfig);
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
      final sizeIndex = config.sizes.indexWhere((size) => size.size == sizeName);
      if (sizeIndex != -1) {
        config.sizes[sizeIndex].price = newPrice;
        await saveConfig(config);
      }
    }
  }

  static Future<void> updateFittingPrice(String sizeName, String fittingName, double newPrice) async {
    final config = getConfig();
    if (config != null) {
      final sizeIndex = config.sizes.indexWhere((size) => size.size == sizeName);
      if (sizeIndex != -1) {
        final fittingIndex = config.sizes[sizeIndex].fittings.indexWhere((fitting) => fitting.fitting == fittingName);
        if (fittingIndex != -1) {
          config.sizes[sizeIndex].fittings[fittingIndex].price = newPrice;
          await saveConfig(config);
        }
      }
    }
  }

  static Future<void> close() async {
    await _configBox?.close();
  }
}
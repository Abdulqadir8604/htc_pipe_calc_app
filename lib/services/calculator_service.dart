import '../models/calculator_data.dart';
import 'hive_service.dart';

class CalculatorService {
  static CalculatorConfig? loadConfig() {
    return HiveService.getConfig();
  }

  static Future<void> saveConfig(CalculatorConfig config) async {
    await HiveService.saveConfig(config);
  }

  static double calculateTotal(double sizePrice, double fittingPrice, double profitMargin, double pipeLength) {
    // Calculate pipe cost (PPM = Price Per Meter)
    double pipeCost = sizePrice * pipeLength;
    
    // Add fitting cost (fixed cost regardless of length)
    double subtotal = pipeCost + fittingPrice;
    
    // Apply profit margin
    return subtotal * (1 + profitMargin);
  }

  static Future<void> updateProfitMargin(double profitMargin) async {
    await HiveService.updateProfitMargin(profitMargin);
  }

  static Future<void> updateSizePrice(String sizeName, double newPrice) async {
    await HiveService.updateSizePrice(sizeName, newPrice);
  }

  static Future<void> updateFittingPrice(String sizeName, String fittingName, double newPrice) async {
    await HiveService.updateFittingPrice(sizeName, fittingName, newPrice);
  }
}
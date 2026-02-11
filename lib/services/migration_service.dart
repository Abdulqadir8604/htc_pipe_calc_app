import '../models/calculator_data.dart';

class MigrationService {
  static CalculatorConfig migrate(CalculatorConfig oldConfig, CalculatorConfig newConfig) {
    if (oldConfig.version >= newConfig.version) {
      return oldConfig;
    }

    // Preserve the user's profit margin
    newConfig.profitMargin = oldConfig.profitMargin;

    // Preserve the user's prices
    for (var newSize in newConfig.sizes) {
      final oldSize = oldConfig.sizes.firstWhere((s) => s.size == newSize.size, orElse: () => newSize);
      newSize.price = oldSize.price;

      for (var newFitting in newSize.fittings) {
        final oldFitting = oldSize.fittings.firstWhere((f) => f.fitting == newFitting.fitting, orElse: () => newFitting);
        newFitting.price = oldFitting.price;
      }
    }

    return newConfig;
  }
}

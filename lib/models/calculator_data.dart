import 'package:hive/hive.dart';

part 'calculator_data.g.dart';

@HiveType(typeId: 0)
class FittingPrice extends HiveObject {
  @HiveField(0)
  String fitting;

  @HiveField(1)
  double price;

  FittingPrice({
    required this.fitting,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'fitting': fitting,
      'price': price,
    };
  }

  factory FittingPrice.fromJson(Map<String, dynamic> json) {
    return FittingPrice(
      fitting: json['fitting'],
      price: json['price'].toDouble(),
    );
  }
}

@HiveType(typeId: 1)
class SizeData extends HiveObject {
  @HiveField(0)
  String size;

  @HiveField(1)
  double price;

  @HiveField(2)
  List<FittingPrice> fittings;

  SizeData({
    required this.size,
    required this.price,
    required this.fittings,
  });

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'price': price,
      'fittings': fittings.map((f) => f.toJson()).toList(),
    };
  }

  factory SizeData.fromJson(Map<String, dynamic> json) {
    return SizeData(
      size: json['size'],
      price: json['price'].toDouble(),
      fittings: (json['fittings'] as List)
          .map((f) => FittingPrice.fromJson(f))
          .toList(),
    );
  }
}

@HiveType(typeId: 2)
class CalculatorConfig extends HiveObject {
  @HiveField(0)
  List<SizeData> sizes;

  @HiveField(1)
  double profitMargin;

  CalculatorConfig({
    required this.sizes,
    required this.profitMargin,
  });

  Map<String, dynamic> toJson() {
    return {
      'sizes': sizes.map((s) => s.toJson()).toList(),
      'profitMargin': profitMargin,
    };
  }

  factory CalculatorConfig.fromJson(Map<String, dynamic> json) {
    return CalculatorConfig(
      sizes: (json['sizes'] as List)
          .map((s) => SizeData.fromJson(s))
          .toList(),
      profitMargin: json['profitMargin'].toDouble(),
    );
  }
}
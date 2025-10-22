// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculator_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FittingPriceAdapter extends TypeAdapter<FittingPrice> {
  @override
  final int typeId = 0;

  @override
  FittingPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FittingPrice(
      fitting: fields[0] as String,
      price: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, FittingPrice obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.fitting)
      ..writeByte(1)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FittingPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SizeDataAdapter extends TypeAdapter<SizeData> {
  @override
  final int typeId = 1;

  @override
  SizeData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SizeData(
      size: fields[0] as String,
      price: fields[1] as double,
      fittings: (fields[2] as List).cast<FittingPrice>(),
    );
  }

  @override
  void write(BinaryWriter writer, SizeData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.size)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.fittings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SizeDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalculatorConfigAdapter extends TypeAdapter<CalculatorConfig> {
  @override
  final int typeId = 2;

  @override
  CalculatorConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalculatorConfig(
      sizes: (fields[0] as List).cast<SizeData>(),
      profitMargin: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CalculatorConfig obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.sizes)
      ..writeByte(1)
      ..write(obj.profitMargin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculatorConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
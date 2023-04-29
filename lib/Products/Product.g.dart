// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 1;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    print(fields[0] as String);
    return Product(
      fields[0] as String,
      fields[1] as String,
      fields[2] as double,
      fields[3] as int,
      fields[4] as int,
      fields[5] as String,
      fields[8] as int,
    )
      ..selected = fields[6] as bool
      ..bonus = fields[7] as int;
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.sku)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.discount)
      ..writeByte(5)
      ..write(obj.id)
      ..writeByte(6)
      ..write(obj.selected)
      ..writeByte(7)
      ..write(obj.bonus)
      ..writeByte(8)
      ..write(obj.balance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'InvoiceData.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MyDataAdapter extends TypeAdapter<MyData> {
  @override
  final int typeId = 4;

  @override
  MyData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MyData(
      (fields[1] as List).cast<Product>(),
      fields[2] as String,
      fields[3] as double,
      fields[4] as double,
      fields[5] as String,
      fields[6] as String,
      fields[7] as Customer,
      fields[8] as Shop,
      fields[9] as String,
    )..invoiceNumber = fields[10] as String?;
  }

  @override
  void write(BinaryWriter writer, MyData obj) {
    writer
      ..writeByte(10)
      ..writeByte(1)
      ..write(obj.products)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.tax)
      ..writeByte(4)
      ..write(obj.vat)
      ..writeByte(5)
      ..write(obj.paidAmount)
      ..writeByte(6)
      ..write(obj.shippingCost)
      ..writeByte(7)
      ..write(obj.customer)
      ..writeByte(8)
      ..write(obj.shop)
      ..writeByte(9)
      ..write(obj.date)
      ..writeByte(10)
      ..write(obj.invoiceNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

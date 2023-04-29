import 'package:hive/hive.dart';

part 'Shop.g.dart';

@HiveType(typeId: 3)
class Shop {
  @HiveField(0)
  String name;
  @HiveField(5)
  String id;
  @HiveField(1)
  String address;
  @HiveField(2)
  String tAndC;
  @HiveField(3)
  String welcomeText;
  @HiveField(4)
  String shopKey;

  Shop(this.name, this.address, this.tAndC, this.welcomeText, this.shopKey,
      this.id);

  @override
  String toString() {
    return 'Shop{name: $name, address: $address, tAndC: $tAndC, welcomeText: $welcomeText, shopKey: $shopKey}';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'id': id,
      'address': address,
      'tAndC': tAndC,
      'welcomeText': welcomeText,
      'shopKey': shopKey,
    };
  }

}

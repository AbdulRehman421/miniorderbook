import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';

import '../Area & Sector/Area.dart';
import '../Area & Sector/Sector.dart';
import '../Customer/Customer.dart';
import '../Extra/Shop.dart';
import '../Products/Product.dart';

part 'InvoiceData.g.dart';

@HiveType(typeId: 4)
class MyData {
  @HiveField(1)
  late List<Product> products;
  @HiveField(2)
  String time;
  @HiveField(3)
  double tax;
  @HiveField(4)
  double vat;
  @HiveField(5)
  String paidAmount;
  @HiveField(6)
  String shippingCost;
  @HiveField(7)
  Customer customer;
  @HiveField(8)
  Shop shop;
  @HiveField(9)
  String date;
  @HiveField(10)
  String? invoiceNumber;
  bool willShowPhone = false;
  Area area=Area(-1, -1, "", -1);
  Sector sector=Sector(-1, -1, "scName");
  String? partyCode="";

  @override
  String toString() {
    return 'MyData{products: $products, time: $time, tax: $tax, vat: $vat, paidAmount: $paidAmount, shippingCost: $shippingCost, customer: $customer, shop: $shop, date: $date, invoiceNumber: $invoiceNumber}';
  }

  set willShowPhones(bool willShowPhone) {
    this.willShowPhone = willShowPhone;
  }

  bool get willShow {
    return willShowPhone;
  }

  set setArea(Area area) {
    this.area = area;
  }

  setSectorArea() async{
    String query =
        "select Area.AreaCd as ac,Area._id as areaId,Area.SecCd,Parties.AreaCd, Sector.SecCd as sc,Area.AreaNm,Sector.SecNm,Sector._id as sectorId, Parties._id as pId,Parties.acno,Parties.dsc from Parties inner join Area ON Area.AreaCd=Parties.AreaCd inner join Sector ON Sector.SecCd=Area.SecCd where pId=${customer.id}";

    final Database database = await openDatabase('my_database.db');
    List<Map<String, dynamic>> info = await database.rawQuery(query);
    sector=Sector(info[0]['sectorId'], info[0]['SecCd'], info[0]['SecNm']);
    area=Area(info[0]['areaId'], info[0]['AreaCd'], info[0]['AreaNm'], info[0]['sc']);
    partyCode="${info[0]['acno']}";
    customer=Customer(info[0]['dsc'].toString().replaceAll(RegExp(r'\s*\([^)]*\)'), ''), "${info[0]['acno']}", "", "","${info[0]['pId']}");
  }

  Area get getArea {
    return area;
  }

  Sector get getSector {
    return sector;
  }

  Future<List<Map<String, dynamic>>> get getAddressInfo async {
    String query =
        "select Area.AreaCd as ac,Area._id as areaId,Area.SecCd,Parties.AreaCd, Sector.SecCd as sc,Area.AreaNm,Sector.SecNm,Sector._id as sectorId, Parties._id as pId from Parties inner join Area ON Area.AreaCd=Parties.AreaCd inner join Sector ON Sector.SecCd=Area.SecCd where pId=${customer.id}";

    final Database database = await openDatabase('my_database.db');
    List<Map<String, dynamic>> info = await database.rawQuery(query);
    print(info);
    return info;
  }

  MyData(this.products, this.time, this.tax, this.vat, this.paidAmount,
      this.shippingCost, this.customer, this.shop, this.date);

  int get discountTotal {
    var initial = 0;
    for (int i = 0; i < products.length; i++) {
      initial = initial + products[i].discount;
    }
    return initial;
  }

  set product(List<Product> products) {
    this.products = products;
  }

  List<Product> get product => products;

  double get _total =>
      products.map<double>((p) => p.total).reduce((a, b) => a + b);

  double get _grandTotal {
    if (tax == "0" && vat == "0") {
      return (_total + int.parse(shippingCost));
    } else if (vat == "0") {
      return (_total + (_total) * (tax)) + int.parse(shippingCost);
    } else if (tax == "0") {
      return (_total + ((_total) * (vat))) + int.parse(shippingCost);
    } else {
      return (_total + (_total * (tax) + (_total * vat))) +
          int.parse(shippingCost);
    }
  }

  double get due {
    return _grandTotal - int.parse(paidAmount);
  }

  /*Map<String, dynamic> toMap() {
    Map<String,dynamic>productM={};
    int i=0;
    for (var element in products) {
      productM.putIfAbsent("$time - $i", () => element.toMap(customer.id));
      i++;
  }

    print(productM);
    return {"prod":productM};
  }*/
  Map<String, dynamic> toMap(current) {

    Map<String, dynamic> newMap = {};

// Loop over the products in the original map
    for (var i = 0; i < products.length; i++) {
      // Create a new key in the format "23040001 - i" and assign the product object to it
      var newKey = "$current - $time - $i - ${DateTime.now().microsecondsSinceEpoch}";
      newMap[newKey] = products[i].toMap(partyCode);
    }
    print(newMap);
    return newMap;
  }
}

import 'package:hive/hive.dart';

part 'Product.g.dart';

@HiveType(typeId: 1)
class Product {
  @HiveField(0)
  final String sku;
  @HiveField(1)
  final String productName;
  @HiveField(2)
  double price;
  @HiveField(3)
  int quantity;
  @HiveField(4)
  int discount;
  @HiveField(5)
  String id;
  @HiveField(6)
  bool selected = false;
  @HiveField(7)
  int bonus = 0;
  @HiveField(8)
  int balance;

  String? partyCode = "";

  @override
  String toString() {
    return '{sku: $sku, productName: $productName, price: $price, quantity: $quantity, discount: $discount, id: $id, selected: $selected}';
  }

  // setSectorCode() async {
  //   String query =
  //       "Parties.acno from Parties inner join Area ON Area.AreaCd=Parties.AreaCd inner join Sector ON Sector.SecCd=Area.SecCd where pId=${customer.id}";
  //   final Database database = await openDatabase('my_database.db');
  //   List<Map<String, dynamic>> info = await database.rawQuery(query);
  //   partyCode = "${info[0]['acno']}";
  // }
  double get total => ((price * quantity) - discount);

  String getIndex(int index) {
    switch (index) {
      case 0:
        return sku;
      case 1:
        return productName;
      case 2:
        return _formatCurrency(price);
      case 3:
        return (quantity).toString();
      case 4:
        return (discount).toString();
      case 5:
        return _formatCurrency(total);
    }
    return '';
  }

  Product(this.sku, this.productName, this.price, this.quantity, this.discount,
      this.id,this.balance);

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)}';
  }

  static double getTotal(List<Product> products) {
    double total = 0;
    for (Product product in products) {
      total += product.price * product.quantity * (1 - product.discount / 100);
    }
    return total;
  }

  Map<String, dynamic> toMap(String? partyCode) {
    return {
      'Pcode': sku,
      'bns': bonus,
      // 'balance': balance,
      'rate': price,
      'qty': quantity,
      'dis': discount,
      'Ccode': partyCode,
    };
  }
}

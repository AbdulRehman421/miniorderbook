import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../Customer/Customer.dart';
import '../Customer/Customer.g.dart';
import '../Products/Product.dart';


Future<void> openDB() async {
  // Get the path to the database file
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, 'my_database.db');
  String sql = await rootBundle.loadString("assets/db/products.sql");
  List<String> queries = sql.split(";");

  Database database = await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
    Batch batch = db.batch();
    for (String query in queries) {
      if (query.trim().isNotEmpty) {
        batch.execute(query);
      }
    }
    await batch.commit();
  });

// Fetch data from the products table
  List<Map<String, dynamic>> products = await database.query('Product');
  List<Map<String, dynamic>> parties = await database.query('Parties');
  openHiveBox("PRODUCTS", products);
  saveCustomer("Customer", parties);
  /*SharedPreferences prefs = await SharedPreferences.getInstance();
  final dbAdded = prefs.setBool("DB_ADDED",true);
  prefs.commit();*/
}

void saveCustomer(String boxName, List<Map<String, dynamic>> customers) async {
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CustomerAdapter());
  }
  var box = await Hive.openBox<Customer>(boxName);
  customers.forEach((customer) {
    if (box.containsKey(customer['_id'])) {
      box.delete(customer['_id']);
    }
    box.put(
        customer['_id'],
        Customer(customer['dsc'], "${customer['Address']}","${customer['Phone']}", "",
            "${customer['_id']}"));
  });
}

void openHiveBox(String boxName, List<Map<String, dynamic>> products) async {
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ProductAdapter());
  }
  var box = await Hive.openBox<Product>(boxName);
  products.forEach((product) {
    print(product['balance']);
    if (box.containsKey(product['_id'])) {
      box.delete(product['_id']);
    }
    box.put(
        product['_id'],
        Product(
            product['pcode'] ?? "",
            product['name1'],
            double.parse("${product['balance']}"),
            1,
            0,
            "${product['_id']}",int.parse("${product['balance']}")));
  });
  /*SharedPreferences prefs = await SharedPreferences.getInstance();
  final dbAdded = prefs.setBool("DB_ADDED",true);
  prefs.commit();*/
}

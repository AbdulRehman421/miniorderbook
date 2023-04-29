import 'package:Mini_Bill/Customer/Customer.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class ShowCust extends StatefulWidget {
  const ShowCust({Key? key}) : super(key: key);

  @override
  State<ShowCust> createState() => _ShowCustState();
}

class _ShowCustState extends State<ShowCust> {
  final ScrollController _scrollController = ScrollController();

  final int pageSize = 10; // number of items to display per page
  int currentPage = 1; // current page number, starting from 1
  List<Customer> items = [];

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() async {
    final int offset = currentPage * pageSize;
    final List<Customer> newItems = await fetchItems(offset, pageSize);
    setState(() {
      items.addAll(newItems);
      currentPage++;
    });
  }

  Future<List<Customer>> fetchItems(int offset, int limit) async {
    List<Customer> fetchd = [];
    final Database database = await openDatabase('my_database.db');

    List<Map<String, dynamic>> parties =
    await database.query('Parties', limit: limit, offset: offset);

    parties.forEach((customer) {
      fetchd.add(Customer(customer['dsc'], "${customer['Address']}",
          "${customer['Phone']}", "", "${customer['_id']}"));
    });
    return fetchd;
  }

  initial() async {
    items.addAll(await fetchItems(0, 20));
    setState(() {});
  }


  @override
  void initState() {
    super.initState();
    initial();
    _scrollController.addListener(_onScroll);
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: items.length,
        controller: _scrollController,
        itemBuilder: (BuildContext context, int index) {
          final item = items[index];
          return ListTile(
            title: Text(item.name), subtitle: Text(item.address),
            // ... other widget properties
          );
        },
      ),
    );
  }
}

import 'package:Mini_Bill/Area%20&%20Sector/Sector.dart';
import 'package:Mini_Bill/Invoices/InvoicesList.dart';
import 'package:Mini_Bill/Products/Product.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../Area & Sector/Area.dart';
import '../Customer/Customer.dart';
import '../Customer/Customer.g.dart';
import '../Extra/Shop.dart';
import '../Invoices/InvoiceData.dart';
import '../Utils/Utils.dart';
import '../Widgets/ConstantWidget.dart';

class MultiSelectCheckListScreen extends StatefulWidget {
  final Customer customer;
  final Area area;
  final Sector sector;

  const MultiSelectCheckListScreen(
      {Key? key,
      required this.customer,
      required this.area,
      required this.sector})
      : super(key: key);

  @override
  State<MultiSelectCheckListScreen> createState() =>
      _MultiSelectCheckListScreenState();
}

class _MultiSelectCheckListScreenState
    extends State<MultiSelectCheckListScreen> {
  bool allSelected = false;

  bool visibility = true;
  final ScrollController _scrollController = ScrollController();
  List<Product> items = [];

  final int pageSize = 20; // number of items to display per page
  int currentPage = 1; // current page number, starting from 1
  bool isLoading = false;

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() async {
    final int offset = currentPage * pageSize;

    final List<Product> newItems = await fetchItems(offset, pageSize);
    setState(() {
      controller.text.isNotEmpty
          ? _searchResult.addAll(newItems)
          : items.addAll(newItems);

      currentPage++;
      isLoading = false;
    });
  }

  Future<List<Product>> fetchItems(int offset, int limit) async {
    List<Product> fetchd = [];
    setState(() {
      isLoading = true;
    });
    final Database database = await openDatabase('my_database.db');
    int? count = controller.text.isNotEmpty
        ? Sqflite.firstIntValue(await database.rawQuery(
            "SELECT COUNT(*) FROM Product WHERE name1 LIKE  '%${controller.text}%'  OR pcode LIKE '%${controller.text}%'"))
        : Sqflite.firstIntValue(
            await database.rawQuery("SELECT COUNT(*) FROM Product"));

    List<Map<String, dynamic>> products = controller.text.isNotEmpty
        ? await database.rawQuery(
            "SELECT * FROM Product WHERE name1 LIKE '%${controller.text}%' OR pcode LIKE '%${controller.text}%' LIMIT $limit OFFSET $offset")
        : await database
            .rawQuery("SELECT * FROM Product LIMIT $limit OFFSET $offset");
    ;
    if (products.length <= count!) {
      isLoading = false;
    }

    for (var product in products) {
      Product p = Product(product['pcode'] ?? "", product['name1'],
          double.parse("${product['balance']}"), 0, 0, "${product['_id']}",int.parse("${product['balance']}"));
      final index = selectedProducts
          .indexWhere((element) => element.id == "${product['_id']}");
      if (index >= 0) {
        p.selected = selectedProducts[index].selected;
        p.discount = selectedProducts[index].discount;
        p.quantity = selectedProducts[index].quantity;
      }

      fetchd.add(p);
    }
    await Future.delayed(const Duration(milliseconds: 500));

    return fetchd;
  }

  initial() async {
    if (controller.text.isNotEmpty) {
      _searchResult.clear();
    } else {
      items.clear();
    }

    controller.text.isNotEmpty
        ? _searchResult.addAll(await fetchItems(0, 20))
        : items.addAll(await fetchItems(0, 20));

    setState(() {});
  }

  final productsKey = GlobalKey<FormState>();
  var skuC = TextEditingController();
  var productNameC = TextEditingController();
  var priceC = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _products();
    initial();
    _scrollController.addListener(_onScroll);
    getInvoiceId();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _products() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductAdapter());
    }
    var box = await Hive.openBox<Product>("PRODUCTS");
    setState(() {
      items.clear();
      items.addAll(box.values.skip(0).take(50).toList());
      items.sort((a, b) => a.productName.compareTo(b.productName));
    });
  }

  String generatedInvoiceId = "0";

  Future<void> getInvoiceId() async {
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(MyDataAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CustomerAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ShopAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductAdapter());
    }

    var box = await Hive.openBox<MyData>("Hive.Invoices");
    // setState(() {
    try {
      setState(() {
        var lastInvoiceId = box.values.last.time.substring(4, 8);
        generatedInvoiceId =
            Utils.generateInvoiceId((int.parse(lastInvoiceId) + 1).toString());
      });
    } catch (e) {
      setState(() {
        generatedInvoiceId = Utils.generateInvoiceId(1.toString());
      });
      print(e);
    }
    if (kDebugMode) {
      print(generatedInvoiceId);
    }
    // });
  }

  TextEditingController controller = TextEditingController();

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    for (var userDetail in items) {
      if (userDetail.productName
          .trim()
          .toLowerCase()
          .contains(text.trim().toLowerCase())) {
        _searchResult.add(userDetail);
      }
    }

    _searchResult.sort((a, b) => a.productName.compareTo(b.productName));

    setState(() {});
  }

  List<Product> _searchResult = [];

  String _formatDate(DateTime date) {
    final format = DateFormat.yMMMd('en_US');
    return format.format(date);
  }

  Future<void> saveInvoice(bool willShow, MyData myData) async {
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(MyDataAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CustomerAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ShopAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductAdapter());
    }

    var box = await Hive.openBox<MyData>("Hive.Invoices");
    box.put(myData.time, myData);
    var box1 = await Hive.openBox<bool>("Hive.WillShow");
    box1.put(myData.time, willShow);
  }

  double totalPrice = 0;
  bool showSelected = false;

  @override
  Widget build(BuildContext context) {
    // final _items = CryptoModel.getCrypto();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Select products'),
        actions: [
          items.isNotEmpty || getSelectedItem().isNotEmpty
              ? ElevatedButton(
                  onPressed: () {
                    if (getSelectedItem().isNotEmpty) {
                      MyData md = MyData(
                          getSelectedItem(),
                          generatedInvoiceId,
                          double.parse("0") / 100,
                          double.parse("0") / 100,
                          "0",
                          "0",
                          widget.customer,
                          new Shop("", "", "", '', '', "-1"),
                          _formatDate(DateTime.now()));
                      md.willShowPhones = false;
                      saveInvoice(false, md);
                      // Navigator.of(context).pop(list);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoiceList(),
                        ),
                      );
                    } else {
                      Fluttertoast.showToast(
                        msg: "Please select a product",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.grey[600],
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                  },
                  child: Visibility(
                      visible: visibility, child: const Text("Save")))
              : const SizedBox()
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: ListView(
              controller: _scrollController,
              children: [
                Visibility(
                  visible: !visibility,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 12.0, right: 12, top: 16, bottom: 16),
                      child: Form(
                          key: productsKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12.0),
                                child: Text("Add Product",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                              Visibility(
                                visible: true /*!editing*/,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    controller: skuC,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter product SKU';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                        labelText: 'SKU',
                                        contentPadding: EdgeInsets.all(8),
                                        hintText: 'Enter sku',
                                        border: OutlineInputBorder()),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextFormField(
                                  controller: productNameC,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter product name';
                                    } else if (isNumeric(
                                        value.substring(0, 1))) {
                                      return 'Please use valid product name';
                                    }
                                    return null;
                                  },
                                  decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'Product name',
                                      hintText: 'Enter product name',
                                      border: OutlineInputBorder()),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextFormField(
                                  controller: priceC,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter product price';
                                    } else if (!isNumeric(value)) {
                                      return "Please enter valid price";
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'Price',
                                      hintText: 'Enter product price',
                                      border: OutlineInputBorder()),
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          visibility = true;
                                          allSelected = false;
                                          editing = false;
                                        });
                                        skuC.clear();
                                        priceC.clear();
                                        productNameC.clear();
                                        productsKey.currentState!.save();
                                      },
                                      child: const Text("Cancel"),
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.red),
                                      ),
                                    ),
                                    flex: 10,
                                  ),
                                  const Expanded(
                                    child: SizedBox(),
                                    flex: 1,
                                  ),
                                  Visibility(
                                    visible: false,
                                    child: !editing
                                        ? Expanded(
                                            child: ElevatedButton(
                                                onPressed: () async {
                                                  if (productsKey.currentState!
                                                      .validate()) {
                                                    addItem(Product(
                                                        skuC.text,
                                                        productNameC.text,
                                                        double.parse(
                                                            priceC.text),
                                                        1,
                                                        0,
                                                        Utils.getTimestamp(),0));
                                                    skuC.clear();
                                                    priceC.clear();
                                                    productNameC.clear();
                                                    setState(() {
                                                      visibility = true;
                                                      allSelected = false;
                                                    });
                                                    productsKey.currentState!
                                                        .save();
                                                  }
                                                },
                                                child: const Text("Add")),
                                            flex: 10,
                                          )
                                        : Expanded(
                                            child: ElevatedButton(
                                                onPressed: () async {
                                                  if (productsKey.currentState!
                                                      .validate()) {
                                                    setState(() {
                                                      editing = false;
                                                      visibility = true;
                                                    });
                                                    updateItem(Product(
                                                        skuC.text,
                                                        productNameC.text,
                                                        double.parse(
                                                            priceC.text),
                                                        1,
                                                        0,
                                                        editingId!,0));
                                                    priceC.clear();
                                                    productNameC.clear();
                                                    skuC.clear();
                                                    controller.clear();
                                                    // onSearchTextChanged('');
                                                    productsKey.currentState!
                                                        .save();
                                                  }
                                                },
                                                child: const Text("Update")),
                                            flex: 10,
                                          ),
                                  ),
                                ],
                              )
                            ],
                          )),
                    ),
                  ),
                ),
                Visibility(
                  visible: visibility,
                  child: items.isNotEmpty
                      ? Column(
                          children: [
                            Card(
                              margin: const EdgeInsets.all(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Text(
                                          "Customer name: ${widget.customer.name}"),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Sector: ${widget.sector.scName}"),
                                        Text("Area: ${widget.area.AreaNm}"),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Total: ${totalPrice}"),
                                        Row(
                                          children: [
                                            Checkbox(
                                                value: showSelected,
                                                onChanged: (value) {
                                                  setState(() {
                                                    showSelected = value!;
                                                  });
                                                }),
                                            const Text("Show Selected Product")
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue)),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.only(left: 6, right: 0),
                                leading: const Icon(Icons.search),
                                title: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                      hintText: 'Search',
                                      border: InputBorder.none),
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: (String query) {
                                    currentPage = 1;
                                    _searchResult.clear();
                                    // items.clear();
                                    setState(() {});
                                    initial();
                                  }, // onChanged: onSearchTextChanged,
                                ),
                                trailing: SizedBox(
                                  width: 80,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      InkWell(
                                        child: const Icon(
                                          Icons.cancel,
                                          size: 28,
                                        ),
                                        onTap: () {
                                          controller.text = "";
                                          // onSearchTextChanged('');
                                          currentPage = 1;
                                          _searchResult.clear();
                                          items.clear();
                                          initial();
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                        },
                                      ),
                                      Visibility(
                                        child: InkWell(
                                          child: const Icon(
                                            Icons.search,
                                            size: 28,
                                          ),
                                          onTap: () {
                                            // onSearchTextChanged(controller.text);
                                            currentPage = 1;
                                            _searchResult.clear();
                                            // items.clear();
                                            setState(() {});
                                            initial();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible:
                                  selectedProducts.isNotEmpty && showSelected,
                              child: Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(
                                      "Selected",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  ListView.builder(
                                    itemBuilder: (context, index) {
                                      return ProductItem1(
                                          selectedProducts, index);
                                    },
                                    itemCount: selectedProducts.length,
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                  )
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "All",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            _searchResult.isNotEmpty ||
                                    controller.text.isNotEmpty
                                ? ListView.builder(
                                    itemBuilder: (context, index) {
                                      return InkWell(
                                        onTap: () async {
                                          if (!_searchResult[index].selected) {
                                            showEditProductDialog(context,
                                                _searchResult[index], index);
                                          }
                                        },
                                        child: Card(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 3, horizontal: 6),
                                          child: ListTile(
                                            // contentPadding: const EdgeInsets.all(12),
                                            selected:
                                                _searchResult[index].selected,
                                            selectedTileColor: Colors.blue,
                                            selectedColor: Colors.white,
                                            title: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Visibility(
                                                  visible: false,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        maxRadius: 16,
                                                        backgroundColor:
                                                            Colors.blue,
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            setState(() {
                                                              editing = true;
                                                              visibility =
                                                                  false;
                                                              editingId =
                                                                  _searchResult[
                                                                          index]
                                                                      .id;
                                                            });
                                                            priceC.text =
                                                                "${_searchResult[index].price}";
                                                            productNameC.text =
                                                                _searchResult[
                                                                        index]
                                                                    .productName;
                                                            skuC.text =
                                                                _searchResult[
                                                                        index]
                                                                    .sku;
                                                          },
                                                          child: const Icon(
                                                            Icons.edit,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      CircleAvatar(
                                                        maxRadius: 16,
                                                        backgroundColor:
                                                            Colors.red,
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            AlertDialog alert =
                                                                AlertDialog(
                                                              title: const Text(
                                                                  'Are you sure?'),
                                                              content: const Text(
                                                                  'By clicking this button, this product will be deleted'),
                                                              actions: <Widget>[
                                                                TextButton(
                                                                  child:
                                                                      const Text(
                                                                          'Yes'),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    deleteSearchProduct(
                                                                        index);
                                                                  },
                                                                ),
                                                                TextButton(
                                                                  child: const Text(
                                                                      'Cancel'),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                ),
                                                              ],
                                                            );
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (BuildContextcontext) {
                                                                return alert;
                                                              },
                                                            );
                                                          },
                                                          child: const Icon(
                                                            Icons.delete,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Visibility(
                                                        visible: false,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      12.0,
                                                                  vertical: 2),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                "Qty: ${_searchResult[index].quantity}",
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              _searchResult[index]
                                                                          .discount !=
                                                                      0
                                                                  ? const VerticalDivider()
                                                                  : const SizedBox(),
                                                              _searchResult[index]
                                                                          .discount !=
                                                                      0
                                                                  ? Text(
                                                                      "Dis: ${_searchResult[index].discount}",
                                                                      style: const TextStyle(
                                                                          color:
                                                                              Colors.white),
                                                                    )
                                                                  : const SizedBox(),
                                                            ],
                                                          ),
                                                          decoration:
                                                              const BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            3)),
                                                            color: Colors.amber,
                                                          ),
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              _searchResult[index]
                                                                  .productName,
                                                              style: TextStyle(
                                                                  fontSize: 13,fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 3,
                                                          ),
                                                          Expanded(
                                                            child: Text(_searchResult[
                                                                    index]
                                                                .sku+'(${_searchResult[index].balance})',
                                                              style: TextStyle(
                                                                  fontSize: 13,fontWeight: FontWeight.bold),),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Price:',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13),
                                                              ),
                                                              Container(
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          12.0,
                                                                      vertical:
                                                                          4),
                                                                  child: Text(
                                                                    '${_searchResult[index].price}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            13),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Disc:',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13),
                                                              ),
                                                              Container(
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          12.0,
                                                                      vertical:
                                                                          4),
                                                                  child: Text(
                                                                    '${_searchResult[index].discount}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            13),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Bns:',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13),
                                                              ),
                                                              Container(
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          12.0,
                                                                      vertical:
                                                                          4),
                                                                  child: Text(
                                                                    '${_searchResult[index].bonus}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            13),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Qty:',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13),
                                                              ),
                                                              Container(
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          12.0,
                                                                      vertical:
                                                                          4),
                                                                  child: Text(
                                                                    '${_searchResult[index].quantity}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            13),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Column(
                                                  children: [
                                                    const SizedBox(
                                                      height: 6,
                                                    ),
                                                    Visibility(
                                                      visible: false,
                                                      child: CircleAvatar(
                                                        maxRadius: 16,
                                                        backgroundColor:
                                                            Colors.blue,
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            showEditProductDialog(
                                                                context,
                                                                _searchResult[
                                                                    index],
                                                                index);
                                                          },
                                                          child: const Icon(
                                                            Icons.tune,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 6,
                                                    ),
                                                    !_searchResult[index]
                                                            .selected
                                                        ? CircleAvatar(
                                                            maxRadius: 16,
                                                            backgroundColor:
                                                                Colors.white,
                                                            child:
                                                                GestureDetector(
                                                              onTap: () async {
                                                                showEditProductDialog(
                                                                    context,
                                                                    _searchResult[
                                                                        index],
                                                                    index);
                                                              },
                                                              child: const Icon(
                                                                Icons.add,
                                                                size: 18,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          )
                                                        : CircleAvatar(
                                                            maxRadius: 16,
                                                            backgroundColor:
                                                                Colors.red,
                                                            child:
                                                                GestureDetector(
                                                              onTap: () async {
                                                                showSearchWarningAlert(
                                                                    context,
                                                                    index,
                                                                    0);
                                                              },
                                                              child: const Icon(
                                                                Icons.remove,
                                                                size: 18,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                    const SizedBox(
                                                      height: 6,
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    itemCount: _searchResult.isEmpty
                                        ? 0
                                        : _searchResult.length,
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                  )
                                : ListView.builder(
                                    itemBuilder: (context, index) {
                                      return InkWell(
                                        onTap: () async {
                                          if (!items[index].selected) {
                                            showEditProductDialog(
                                                context, items[index], index);
                                          }
                                        },
                                        child: Card(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 3, horizontal: 6),
                                          child: ListTile(
                                            // contentPadding: const EdgeInsets.all(12),
                                            selected: items[index].selected,
                                            selectedTileColor: Colors.blue,
                                            selectedColor: Colors.white,
                                            title: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Visibility(
                                                  visible: false,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        maxRadius: 16,
                                                        backgroundColor:
                                                            Colors.blue,
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            setState(() {
                                                              editing = true;
                                                              visibility =
                                                                  false;
                                                              editingId =
                                                                  items[index]
                                                                      .id;
                                                            });
                                                            priceC.text =
                                                                "${items[index].price}";
                                                            productNameC
                                                                .text = items[
                                                                    index]
                                                                .productName;
                                                            skuC.text =
                                                                items[index]
                                                                    .sku;
                                                          },
                                                          child: const Icon(
                                                            Icons.edit,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      CircleAvatar(
                                                        maxRadius: 16,
                                                        backgroundColor:
                                                            Colors.red,
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            AlertDialog alert =
                                                                AlertDialog(
                                                              title: const Text(
                                                                  'Are you sure?'),
                                                              content: const Text(
                                                                  'By clicking this button, this product will be deleted'),
                                                              actions: <Widget>[
                                                                TextButton(
                                                                  child:
                                                                      const Text(
                                                                          'Yes'),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    deleteProduct(
                                                                        index);
                                                                  },
                                                                ),
                                                                TextButton(
                                                                  child: const Text(
                                                                      'Cancel'),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                ),
                                                              ],
                                                            );
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (BuildContextcontext) {
                                                                return alert;
                                                              },
                                                            );
                                                          },
                                                          child: const Icon(
                                                            Icons.delete,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Visibility(
                                                        visible: false,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      12.0,
                                                                  vertical: 2),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                "Qty: ${items[index].quantity}",
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              items[index].discount !=
                                                                      0
                                                                  ? const VerticalDivider()
                                                                  : const SizedBox(),
                                                              items[index].discount !=
                                                                      0
                                                                  ? Text(
                                                                      "Dis: ${items[index].discount}",
                                                                      style: const TextStyle(
                                                                          color:
                                                                              Colors.white),
                                                                    )
                                                                  : const SizedBox(),
                                                            ],
                                                          ),
                                                          decoration:
                                                              const BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            3)),
                                                            color: Colors.amber,
                                                          ),
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Expanded(
                                                            flex: 1,
                                                            child: Container(),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(items[index]
                                                                .productName , style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
                                                          ),
                                                          SizedBox(width: 6),
                                                          Expanded(
                                                            child: Text(
                                                                items[index].sku+'(${items[index].balance})', style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
                                                          ),
                                                        ],
                                                      ),
                                                      // const SizedBox(
                                                      //   height: 12,
                                                      // ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Price:',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13),
                                                              ),
                                                              Container(
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          12.0,
                                                                      vertical:
                                                                          4),
                                                                  child: Text(
                                                                    '${items[index].price}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            13),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Disc:',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13),
                                                              ),
                                                              Container(
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          12.0,
                                                                      vertical:
                                                                          4),
                                                                  child: Text(
                                                                    '${items[index].discount}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            13),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Bns:',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13),
                                                              ),
                                                              Container(
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          12.0,
                                                                      vertical:
                                                                          4),
                                                                  child: Text(
                                                                    '${items[index].bonus}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            13),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Qty:',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13),
                                                              ),
                                                              Container(
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          12.0,
                                                                      vertical:
                                                                          4),
                                                                  child: Text(
                                                                    '${items[index].quantity}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            13),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Column(
                                                  children: [
                                                    const SizedBox(height: 6),
                                                    Visibility(
                                                      visible: false,
                                                      child: CircleAvatar(
                                                        maxRadius: 16,
                                                        backgroundColor:
                                                            Colors.orangeAccent,
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            showEditProductDialog(
                                                                context,
                                                                items[index],
                                                                index);
                                                          },
                                                          child: const Icon(
                                                            Icons.tune,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    !items
                                                            .elementAt(index)
                                                            .selected
                                                        ? CircleAvatar(
                                                            maxRadius: 16,
                                                            backgroundColor:
                                                                Colors.white,
                                                            child:
                                                                GestureDetector(
                                                              onTap: () async {
                                                                showEditProductDialog(
                                                                    context,
                                                                    items[
                                                                        index],
                                                                    index);
                                                              },
                                                              child: const Icon(
                                                                Icons.add,
                                                                size: 18,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          )
                                                        : CircleAvatar(
                                                            maxRadius: 16,
                                                            backgroundColor:
                                                                Colors.red,
                                                            child:
                                                                GestureDetector(
                                                              onTap: () async {
                                                                showWarningAlert(
                                                                    context,
                                                                    index,
                                                                    0);
                                                              },
                                                              child: const Icon(
                                                                Icons.remove,
                                                                size: 18,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                    const SizedBox(height: 6),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    itemCount: items.length,
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                  ),
                            const SizedBox(
                              height: 12,
                            ),
                            if (isLoading)
                              const SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator()),
                            const SizedBox(
                              height: 100,
                            )
                          ],
                        )
                      : ConstantWidget.NotFoundWidget(
                          context, "Product not added yet"),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Visibility(
        visible: false,
        child: Visibility(
          visible: visibility,
          child: Container(
            child: FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    editing = false;
                    if (visibility) {
                      visibility = false;
                    } else {
                      visibility = true;
                    }
                  });
                },
                label: const Text("Add Product"),
                icon: const Icon(Icons.add)),
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  bool editing = true;
  String? editingId;
  List<Product> selectedProducts = [];

  List<Product> getSelectedItem() {
    return selectedProducts;
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  void addItem(Product product) {
    setState(() {
      items.add(product);
    });
    openHiveBox("PRODUCTS", product);
  }

  void updateItem(Product product) async {
    openHiveBox("PRODUCTS", product);
  }

  void openHiveBox(String boxName, Product product) async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductAdapter());
    }
    var box = await Hive.openBox<Product>(boxName);
    if (box.containsKey(product.id)) {
      box.delete(product.id);
      box.put(product.id, product);
    } else {
      box.put(product.id, product);
    }

    print(box.values);
    _products();
  }

  Future<void> deleteProduct(int index) async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductAdapter());
    }
    var box = await Hive.openBox<Product>("PRODUCTS");
    box.delete(items[index].id);
    setState(() {
      items.removeWhere(
        (element) => element.sku == items[index].sku,
      );
    });
    print(box.values);
  }

  Future<void> deleteSearchProduct(int index) async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductAdapter());
    }
    var box = await Hive.openBox<Product>("PRODUCTS");
    box.delete(_searchResult[index].id);
    setState(() {
      items.removeWhere(
        (element) => element.id == items[index].id,
      );
      _searchResult.removeWhere(
        (element) => element.id == _searchResult[index].id,
      );
    });
    print(box.values);
  }

  int findProductUsingIndexWhere(List<Product> product, String id) {
    // Find the index of person. If not found, index = -1
    final index = product.indexWhere((element) => element.id == id);
    if (index >= 0) {
      print('Using indexWhere: ${product[index]}');
    }
    return index;
  }

  void showWarningAlert(BuildContext context, int index, type) {
    int searchIndex =
        findProductUsingIndexWhere(_searchResult, items[index].id);

    AlertDialog alertDialog = AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        width: double.maxFinite,
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
              child: Text(
            "Are you sure?",
            style: TextStyle(color: Colors.white),
          )),
        ),
      ),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10))),
      content: SingleChildScrollView(
        child: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstantWidget.SmallWarningWidget(context),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Do you want to " +
                      (type == 1 ? "add " : "remove ") +
                      "${items[index].productName}?",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red),
                          elevation: MaterialStateProperty.all(0),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 24))),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("No")),
                  ElevatedButton(
                      style: ButtonStyle(
                          elevation: MaterialStateProperty.all(0),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 24))),
                      onPressed: () async {
                        print("$index     $searchIndex");
                        setState(() {
                          if (searchIndex != -1) {
                            _searchResult[searchIndex].selected = false;
                          }
                          if (index != -1) {
                            items[index].selected = false;
                          }
                          selectedProducts.removeWhere(
                            (element) => items[index].id == element.id,
                          );
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Yes")),
                ],
              )
            ],
          ),
        ),
      ),
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        });
  }


  void showSearchWarningAlert(BuildContext context, int index, type) {
    int productIndex =
        findProductUsingIndexWhere(items, _searchResult[index].id);
    AlertDialog alertDialog = AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        width: double.maxFinite,
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
              child: Text(
            "Are you sure?",
            style: TextStyle(color: Colors.white),
          )),
        ),
      ),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10))),
      content: SingleChildScrollView(
        child: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstantWidget.SmallWarningWidget(context),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Do you want to " +
                      (type == 1 ? "add " : "remove ") +
                      "${_searchResult[index].productName}?",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red),
                          elevation: MaterialStateProperty.all(0),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 24))),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("No")),
                  ElevatedButton(
                      style: ButtonStyle(
                          elevation: MaterialStateProperty.all(0),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 24))),
                      onPressed: () async {
                        setState(() {
                          if (index != -1) {
                            _searchResult[index].selected = false;
                          }

                          if (productIndex != -1) {
                            items[productIndex].selected = false;
                          }

                          selectedProducts.removeWhere((element) =>
                              _searchResult[index].id == element.id);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Yes")),
                ],
              )
            ],
          ),
        ),
      ),
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        });
  }

  void showSelectedWarningAlert(BuildContext context, int index, type) {
    int productIndex =
        findProductUsingIndexWhere(items, selectedProducts[index].id);
    int searchIndex =
        findProductUsingIndexWhere(_searchResult, selectedProducts[index].id);
    AlertDialog alertDialog = AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        width: double.maxFinite,
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
              child: Text(
            "Are you sure?",
            style: TextStyle(color: Colors.white),
          )),
        ),
      ),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10))),
      content: SingleChildScrollView(
        child: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstantWidget.SmallWarningWidget(context),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Do you want to " +
                      (type == 1 ? "add " : "remove ") +
                      "${selectedProducts[index].productName}?",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red),
                          elevation: MaterialStateProperty.all(0),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 24))),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("No")),
                  ElevatedButton(
                      style: ButtonStyle(
                          elevation: MaterialStateProperty.all(0),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 24))),
                      onPressed: () async {
                        setState(() {
                          if (searchIndex != -1) {
                            _searchResult[searchIndex].selected = false;
                          }

                          if (productIndex != -1) {
                            items[productIndex].selected = false;
                            selectedProducts.removeWhere((element) =>
                                items[productIndex].id == element.id);
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Yes")),
                ],
              )
            ],
          ),
        ),
      ),
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        });
  }
  void showEditProductDialog(BuildContext context, Product product, int index) {
    var countQuantity = product.quantity;
    var countBonus = product.bonus;
    TextEditingController quantityController = TextEditingController();
    if (countQuantity < 1) {
      quantityController.text = "";
    } else {
      quantityController.text = countQuantity.toStringAsFixed(0);
    }
    TextEditingController bonusController = TextEditingController();
    if (countBonus < 1) {
      bonusController.text = "0";
    } else {
      bonusController.text = countQuantity.toStringAsFixed(0);
    }
    var discountC = TextEditingController();
    var priceC = TextEditingController();
    discountC.text = product.discount.toStringAsFixed(0);
    priceC.text = product.price.toStringAsFixed(0);
    int searchIndex = findProductUsingIndexWhere(_searchResult, product.id);
    int productIndex = findProductUsingIndexWhere(items, product.id);

    if (_searchResult.isNotEmpty) {
      _searchResult[searchIndex].selected = false;
    }
    setState(() {});
    AlertDialog alertDialog = AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        width: double.maxFinite,
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
              child: Text(
                "Add Additional",
                style: TextStyle(color: Colors.white),
              )),
        ),
      ),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10))),
      content: SingleChildScrollView(
        child: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12.0, top: 12),
                      child: Text("Quantity: "),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 20,
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              hintText: "Quantity",
                              alignLabelWithHint: true,
                            ),
                            onChanged: (val) {
                              quantityController.text;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12.0, top: 12),
                      child: Text("Bonus: "),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 20,
                          child: TextField(
                            controller: bonusController,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              hintText: "Bonus",
                              alignLabelWithHint: true,
                            ),
                            onChanged: (val) {
                              bonusController.text;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Text("Price"),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.maxFinite,
                      child: TextField(
                        controller: priceC,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          hintText: "Price",
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Text("Discount"),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.maxFinite,
                      child: TextField(
                        controller: discountC,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          hintText: "Discount",
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                          MaterialStateProperty.all(Colors.red),
                          elevation: MaterialStateProperty.all(0),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 24))),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel")),
                  ElevatedButton(
                      style: ButtonStyle(
                          elevation: MaterialStateProperty.all(0),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 24))),
                      onPressed: () async {
                        print("$searchIndex .... $productIndex");
                        print(_searchResult);
                        try {
                          items[productIndex].quantity =
                              int.parse(quantityController.text);
                          items[productIndex].discount =
                              int.parse(discountC.text);
                          items[productIndex].selected = true;
                          items[productIndex].price = double.parse(priceC.text);
                          items[productIndex].bonus = int.parse(bonusController.text);
                        } catch (e) {
                          print(e);
                        }
                        try {
                          if (_searchResult.isNotEmpty) {
                            _searchResult[searchIndex].quantity =
                                int.parse(quantityController.text);
                            _searchResult[searchIndex].discount =
                                int.parse(discountC.text);
                            _searchResult[searchIndex].selected = true;
                            _searchResult[searchIndex].price =
                                double.parse(priceC.text);
                            _searchResult[searchIndex].bonus =
                                int.parse(bonusController.text);
                          }
                        } catch (e) {
                          print(e);
                        }

                        if (productIndex != -1) {
                          selectedProducts.add(items[productIndex]);
                        } else if (searchIndex != -1) {
                          selectedProducts.add(_searchResult[searchIndex]);
                        }

                        totalPrice = Product.getTotal(selectedProducts);

                        setState(() {});

                        Navigator.pop(context);
                      },
                      child: const Text("Submit")),
                ],
              )
            ],
          ),
        ),
      ),
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        });
  }

  Widget ProductItem1(List<Product> selectedProducts, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      child: ListTile(
        // contentPadding: const EdgeInsets.all(12),
        selected: selectedProducts[index].selected,
        selectedTileColor: Colors.blue,
        selectedColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Visibility(
              visible: false,
              child: Row(
                children: [
                  CircleAvatar(
                    maxRadius: 16,
                    backgroundColor: Colors.blue,
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          editing = true;
                          visibility = false;
                          editingId = _searchResult[index].id;
                        });
                        priceC.text = "${_searchResult[index].price}";
                        productNameC.text = _searchResult[index].productName;
                        skuC.text = _searchResult[index].sku;
                      },
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  CircleAvatar(
                    maxRadius: 16,
                    backgroundColor: Colors.red,
                    child: GestureDetector(
                      onTap: () async {
                        AlertDialog alert = AlertDialog(
                          title: const Text('Are you sure?'),
                          content: const Text(
                              'By clicking this button, this product will be deleted'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Yes'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                deleteSearchProduct(index);
                              },
                            ),
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                        showDialog(
                          context: context,
                          builder: (BuildContextcontext) {
                            return alert;
                          },
                        );
                      },
                      child: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Qty: ${selectedProducts[index].quantity}",
                            style: const TextStyle(color: Colors.white),
                          ),
                          selectedProducts[index].discount != 0
                              ? const VerticalDivider()
                              : const SizedBox(),
                          selectedProducts[index].discount != 0
                              ? Text(
                                  "Dis: ${selectedProducts[index].discount}",
                                  style: const TextStyle(color: Colors.white),
                                )
                              : const SizedBox(),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedProducts[index].productName,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          selectedProducts[index].sku+" Balance: ${selectedProducts[index].balance}",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Price:',
                            style: TextStyle(fontSize: 13),
                          ),
                          Container(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4),
                              child: Text(
                                '${selectedProducts[index].price}',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Disc:',
                            style: TextStyle(fontSize: 13),
                          ),
                          Container(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4),
                              child: Text(
                                '${selectedProducts[index].discount}',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Bns:',
                            style: TextStyle(fontSize: 13),
                          ),
                          Container(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4),
                              child: Text(
                                '${selectedProducts[index].bonus}',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Qty:',
                            style: TextStyle(fontSize: 13),
                          ),
                          Container(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4),
                              child: Text(
                                '${selectedProducts[index].quantity}',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const SizedBox(
                  height: 6,
                ),
                Visibility(
                  visible: false,
                  child: CircleAvatar(
                    maxRadius: 16,
                    backgroundColor: Colors.blue,
                    child: GestureDetector(
                      onTap: () async {
                        showEditProductDialog(
                            context, _searchResult[index], index);
                      },
                      child: const Icon(
                        Icons.tune,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                !selectedProducts[index].selected
                    ? CircleAvatar(
                        maxRadius: 16,
                        backgroundColor: Colors.blue,
                        child: GestureDetector(
                          onTap: () async {
                            showEditProductDialog(
                                context, selectedProducts[index], index);
                          },
                          child: const Icon(
                            Icons.add,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : CircleAvatar(
                        maxRadius: 16,
                        backgroundColor: Colors.red,
                        child: GestureDetector(
                          onTap: () async {
                            showSelectedWarningAlert(context, index, 0);
                          },
                          child: const Icon(
                            Icons.remove,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                const SizedBox(
                  height: 6,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

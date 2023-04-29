import 'package:Mini_Bill/Area%20&%20Sector/Area.dart';
import 'package:Mini_Bill/Widgets/ConstantWidget.dart';
import 'package:Mini_Bill/Customer/Customer.dart';
import 'package:Mini_Bill/Area%20&%20Sector/Sector.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';

import '../Products/SelectProducts.dart';
import '../Utils/Utils.dart';
import 'Customer.g.dart';

class SelectCustomer extends StatefulWidget {
  const SelectCustomer({Key? key, required this.areaId, required this.sectorId})
      : super(key: key);

  final Area areaId;
  final Sector sectorId;

  @override
  _SelectCustomerState createState() => _SelectCustomerState();
}

class _SelectCustomerState extends State<SelectCustomer> {
  var customerNameC = TextEditingController();
  var customerAddressC = TextEditingController();
  var customerPhoneC = TextEditingController();
  var customerEmailC = TextEditingController();
  final customerKey = GlobalKey<FormState>();

  final ScrollController _scrollController = ScrollController();

  final int pageSize = 30; // number of items to display per page
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
      controller.text.isNotEmpty
          ? _searchResult.addAll(newItems)
          : items.addAll(newItems);
      currentPage++;
      isLoaded = false;
    });
  }

  bool isLoaded = false;

  var total = 2122;

  Future<List<Customer>> fetchItems(int offset, int limit) async {
    List<Customer> fetchd = [];
    setState(() {
      isLoaded = true;
    });
    final Database database = await openDatabase('my_database.db');

    List<Map<String, dynamic>> parties = controller.text.isNotEmpty
        ? await database.rawQuery(
            "SELECT * FROM Parties WHERE AreaCd=${widget.areaId.AreaCd} and dsc LIKE '%${controller.text}%' LIMIT $limit OFFSET $offset")
        : await database
            .rawQuery("SELECT * FROM Parties where AreaCd=${widget.areaId.AreaCd} LIMIT $limit OFFSET $offset");

    for (var customer in parties) {
      print(customer["dsc"]);
      fetchd.add(Customer(customer['dsc'], "${customer['Address']}",
          "${customer['Phone']}", "", "${customer['_id']}"));
    }

    await Future.delayed(const Duration(milliseconds: 500));

    return fetchd;
  }

  initial() async {
    controller.text.isNotEmpty
        ? _searchResult.addAll(await fetchItems(0, 30))
        : items.addAll(await fetchItems(0, 30));
    print(items.length);
    setState(() {});
  }

  void saveCustomer(String boxName, Customer customer) async {
    if (customer.name.isNotEmpty) {
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CustomerAdapter());
      }
      var box = await Hive.openBox<Customer>(boxName);
      box.put(customer.id, customer);
      setState(() {
        // widget.customer.add(customer);
      });
    }
  }

  void updateCustomer(String boxName, Customer customer) async {
    if (customer.name != "") {
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CustomerAdapter());
      }
      var box = await Hive.openBox<Customer>(boxName);
      box.put(customer.id, customer);
      setState(() {
        // widget.customer.add(customer);
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
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
      appBar: AppBar(
        title: const Text("Select Customer"),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              child: Container(
                padding: EdgeInsets.only(bottom: 100),
                child: listVisibility
                    ? items.isNotEmpty
                        ? Column(
                            children: [
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
                                        setState(() {});
                                        initial();
                                      }
                                      // onChanged: onSearchTextChanged,
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
                                            setState(() {});
                                            initial();
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                          },
                                        ),
                                        InkWell(
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
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              _searchResult.isNotEmpty ||
                                      controller.text.isNotEmpty
                                  ? ListView.separated(
                                      physics: const BouncingScrollPhysics(
                                          parent: ClampingScrollPhysics()),
                                      shrinkWrap: true,
                                      itemBuilder: (context, index) {
                                        return InkWell(
                                          onTap: () {
                                            /*Navigator.of(context)
                                                .pop(_searchResult[index]);*/
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      MultiSelectCheckListScreen(
                                                    customer:
                                                        _searchResult[index],
                                                        area:widget.areaId,
                                                        sector:widget.sectorId
                                                  ),
                                                ));
                                          },
                                          child: Card(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16.0,
                                                      vertical: 8),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            _searchResult[index]
                                                                .name),
                                                        Text("Phone: " +
                                                            _searchResult[index]
                                                                .phone),
                                                        Text("Area: ${widget.areaId.AreaNm}"),
                                                        _searchResult[index]
                                                                    .email !=
                                                                ""
                                                            ? Text("Email: " +
                                                                _searchResult[
                                                                        index]
                                                                    .email)
                                                            : SizedBox(),
                                                      ],
                                                    ),
                                                  ),
                                                  const Expanded(
                                                      child: SizedBox(
                                                    width: 10,
                                                  )),
                                                  Visibility(
                                                    visible: false,
                                                    child: Expanded(
                                                        flex: 2,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Expanded(
                                                              flex: 1,
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                child:
                                                                    IconButton(
                                                                        onPressed:
                                                                            () async {
                                                                          setState(
                                                                              () {
                                                                            editing =
                                                                                true;
                                                                            listVisibility =
                                                                                false;
                                                                            editableId =
                                                                                _searchResult[index].id;
                                                                          });
                                                                          customerNameC.text =
                                                                              _searchResult[index].name;
                                                                          customerPhoneC.text =
                                                                              _searchResult[index].phone;
                                                                          customerEmailC.text =
                                                                              _searchResult[index].email;
                                                                          customerAddressC.text =
                                                                              _searchResult[index].address;
                                                                        },
                                                                        icon:
                                                                            const Icon(
                                                                          Icons
                                                                              .edit,
                                                                          color:
                                                                              Colors.white,
                                                                        )),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 1,
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                child:
                                                                    IconButton(
                                                                        onPressed:
                                                                            () async {
                                                                          final alert =
                                                                              AlertDialog(
                                                                            title:
                                                                                const Text('Are you sure?'),
                                                                            content:
                                                                                const Text('By clicking this button, this customer will be deleted'),
                                                                            actions: <Widget>[
                                                                              TextButton(
                                                                                child: const Text('Yes'),
                                                                                onPressed: () {
                                                                                  Navigator.of(context).pop();
                                                                                  deleteSearchCustomer(index);
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
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (BuildContextcontext) {
                                                                              return alert;
                                                                            },
                                                                          );
                                                                          // deleteCustomer(index);
                                                                        },
                                                                        icon:
                                                                            const Icon(
                                                                          Icons
                                                                              .delete,
                                                                          color:
                                                                              Colors.white,
                                                                        )),
                                                              ),
                                                            ),
                                                          ],
                                                        )),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      itemCount: _searchResult.isEmpty
                                          ? 0
                                          : _searchResult.length,
                                      separatorBuilder:
                                          (BuildContext context, int index) {
                                        return const Divider(
                                          height: 0,
                                        );
                                      },
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const BouncingScrollPhysics(
                                          parent: ClampingScrollPhysics()),
                                      itemBuilder: (context, index) {
                                        return InkWell(
                                          onTap: () {
                                            /* Navigator.of(context)
                                                .pop(widget.customer[index]);*/
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      MultiSelectCheckListScreen(
                                                    customer: items[index],
                                                          area:widget.areaId,
                                                          sector:widget.sectorId
                                                  ),
                                                ));
                                          },
                                          child: Card(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16.0,
                                                      vertical: 8),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(items[index].name),
                                                        Text("Phone: " +
                                                            items[index].phone),
                                                        Text("Area: ${widget.areaId.AreaNm}"),
                                                        items[index].email != ""
                                                            ? Text("Email: " +
                                                                items[index]
                                                                    .email)
                                                            : SizedBox(),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Expanded(
                                                      child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Visibility(
                                                        visible: false,
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.red,
                                                          child: IconButton(
                                                              onPressed:
                                                                  () async {
                                                                setState(() {
                                                                  editing =
                                                                      true;
                                                                  listVisibility =
                                                                      false;
                                                                  editableId =
                                                                      items[index]
                                                                          .id;
                                                                });
                                                                customerNameC
                                                                        .text =
                                                                    items[index]
                                                                        .name;
                                                                customerPhoneC
                                                                        .text =
                                                                    items[index]
                                                                        .phone;
                                                                customerEmailC
                                                                        .text =
                                                                    items[index]
                                                                        .email;
                                                                customerAddressC
                                                                        .text =
                                                                    items[index]
                                                                        .address;
                                                              },
                                                              icon: const Icon(
                                                                Icons.edit,
                                                                color: Colors
                                                                    .white,
                                                              )),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Visibility(
                                                        visible: false,
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.blue,
                                                          child: IconButton(
                                                              onPressed:
                                                                  () async {
                                                                final alert =
                                                                    AlertDialog(
                                                                  title: const Text(
                                                                      'Are you sure?'),
                                                                  content:
                                                                      const Text(
                                                                          'By clicking this button, this customer will be deleted'),
                                                                  actions: <
                                                                      Widget>[
                                                                    TextButton(
                                                                      child: const Text(
                                                                          'Yes'),
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                        deleteCustomer(
                                                                            index);
                                                                      },
                                                                    ),
                                                                    TextButton(
                                                                      child: const Text(
                                                                          'Cancel'),
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      },
                                                                    ),
                                                                  ],
                                                                );
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (BuildContextcontext) {
                                                                    return alert;
                                                                  },
                                                                );
                                                                // deleteCustomer(index);
                                                              },
                                                              icon: const Icon(
                                                                Icons.delete,
                                                                color: Colors
                                                                    .white,
                                                              )),
                                                        ),
                                                      ),
                                                    ],
                                                  )),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      itemCount: items.length,
                                      separatorBuilder:
                                          (BuildContext context, int index) {
                                        return const Divider(
                                          height: 0,
                                        );
                                      },
                                    ),
                              const SizedBox(
                                height: 12,
                              ),
                              if (isLoaded)
                                const SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: CircularProgressIndicator()),
                              const SizedBox(
                                height: 48,
                              )
                            ],
                          )
                        : ConstantWidget.NotFoundWidget(
                            context, "Customer not added yet")
                    : Container(
                        margin: EdgeInsets.all(12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Form(
                                key: customerKey,
                                child: Column(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Add Customer",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: TextFormField(
                                        controller: customerNameC,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please customer name';
                                          }
                                          return null;
                                        },
                                        decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.all(8),
                                            labelText: 'Customer name',
                                            hintText: 'Enter customer name',
                                            border: OutlineInputBorder()),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: TextFormField(
                                        controller: customerAddressC,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter customer address';
                                          }
                                          return null;
                                        },
                                        minLines: 2,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.all(8),
                                            labelText: 'Customer address',
                                            hintText: 'Enter customer address',
                                            border: OutlineInputBorder()),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: TextFormField(
                                        controller: customerPhoneC,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter customer phone';
                                          }
                                          return null;
                                        },
                                        keyboardType: TextInputType.phone,
                                        decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.all(8),
                                            labelText: 'Customer phone',
                                            hintText: 'Enter customer phone',
                                            border: OutlineInputBorder()),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: TextFormField(
                                        controller: customerEmailC,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.all(8),
                                            labelText: 'Customer email',
                                            hintText: 'Enter customer email',
                                            border: OutlineInputBorder()),
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                listVisibility = true;
                                                editing = false;
                                              });
                                              customerNameC.text = "";
                                              customerAddressC.text = "";
                                              customerPhoneC.text = "";
                                              customerEmailC.text = "";
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
                                        Expanded(
                                          child: !editing
                                              ? ElevatedButton(
                                                  onPressed: () async {
                                                    if (customerKey
                                                        .currentState!
                                                        .validate()) {
                                                      setState(() {
                                                        listVisibility = true;
                                                      });

                                                      saveCustomer(
                                                          "Customer",
                                                          Customer(
                                                              customerNameC
                                                                  .text,
                                                              customerAddressC
                                                                  .text,
                                                              customerPhoneC
                                                                  .text,
                                                              customerEmailC
                                                                  .text,
                                                              Utils
                                                                  .getTimestamp()));
                                                      customerNameC.text = "";
                                                      customerAddressC.text =
                                                          "";
                                                      customerPhoneC.text = "";
                                                      customerEmailC.text = "";
                                                    }
                                                  },
                                                  child: const Text("Add"))
                                              : ElevatedButton(
                                                  onPressed: () async {
                                                    if (customerKey
                                                        .currentState!
                                                        .validate()) {
                                                      setState(() {
                                                        editing = false;
                                                        listVisibility = true;
                                                      });

                                                      updateCustomer(
                                                          "Customer",
                                                          Customer(
                                                              customerNameC
                                                                  .text,
                                                              customerAddressC
                                                                  .text,
                                                              customerPhoneC
                                                                  .text,
                                                              customerEmailC
                                                                  .text,
                                                              editableId!));
                                                      customerNameC.text = "";
                                                      customerAddressC.text =
                                                          "";
                                                      customerPhoneC.text = "";
                                                      customerEmailC.text = "";
                                                      _customers(0);
                                                    }
                                                  },
                                                  child: const Text("Update")),
                                          flex: 10,
                                        ),
                                      ],
                                    )
                                  ],
                                )),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Visibility(
        visible: false,
        child: Container(
          child: Visibility(
            visible: listVisibility,
            child: FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  listVisibility = false;
                });
              },
              label: const Text("Add Customer"),
              icon: const Icon(Icons.add),
            ),
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  String? editableId;
  bool editing = false;
  bool listVisibility = true;
  int page = 0;
  Future<void> _customers(int page) async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CustomerAdapter());
    }
    var box = await Hive.openBox<Customer>("Customer");
    total = box.values.length;
    List<Customer> data = box.values.skip(page).take(100).toList();
    // widget.customer.addAll(data);
    this.page = page;
    setState(() {});
  }

  Future<void> deleteCustomer(int index) async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CustomerAdapter());
    }
    var box = await Hive.openBox<Customer>("Customer");
    // box.delete(widget.customer[index].id);
    setState(() {
      // widget.customer
      //     .removeWhere((element) => element.id == widget.customer[index].id);
    });
  }

  Future<void> deleteSearchCustomer(int index) async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CustomerAdapter());
    }
    var box = await Hive.openBox<Customer>("Customer");
    box.delete(_searchResult[index].id);
    setState(() {
      // widget.customer
      //     .removeWhere((element) => element.id == widget.customer[index].id);
      _searchResult
          .removeWhere((element) => element.id == _searchResult[index].id);
    });
  }

  TextEditingController controller = TextEditingController();

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    currentPage = 1;

    for (var element in items) {
      if (element.name
              .trim()
              .toLowerCase()
              .contains(text.trim().toLowerCase()) ||
          element.phone
              .trim()
              .toLowerCase()
              .contains(text.trim().toLowerCase())) {
        _searchResult.add(element);
      }
    }

    setState(() {});
  }

  List<Customer> _searchResult = [];
}

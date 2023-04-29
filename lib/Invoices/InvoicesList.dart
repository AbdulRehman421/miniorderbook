import 'dart:io';

import 'package:Mini_Bill/Products/ReSelectProducts.dart';
import 'package:Mini_Bill/Widgets/ConstantWidget.dart';
import 'package:Mini_Bill/Customer/Customer.dart';
import 'package:Mini_Bill/Invoices/InvoiceData.dart';
import 'package:Mini_Bill/Invoices/invoice.dart';
import 'package:Mini_Bill/main.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

import '../Area & Sector/Area.dart';
import '../Customer/Customer.g.dart';
import '../Extra/Shop.dart';
import '../Products/Product.dart';
import '../Area & Sector/Sector.dart';
import '../Area & Sector/SelectSectorArea.dart';

class InvoiceList extends StatefulWidget {
  const InvoiceList({Key? key}) : super(key: key);

  @override
  _InvoiceListState createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> with RouteAware {
  late ProgressDialog pr;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _invoiceData();

    _customers();

    // TODO: Initialize _bannerAd
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    print("Route was pushed onto navigator and is now topmost route. sdg");
  }

  @override
  void didPopNext() {
    print("Covering route was popped off the navigator. dsgds");
    _invoiceData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Mini Order Book"),
          actions: [
            IconButton(
                onPressed: () async {
                  bool confirmDelete =
                      await showSendConfirmationDialog(context);
                  if (confirmDelete) {
                    int current = 0;
                    Map<String, dynamic> ordersMap = {};

                    showLoaderDialog(
                        context, "Sending data to server", "Please wait");
                    final refz = FirebaseDatabase.instance.ref();
                    final snapshot = await refz.child('orders').get();

                    if (snapshot.exists) {
                      print(snapshot.children.length);
                      if (snapshot.value != null) {
                        Map<Object?, dynamic> data = snapshot.value as Map<Object?,dynamic>;
                        // ordersMap.addAll(data);
                        Map<String,dynamic>nD={};
                        data.forEach((key, value) {
                          nD.putIfAbsent("$key", () => value);
                        });
                        List<int> firstNumbers = [];
                        nD.keys.forEach((key) {
                          int firstNumber = int.parse(key.split("-").first.trim());
                          firstNumbers.add(firstNumber);
                        });
                        ordersMap.addAll(nD);
                        current= firstNumbers.toSet().length+1;
                      }else{
                        print('No data available.');
                        current = 1;
                      }

                    } else {
                      print('No data available.');
                      current = 1;
                    }
                    DatabaseReference ref =
                        FirebaseDatabase.instance.reference().child("orders");
                    for (MyData customer in myDataList) {
                      await customer.setSectorArea();
                      ordersMap.addAll(customer.toMap(current));
                    }
                    // print(ordersMap);
                    await ref.set(ordersMap).then((value) {
                  // Data was successfully set
                  print("Data set successfully");
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                      msg: "Data sent to server",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.grey[600],
                      textColor: Colors.white,
                      fontSize: 16.0
                  );
                  deleteAll();
                }).catchError((error) {
                  // Handle the error
                  Navigator.pop(context);
                  print("Error setting data: ");
                  Fluttertoast.showToast(
                      msg: "Error setting data: ",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.grey[600],
                      textColor: Colors.white,
                      fontSize: 16.0
                  );
                });
                  }
                },
                icon: const Icon(Icons.send_sharp))
          ],
          leading: IconButton(
              onPressed: () async {
                bool confirmDelete =
                    await showDeleteConfirmationDialog(context);
                if (confirmDelete) {
                  // Perform delete action
                  deleteAll();
                } else {
                  // Cancel delete action
                }
              },
              icon: Icon(
                Icons.delete_sharp,
                color: Colors.redAccent,
              )),
        ),
        body: Stack(
          children: [
            ListView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              children: [
                myDataList.isNotEmpty
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
                                onChanged: onSearchTextChanged,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.cancel),
                                onPressed: () {
                                  controller.clear();
                                  onSearchTextChanged('');
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                              ),
                            ),
                          ),
                          _searchResult.isNotEmpty || controller.text.isNotEmpty
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemBuilder: (contextb, index) {
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0, horizontal: 24),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [],
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        "Invoice# ${_searchResult[index].time}"),
                                                    Text(
                                                        "Customer name: ${_searchResult[index].customer.address}"),
                                                    Text(
                                                        "Discount: ${_searchResult[index].discountTotal}"),
                                                    Text(
                                                        "Paid Amount: ${_searchResult[index].paidAmount}"),
                                                    Text(
                                                      "Due Amount: ${_searchResult[index].due.toStringAsFixed(0)}",
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundColor:
                                                          Colors.blue,
                                                      child: IconButton(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(0),
                                                        onPressed: () async {
                                                          AlertDialog alert =
                                                              AlertDialog(
                                                            title: const Text(
                                                                'Are you sure?'),
                                                            content: const Text(
                                                                'By clicking this button, this invoice will be redirect to editing'),
                                                            actions: <Widget>[
                                                              TextButton(
                                                                child:
                                                                    const Text(
                                                                        'Yes'),
                                                                onPressed: () {
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                MultiSelectCheckListScreen(myData: _searchResult[index]),
                                                                      ));
                                                                },
                                                              ),
                                                              TextButton(
                                                                child: const Text(
                                                                    'Cancel'),
                                                                onPressed: () {
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
                                                                (BuildContext
                                                                    context) {
                                                              return alert;
                                                            },
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 6,
                                                    ),
                                                    CircleAvatar(
                                                      backgroundColor:
                                                          Colors.red,
                                                      child: IconButton(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(0),
                                                        onPressed: () async {
                                                          AlertDialog alert =
                                                              AlertDialog(
                                                            title: const Text(
                                                                'Are you sure?'),
                                                            content: const Text(
                                                                'By clicking this button, this invoice will be deleted'),
                                                            actions: <Widget>[
                                                              TextButton(
                                                                child:
                                                                    const Text(
                                                                        'Yes'),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                  deleteMyDataSearch(
                                                                      _searchResult[
                                                                          index]);
                                                                },
                                                              ),
                                                              TextButton(
                                                                child: const Text(
                                                                    'Cancel'),
                                                                onPressed: () {
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
                                                                (BuildContext
                                                                    context) {
                                                              return alert;
                                                            },
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    // const SizedBox(
                                                    //   height: 6,
                                                    // ),
                                                    // CircleAvatar(
                                                    //   backgroundColor:
                                                    //       Colors.blue,
                                                    //   child: IconButton(
                                                    //     padding:
                                                    //         const EdgeInsets
                                                    //             .all(0),
                                                    //     onPressed: () async {
                                                    //       Navigator.push(
                                                    //           contextb,
                                                    //           MaterialPageRoute(
                                                    //               builder: (contextb) =>
                                                    //                   MyPdfWidget(
                                                    //                       myData:
                                                    //                           _searchResult[index])));
                                                    //     },
                                                    //     icon: const Icon(
                                                    //       Icons.print,
                                                    //       color: Colors.white,
                                                    //     ),
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Container(
                                                margin: EdgeInsets.only(top: 5),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 3),
                                                decoration: const BoxDecoration(
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                            const Radius
                                                                .circular(4)),
                                                    color: Colors.amber),
                                                child: Text(
                                                    _searchResult[index].date)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  itemCount: _searchResult == null
                                      ? 0
                                      : _searchResult.isEmpty
                                          ? 0
                                          : _searchResult.length)
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemBuilder: (contextb, index) {
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0, horizontal: 24),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [],
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Invoice# ${myDataList[index].time}",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.7,
                                                      child: Text(
                                                          "Customer name: ${myDataList[index].customer.name}",
                                                          softWrap: true),
                                                    ),
                                                    SizedBox(
                                                      height: 2,
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.7,
                                                      child: Text(
                                                          "Discount: ${myDataList[index].discountTotal}"),
                                                    ),
                                                    SizedBox(
                                                      height: 2,
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.7,
                                                      child: Text(
                                                          "Product Quantity: ${myDataList[index].product.length}"),
                                                    ),
                                                    SizedBox(
                                                      height: 2,
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.7,
                                                      child: Text(
                                                        "Total Amount: ${myDataList[index].due.toStringAsFixed(0)}",
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundColor:
                                                          Colors.blue,
                                                      child: IconButton(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(0),
                                                        onPressed: () async {
                                                          AlertDialog alert =
                                                              AlertDialog(
                                                            title: const Text(
                                                                'Are you sure?'),
                                                            content: const Text(
                                                                'By clicking this button, this invoice will be redirect to editing'),
                                                            actions: <Widget>[
                                                              TextButton(
                                                                child:
                                                                    const Text(
                                                                        'Yes'),
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                MultiSelectCheckListScreen(myData: myDataList[index]),
                                                                      ));
                                                                },
                                                              ),
                                                              TextButton(
                                                                child: const Text(
                                                                    'Cancel'),
                                                                onPressed: () {
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
                                                                (BuildContext
                                                                    context) {
                                                              return alert;
                                                            },
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 6,
                                                    ),
                                                    SizedBox(
                                                      height: 6,
                                                    ),
                                                    CircleAvatar(
                                                      backgroundColor:
                                                          Colors.red,
                                                      child: IconButton(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(0),
                                                        onPressed: () async {
                                                          AlertDialog alert =
                                                              AlertDialog(
                                                            title: const Text(
                                                                'Are you sure?'),
                                                            content: const Text(
                                                                'By clicking this button, this invoice will be deleted'),
                                                            actions: <Widget>[
                                                              TextButton(
                                                                child:
                                                                    const Text(
                                                                        'Yes'),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                  deleteMyData(
                                                                      myDataList[
                                                                          index]);
                                                                },
                                                              ),
                                                              TextButton(
                                                                child: const Text(
                                                                    'Cancel'),
                                                                onPressed: () {
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
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    // const SizedBox(
                                                    //   height: 6,
                                                    // ),
                                                    // CircleAvatar(
                                                    //   backgroundColor:
                                                    //       Colors.blue,
                                                    //   child: IconButton(
                                                    //     padding:
                                                    //         const EdgeInsets
                                                    //             .all(0),
                                                    //     onPressed: () async {
                                                    //       Navigator.push(
                                                    //           contextb,
                                                    //           MaterialPageRoute(
                                                    //               builder: (contextb) =>
                                                    //                   MyPdfWidget(
                                                    //                       myData:
                                                    //                           myDataList[index])));
                                                    //     },
                                                    //     icon: const Icon(
                                                    //       Icons.print,
                                                    //       color: Colors.white,
                                                    //     ),
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 3),
                                                margin: EdgeInsets.only(top: 5),
                                                decoration: const BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(4)),
                                                    color: Colors.amber),
                                                child: Text(
                                                    myDataList[index].date)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  itemCount: myDataList == null
                                      ? 0
                                      : myDataList.isEmpty
                                          ? 0
                                          : myDataList.length),
                          // Column(
                          //   children: [
                          //     // Padding(
                          //     //   padding: const EdgeInsets.symmetric(horizontal: 36.0),
                          //     //   child: ElevatedButton(
                          //     //       onPressed: () async {
                          //     //         // "Sector: ${info[0]["SecNm"]} Area: ${info[0]["AreaNm"];
                          //     //         bool confirmDelete = await showSendConfirmationDialog(context);
                          //     //         if (confirmDelete) {
                          //     //           showLoaderDialog(context, "Sending data to server", "Please wait");
                          //     //           DatabaseReference ref =
                          //     //           FirebaseDatabase.instance.ref("orders");
                          //     //
                          //     //           Map<String, dynamic> ordersMap = {};
                          //     //
                          //     //           for (MyData customer in myDataList) {
                          //     //             ordersMap["ORDER - ${customer.time}"] = customer.toMap();
                          //     //           }
                          //     //           await ref.set(ordersMap).then((value) {
                          //     //             // Data was successfully set
                          //     //             print("Data set successfully");
                          //     //             Navigator.pop(context);
                          //     //             Fluttertoast.showToast(
                          //     //                 msg: "Data sent to server",
                          //     //                 toastLength: Toast.LENGTH_SHORT,
                          //     //                 gravity: ToastGravity.BOTTOM,
                          //     //                 timeInSecForIosWeb: 1,
                          //     //                 backgroundColor: Colors.grey[600],
                          //     //                 textColor: Colors.white,
                          //     //                 fontSize: 16.0
                          //     //             );
                          //     //           }).catchError((error) {
                          //     //             // Handle the error
                          //     //             Navigator.pop(context);
                          //     //             print("Error setting data: " + error.message);
                          //     //             Fluttertoast.showToast(
                          //     //                 msg: "Error setting data: " + error.message,
                          //     //                 toastLength: Toast.LENGTH_SHORT,
                          //     //                 gravity: ToastGravity.BOTTOM,
                          //     //                 timeInSecForIosWeb: 1,
                          //     //                 backgroundColor: Colors.grey[600],
                          //     //                 textColor: Colors.white,
                          //     //                 fontSize: 16.0
                          //     //             );
                          //     //           });
                          //     //
                          //     //         }
                          //     //
                          //     //       },
                          //     //       child: const Text("Send all data")),
                          //     // ),
                          //     const SizedBox(height: 12),
                          //     Padding(
                          //       padding: const EdgeInsets.symmetric(horizontal: 36.0),
                          //       child: ElevatedButton(
                          //           onPressed: () async{
                          //             bool confirmDelete = await showDeleteConfirmationDialog(context);
                          //             if (confirmDelete) {
                          //               // Perform delete action
                          //               await FirebaseDatabase.instance
                          //                   .ref('orders')
                          //                   .remove();
                          //               deleteAll();
                          //             } else {
                          //               // Cancel delete action
                          //             }
                          //
                          //           },
                          //           child: const Text("Delete all data"),
                          //           style: ElevatedButton.styleFrom(
                          //             backgroundColor: Colors.red,
                          //           )),
                          //     ),
                          //     const SizedBox(height: 100)
                          //   ],
                          // ),
                          const SizedBox(
                            height: 48,
                          )
                        ],
                      )
                    : Center(
                        child: Container(
                          child: Column(
                            children: [
                              Lottie.asset(kIsWeb
                                  ? 'not_found.json'
                                  : 'assets/not_found.json'),
                              const Text(
                                "No invoice created yet",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
        resizeToAvoidBottomInset: false,
        floatingActionButton: Container(
          child: FloatingActionButton.extended(
            onPressed: () async {
              /* try {
                final result = await InternetAddress.lookup('example.com');
                if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                  print("connected");*/
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectSectorAndArea(),
                  ));
              /* } else {
                  print('not connected');
                  ShowNoInternetAlert(context);
                }
              } on SocketException catch (_) {
                print('not connected');
                ShowNoInternetAlert(context);
              }*/
            },
            label: const Text("Add New"),
            icon: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Confirmation"),
          content: const Text("Are you sure you want to delete this item?"),
          actions: <Widget>[
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text("DELETE"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  static showLoaderDialog(BuildContext context, title, subtitle) {
    AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))),
      contentPadding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 24),
      content: WillPopScope(
        onWillPop: () => Future.value(true),
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator()),
                  SizedBox(
                    width: 10,
                  ),
                  Container(
                      margin: EdgeInsets.only(left: 7), child: Text(subtitle)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<bool> showSendConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Send data confirmation"),
          content: const Text("Are you sure to send all data to backend?"),
          actions: <Widget>[
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text("SEND"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>>? info;

  Future<void> _invoiceData() async {
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
    var box1 = await Hive.openBox<bool>("Hive.WillShow");
    myDataList.clear();

    for (int i = 0; i < box.values.length; i++) {
      var element = box.values.elementAt(i);
      element.willShowPhone = box1.get(element.time) ?? false;
      info = await element.getAddressInfo;
      await element.setSectorArea();
      myDataList.add(element);
    }
    setState(() {});
  }

  List<Area> ares = [];
  List<Sector> sectors = [];
  List<Customer> customer = [];

  Future<void> _customers() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CustomerAdapter());
    }
    var box = await Hive.openBox<Customer>("Customer");
    setState(() {
      customer.clear();
      for (var element in box.values) {
        if (element.name == "") {
          customer.add(element);
        }
      }
    });
    print(customer);
  }

  List<MyData> myDataList = [];

  Future<void> deleteMyData(MyData myData) async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductAdapter());
    }
    var box = await Hive.openBox<MyData>("Hive.Invoices");
    box.delete(myData.time);
    setState(() {
      myDataList.removeWhere((element) => element.time == myData.time);
    });
    print(box.values);
  }

  Future<void> deleteAll() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductAdapter());
    }
    var box = await Hive.openBox<MyData>("Hive.Invoices");
    box.clear();
    setState(() {
      myDataList.clear();
    });
    print(box.values);
  }

  Future<void> deleteMyDataSearch(MyData myData) async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductAdapter());
    }
    var box = await Hive.openBox<MyData>("Hive.Invoices");
    box.delete(myData.time);
    setState(() {
      myDataList.removeWhere((element) => element.time == myData.time);
      _searchResult.removeWhere((element) => element.time == myData.time);
    });
    print(box.values);
  }

  void showEditProductDialog(BuildContext context, int index) {
    double countQuantity = 0;
    TextEditingController quantityController = TextEditingController();
    quantityController.text = countQuantity.toStringAsFixed(0);

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
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Text("Add Discount"),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.maxFinite,
                      child: const TextField(
                        keyboardType: TextInputType.number,
                        autofocus: false,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12.0, top: 12),
                      child: Text("Add Quantity: "),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 10,
                          child: IconButton(
                              onPressed: () {
                                if (double.parse(quantityController.text) > 1) {
                                  quantityController.text = (double.parse(
                                              quantityController.text
                                                  .toString()) -
                                          1)
                                      .toStringAsFixed(0);
                                }
                              },
                              icon: const Icon(Icons.remove)),
                        ),
                        Expanded(
                          flex: 20,
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            autofocus: false,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              hintText: "Quantity",
                            ),
                            onChanged: (val) {
                              if (val.isEmpty) {
                                quantityController.text = "1";
                              } else if (double.parse(val).toInt() < 1) {
                                quantityController.text = "1";
                              } else {
                                quantityController.text = val;
                              }
                            },
                          ),
                        ),
                        Expanded(
                            flex: 10,
                            child: IconButton(
                                onPressed: () {
                                  quantityController.text = (double.parse(
                                              quantityController.text
                                                  .toString()) +
                                          1)
                                      .toStringAsFixed(0);
                                },
                                icon: const Icon(Icons.add))),
                      ],
                    ),
                  ),
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
                      onPressed: () {},
                      child: const Text("Cancel")),
                  ElevatedButton(
                      style: ButtonStyle(
                          elevation: MaterialStateProperty.all(0),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 24))),
                      onPressed: () {},
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

  void ShowNoInternetAlert(BuildContext context) {
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
              ConstantWidget.SmallNoInternetWidget(context),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "To create new invoice please turn on your internet connection.",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blue),
                          elevation: MaterialStateProperty.all(0),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 24))),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Ok")),
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

  TextEditingController controller = TextEditingController();

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    for (var element in myDataList) {
      if (element.customer.name
          .trim()
          .toLowerCase()
          .contains(text.trim().toLowerCase())) {
        await element.setSectorArea();
        _searchResult.add(element);
      }
    }

    setState(() {});
  }

  List<MyData> _searchResult = [];
}

class Exercise {
  String name;

  Exercise({required this.name});
}

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:Mini_Bill/Widgets/ConstantWidget.dart';
import 'package:Mini_Bill/Customer/Customer.dart';
import 'package:Mini_Bill/Invoices/InvoiceData.dart';
import 'package:Mini_Bill/Invoices/InvoicesList.dart';
import 'package:Mini_Bill/Products/Product.dart';
import 'package:Mini_Bill/Products/SelectProducts.dart';

import 'package:Mini_Bill/Utils/Utility.dart';
import 'package:Mini_Bill/Utils/Utils.dart';
import 'package:Mini_Bill/Utils/db.dart';
import 'package:Mini_Bill/Widgets/screen_size.dart';
import 'package:autocomplete_textfield_ns/autocomplete_textfield_ns.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Customer/Customer.g.dart';
import 'Customer/SelectCustomer.dart';
import 'Extra/SelectShop.dart';
import 'Extra/Shop.dart';
import 'Firebase/firebase_options.dart';
import 'Invoices/invoice.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    Hive.init((await getApplicationDocumentsDirectory()).path);
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final dbAdded = prefs.getBool("DB_ADDED");
  if(dbAdded==null){
    openDB();
  }/*else{

  }*/

  await waitScreenSizeAvailable();
  runApp(MaterialApp(
    home: const InvoiceList(),
    title: "MiniPos",
    navigatorObservers: [routeObserver],
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var customerNameC = TextEditingController();
  var customerAddressC = TextEditingController();
  var customerPhoneC = TextEditingController();
  var customerEmailC = TextEditingController();
  var termsAndConditionC = TextEditingController();
  var thankingQuoteC = TextEditingController();
  var brandNameC = TextEditingController();
  var paymentInfoC = TextEditingController();
  bool mainImageVisibility = false;
  var skuC = TextEditingController();
  var productNameC = TextEditingController();
  var priceC = TextEditingController();
  var quantityC = TextEditingController();
  var discountC = TextEditingController();
  var vatC = TextEditingController();
  var shippingC = TextEditingController();
  var taxC = TextEditingController();
  var paidAmountC = TextEditingController();

  final paymentKey = GlobalKey<FormState>();
  Image image = Image.asset(
    "name",
    height: 100,
    width: 100,
  );

  String currentText = "";

  String selected = "";

  var autoKey = GlobalKey<AutoCompleteTextFieldState<Customer>>();
  var productAutoKey = GlobalKey<AutoCompleteTextFieldState<Product>>();
  var IMAGE_KEY = 'IMAGE_KEY';

  pickImage(ImageSource source) async {
    if (!kIsWeb) {
      final ImagePicker _picker = ImagePicker();

      XFile? _image = (await _picker.pickImage(source: source));

      File file = File(_image!.path);
      File? croppedFile = await ImageCropper().cropImage(
          sourcePath: file.path,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
          androidUiSettings: const AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.blueAccent,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          iosUiSettings: const IOSUiSettings(
            minimumAspectRatio: 1.0,
          ));

      if (croppedFile != null) {
        setState(() {
          image = Image.file(croppedFile, height: 50, width: 200);
          mainImageVisibility = true;
        });
        ImageSharedPrefs.saveImageToPrefs(
            ImageSharedPrefs.base64String(croppedFile.readAsBytesSync()),
            IMAGE_KEY);
      } else {
        setState(() {
          mainImageVisibility = false;
        });
        print('Error picking image!');
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        Uint8List? fileBytes = result.files.first.bytes;
        if (fileBytes != null) {
          ImageSharedPrefs.saveImageToPrefs(
              ImageSharedPrefs.base64String(fileBytes), IMAGE_KEY);
          final imageString =
              await ImageSharedPrefs.loadImageFromPrefs(IMAGE_KEY);
          setState(() {
            mainImageVisibility = true;
            image = ImageSharedPrefs.imageFrom64BaseString(imageString!);
          });
        } else {
          setState(() {
            mainImageVisibility = false;
          });
          Utils.dTPrint("Pick failed");
        }
      } else {
        // User canceled the picker
        setState(() {
          mainImageVisibility = false;
        });
        print('Error picking image!');
        Utils.dTPrint("Pick failed");
      }
    }
  }

  loadImageFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final imageKeyValue = prefs.getString(IMAGE_KEY);
    if (imageKeyValue != null) {
      final imageString = await ImageSharedPrefs.loadImageFromPrefs(IMAGE_KEY);
      setState(() {
        mainImageVisibility = true;
        image = ImageSharedPrefs.imageFrom64BaseString(imageString!);
      });
    }
  }

  List<Customer> customer = [];

  @override
  void initState() {
    super.initState();
    loadImageFromPrefs();
    loadShop();
    vatC.text = "0";
    taxC.text = "0";
    paidAmountC.text = "0";
    shippingC.text = "0";
    discountC.text = "0";
    priceC.text = "0";

    _customers();
    _shops();

    getInvoiceId();

    // TODO: Initialize _bannerAd

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

  bool willPhoneShow = false;



  @override
  void dispose() {
    super.dispose();
  }

  Customer? customerModel/*= Customer("", "", "", "", Utils.getTimestamp())*/;

  Shop shop = Shop(" ", "", "", "", "", Utils.getTimestamp());
  List<Shop> shopList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mini POS"),
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.only(
                  top: 12, bottom: 100, right: 6, left: 6),
              children: [
                Visibility(
                  visible: false,
                  child: Card(
                    margin: const EdgeInsets.all(6),
                    child: InkWell(
                      onTap: () async {
                        Shop result = await Navigator.of(context)
                            .push(MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) {
                            return SelectShop(
                              shop: shopList,
                            );
                          },
                        ));
                        if (result != null) {
                          setState(() {
                            shop = result;
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 16.0, bottom: 16, right: 12, left: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            shop.name != ""
                                ? Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 50,
                                          child: shop.shopKey == ""
                                              ? Container(
                                                  color: Colors.black,
                                                )
                                              : ImageSharedPrefs
                                                  .imageFrom64BaseString(
                                                  shop.shopKey,
                                                ),
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(shop.name),
                                              Text("Address: " + shop.address),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 20.0),
                                      child: Text("Select Shop"),
                                    ),
                                  ),
                            const Padding(
                              padding: EdgeInsets.only(left: 12.0, right: 12),
                              child: Icon(Icons.arrow_forward_ios_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.all(6),
                  child: InkWell(
                    /*onTap: () async {
                      Customer result = await Navigator.of(context)
                          .push(MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) {
                          return SelectCustomer( areaId: -1,sectorId: -1,
                           *//* customer: customer,*//*
                          );
                        },
                      ));
                      if (result != null) {
                        setState(() {
                          customerModel = result;
                        });
                        final result1 = await Navigator.of(context)
                            .push(MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) {
                            return MultiSelectCheckListScreen(
                              customer: customerModel!,
                            );
                          },
                        ));
                        if (result1.isNotEmpty) {
                          print(qts);
                          List<Product> result = result1[0];
                          Customer customer = result1[1];
                          setState(() {
                            for (var product in result) {
                              // addItem(element);
                              if (products
                                  .where((element) => element.id == product.id)
                                  .isEmpty) {
                                products.add(product);
                              } else {
                                var index = products.indexWhere(
                                        (element) => element.id == product.id);
                                print(products[index]);
                                products[index].quantity =
                                    product.quantity;
                                products[index].discount = product.discount;
                              }
                            }
                            setState(() {
                              customerModel = customer;
                            });
                          });
                        }
                      }
                    },*/
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 16.0, bottom: 16, right: 12, left: 4),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 9,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Text(customerModel == null
                                    ? "Select Customer"
                                    : customerModel!.name +
                                        "\n" +
                                        customerModel!.email +
                                        "\n" +
                                        customerModel!.phone),
                              )),
                          const Expanded(
                              flex: 1,
                              child: Icon(Icons.arrow_forward_ios_rounded)),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.all(6),
                  child: InkWell(
                   /* onTap: () async {
                      if (customerModel != null) {
                        final result1 = await Navigator.of(context)
                            .push(MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) {
                            return MultiSelectCheckListScreen(
                              customer: customerModel!,
                            );
                          },
                        ));
                        if (result1.isNotEmpty) {
                          print(qts);
                          List<Product> result = result1[0];
                          Customer customer = result1[1];
                          setState(() {
                            for (var product in result) {
                              // addItem(element);
                              if (products
                                  .where((element) => element.id == product.id)
                                  .isEmpty) {
                                products.add(product);
                              } else {
                                var index = products.indexWhere(
                                    (element) => element.id == product.id);
                                print(products[index]);
                                products[index].quantity =
                                     product.quantity;
                                products[index].discount = product.discount;
                              }
                            }
                            setState(() {
                              customerModel = customer;
                            });
                          });
                        }
                      } else {
                        Fluttertoast.showToast(
                          msg: "Please select customer first",
                          toastLength: Toast.LENGTH_SHORT,
                          // or Toast.LENGTH_LONG
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.grey[600],
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      }
                    },*/
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 16.0, bottom: 16, right: 12, left: 4),
                      child: Row(
                        children: const [
                          Expanded(
                              flex: 9,
                              child: Padding(
                                padding: EdgeInsets.only(left: 16.0),
                                child: Text("Add Products"),
                              )),
                          Expanded(
                              flex: 1,
                              child: Icon(Icons.arrow_forward_ios_rounded)),
                        ],
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: products.isNotEmpty,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: Text("Products",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const Divider(),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 2),
                                        child: Row(
                                          children: [
                                            Text(
                                              "Qty: ${products[index].quantity}",
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            products[index].discount != 0
                                                ? VerticalDivider()
                                                : SizedBox(),
                                            products[index].discount != 0
                                                ? Text(
                                                    "Dis: ${products[index].discount}",
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  )
                                                : SizedBox(),
                                          ],
                                        ),
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(3)),
                                          color: Colors.amber,
                                        ),
                                      ),
                                      Text(
                                        "SKU: ${products[index].sku}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(products[index].productName.trim() +
                                          " (X${products[index].quantity})"),
                                      Text("Price: ${products[index].price}"),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const SizedBox(height: 10),
                                      Visibility(
                                        visible: false,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.blue,
                                          child: IconButton(
                                            onPressed: () {
                                              showEditProductDialog(
                                                  context, products[index]);
                                            },
                                            icon: const Icon(
                                              Icons.tune,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      CircleAvatar(
                                        backgroundColor: Colors.red,
                                        child: IconButton(
                                          onPressed: () {
                                            products.removeAt(index);
                                            setState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              );
                            },
                            itemCount: products.length,
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return const Divider();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: false,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 12.0, right: 12, top: 16, bottom: 16),
                      child: Form(
                          key: paymentKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12.0),
                                child: Text("Payment",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextFormField(
                                  controller: vatC,
                                  decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'VAT(%)',
                                      hintText: 'Enter VAT(%)',
                                      border: OutlineInputBorder()),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextFormField(
                                  controller: taxC,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'TAX(%)',
                                      hintText: 'Enter TAX(%)',
                                      border: OutlineInputBorder()),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextFormField(
                                  controller: shippingC,
                                  decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'Shipping Cost',
                                      hintText: 'Enter Shipping Cost',
                                      border: OutlineInputBorder()),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextFormField(
                                  controller: paidAmountC,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'Paid Amount',
                                      hintText: 'Enter paid amount',
                                      border: OutlineInputBorder()),
                                ),
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                      value: willPhoneShow,
                                      onChanged: (val) => setState(() {
                                            willPhoneShow = val ?? false;
                                          })),
                                  Text("Print Customer Mobile No.")
                                ],
                              )
                            ],
                          )),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                          onPressed:
                              products.isNotEmpty && customerModel != null
                                  ? () {
                                      showAlertToSubmit();
                                    }
                                  : null,
                          child: Text('Order Book')),
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    IconButton(
                      onPressed: () {
                        showPreview();
                      },
                      icon: Icon(Icons.print),
                      tooltip: "Print Preview",
                    ),
                    SizedBox(
                      width: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Product> products = [];
  final rows = <TableRow>[];
  bool showMobile = false;

  bool visibility = true;

  MaterialColor colorCustom = const MaterialColor(0xF62408FF, <int, Color>{
    50: Color.fromRGBO(246, 36, 8, 0.1),
    100: Color.fromRGBO(246, 36, 8, 0.2),
    200: Color.fromRGBO(246, 36, 8, 0.3),
    300: Color.fromRGBO(246, 36, 8, 0.4),
    400: Color.fromRGBO(246, 36, 8, 0.5),
    500: Color.fromRGBO(246, 36, 8, 0.6),
    600: Color.fromRGBO(246, 36, 8, 0.7),
    700: Color.fromRGBO(246, 36, 8, 0.8),
    800: Color.fromRGBO(246, 36, 8, 0.9),
    900: Color.fromRGBO(246, 36, 8, 1.0),
  });

  void showEditProductDialog(BuildContext context, Product product) {
    var countQuantity = product.quantity;
    TextEditingController quantityController = TextEditingController();
    quantityController.text = countQuantity.toStringAsFixed(0);
    var discountC = TextEditingController();
    discountC.text = product.discount.toStringAsFixed(0);

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
                      child: TextField(
                        controller: discountC,
                        keyboardType: TextInputType.number,
                        autofocus: false,
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
                        int index =
                            findProductUsingIndexWhere(products, product);
                        setState(() {
                          products[index].quantity =
                              int.parse(quantityController.text);
                          products[index].discount = int.parse(discountC.text);
                          print(products);
                        });

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

  int findProductUsingIndexWhere(List<Product> product, Product productObj) {
    // Find the index of person. If not found, index = -1
    final index =
        product.indexWhere((element) => element.sku == productObj.sku);
    if (index >= 0) {
      print('Using indexWhere: ${product[index]}');
    }
    return index;
  }

  void addItem(Product product) async {
    /* setState(() {

    });*/
  }

  List<quantities> qts = [];

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  final ScrollController _scrollController = ScrollController();

  void saveShopInfo(shopName, shopInfo, termAndCondition, welcomeText) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString("shopName", shopName);
    preferences.setString("shopInfo", shopInfo);
    preferences.setString("termAndCondition", termAndCondition);
    preferences.setString("welcomeText", welcomeText);
  }

  void loadShop() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CustomerAdapter());
    }

    var box = await Hive.openBox<Customer>("Customer");
    List<Customer> customers = [];
    for (var element in box.values) {
      customers.add(element);
    }
  }

  void saveCustomer(String boxName, Customer customer) async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CustomerAdapter());
    }
    var box = await Hive.openBox<Customer>(boxName);
    box.put(customer.phone, customer);
  }

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

  Future<void> _shops() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ShopAdapter());
    }

    var box = await Hive.openBox<Shop>("Shop");
    setState(() {
      shopList.clear();
      for (var element in box.values) {
        shopList.add(element);
      }
    });
  }

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

  void showAlertToSubmit() {
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
            "Alert!",
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
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Are you sure to create a new order?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blue),
                          elevation: MaterialStateProperty.all(0),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 24))),
                      onPressed: () {
                        Navigator.pop(context);
                        var time =
                            ((DateTime.now().millisecondsSinceEpoch) / 1000)
                                .toStringAsFixed(0);
                        if (shop.name != "") {
                          MyData md = MyData(
                              products,
                              generatedInvoiceId,
                              double.parse(vatC.text) / 100,
                              double.parse(taxC.text) / 100,
                              paidAmountC.text,
                              shippingC.text,
                              customerModel!,
                              shop,
                              _formatDate(DateTime.now()));
                          md.willShowPhones = willPhoneShow;
                          saveInvoice(willPhoneShow, md);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyPdfWidget(
                                      myData: MyData(
                                          products,
                                          generatedInvoiceId,
                                          double.parse(vatC.text) / 100,
                                          double.parse(taxC.text) / 100,
                                          paidAmountC.text,
                                          shippingC.text,
                                          customerModel!,
                                          shop,
                                          _formatDate(DateTime.now())),
                                    )),
                          );
                        }
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

  void showPreview() {
    if (shop.name != "") {
      MyData md = MyData(
          products,
          generatedInvoiceId,
          double.parse(vatC.text) / 100,
          double.parse(taxC.text) / 100,
          paidAmountC.text,
          shippingC.text,
          customerModel!,
          shop,
          _formatDate(DateTime.now()));
      md.willShowPhones = willPhoneShow;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MyPdfWidget(
                  myData: MyData(
                      products,
                      generatedInvoiceId,
                      double.parse(vatC.text) / 100,
                      double.parse(taxC.text) / 100,
                      paidAmountC.text,
                      shippingC.text,
                      customerModel!,
                      shop,
                      _formatDate(DateTime.now())),
                )),
      );
    }
  }
}

class quantities {
  int quantity;
  String id;

  quantities(this.quantity, this.id);

  @override
  String toString() {
    return 'quantities{quantity: $quantity, id: $id}';
  }
}

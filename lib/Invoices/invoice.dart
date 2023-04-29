import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:Mini_Bill/Widgets/ConstantWidget.dart';
import 'package:Mini_Bill/Widgets/DynamicPdfSizeScreen.dart';
import 'package:Mini_Bill/Products/Product.dart';
import 'package:Mini_Bill/Utils/Utility.dart';
import 'package:Mini_Bill/Utils/Utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../Customer/Customer.dart';
import 'InvoiceData.dart';

MyData? _myData;

Future<void> _saveAsFile(BuildContext context, LayoutCallback build,
    PdfPageFormat pageFormat) async {
  final bytes = await build(pageFormat);

  final appDocDir = await getApplicationDocumentsDirectory();
  final appDocPath = appDocDir.path;
  final file = File(appDocPath + '/' + '${_myData!.time}.pdf');
  Utils.dTPrint('Save as file ${file.path} ...');
  await file.writeAsBytes(bytes);
  await OpenFile.open(file.path);
}

class MyPdfWidget extends StatefulWidget {
  final MyData myData;

  MyPdfWidget({Key? key, required this.myData}) : super(key: key);

  @override
  _MyPdfWidgetState createState() => _MyPdfWidgetState();
}

class _MyPdfWidgetState extends State<MyPdfWidget> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    openBox();
    setState(() {
      _myData = widget.myData;
    });
    // checkData();
  }


  Future<void> checkData() async {
    SharedPreferences _pref = await SharedPreferences.getInstance();
    setState(() {
      width = (_pref.getDouble(ConstantWidget.width) == 0
          ? width
          : _pref.getDouble(ConstantWidget.width))!;
      height = (_pref.getDouble(ConstantWidget.height) == 0
          ? height
          : _pref.getDouble(ConstantWidget.height))!;
    });
  }

  double width = 104.8, height = 235;
  bool willShow = false;

  @override
  Widget build(BuildContext context) {
    final actions = <PdfPreviewAction>[
      if (!kIsWeb)
        const PdfPreviewAction(
          icon: Icon(Icons.save),
          onPressed: _saveAsFile,
        )
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Bill to- ' + widget.myData.customer.name),
        // leading: Icon(Icons.settings),
        actions: [
          IconButton(
            icon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.settings),
            ),
            onPressed: () async {
              bool result =
                  await Navigator.of(context).push(MaterialPageRoute<dynamic>(
                builder: (BuildContext context) {
                  return DynamicPageSize();
                },
              ));
              if (result != null) {
                SharedPreferences _pref = await SharedPreferences.getInstance();
                setState(() {
                  width = (_pref.getDouble(ConstantWidget.width) == 0
                      ? width
                      : _pref.getDouble(ConstantWidget.width))!;
                  height = (_pref.getDouble(ConstantWidget.height) == 0
                      ? height
                      : _pref.getDouble(ConstantWidget.height))!;
                });
              }
            },
          )
        ],
      ),
      body: PdfPreview(
        maxPageWidth: 700,
        initialPageFormat: PdfPageFormat(
          width * PdfPageFormat.mm,
          height * PdfPageFormat.mm,
          marginAll: 0 * PdfPageFormat.cm,
        ),
        build: (format) => generateInvoice(format, widget.myData),
        actions: actions,
        canChangePageFormat: false,
      ),
    );
  }

  Future<void> openBox() async {
    var box1 = await Hive.openBox<bool>("Hive.WillShow");
    setState(() {
      widget.myData.willShowPhone = box1.get(widget.myData.time) ?? false;
    });
  }
}

Future<Uint8List> generateInvoice(
    PdfPageFormat pageFormat, MyData myData) async {
  final invoice = Invoice(
    invoiceNumber: "${myData.time}",
    products: myData.products,
    customerName: myData.customer.name,
    customerAddress: myData.customer.address,
    paymentInfo: myData.shop.address,
    tax: myData.tax,
    baseColor: PdfColors.grey300,
    accentColor: PdfColors.blueGrey900,
  );

  return await invoice.buildPdf(pageFormat, myData);
}

class Invoice {
  Invoice({
    required this.products,
    required this.customerName,
    required this.customerAddress,
    required this.invoiceNumber,
    required this.tax,
    required this.paymentInfo,
    required this.baseColor,
    required this.accentColor,
  });

  final List<Product> products;
  final String customerName;
  final String customerAddress;
  final String invoiceNumber;
  final double tax;
  final String paymentInfo;
  final PdfColor baseColor;
  final PdfColor accentColor;

  static const _darkColor = PdfColors.black;
  static const _whiteColor = PdfColors.white;
  static const _thankingBd = PdfColors.blue500;
  static const _lightColor = PdfColors.white;
  static const _blackColor = PdfColors.black;
  static var welcomeTC = PdfColor.fromHex("#106366");

  PdfColor get _baseTextColor => _darkColor;

  PdfColor get _accentTextColor => _darkColor;

  PdfColor get _blackTextColor => _blackColor;
  PdfColor get welcomeTextColor => welcomeTC;

  double get _total =>
      products.map<double>((p) => p.total).reduce((a, b) => a + b);

  double get _grandTotal {
    if (_myData!.tax == "0" && _myData!.vat == "0") {
      return (_total + int.parse(_myData!.shippingCost));
    } else if (_myData!.vat == "0") {
      return (_total + (_total) * (_myData!.tax)) +
          int.parse(_myData!.shippingCost);
    } else if (_myData!.tax == "0") {
      return (_total + ((_total) * (_myData!.vat))) +
          int.parse(_myData!.shippingCost);
    } else {
      return (_total + (_total * (_myData!.tax) + (_total * _myData!.vat))) +
          int.parse(_myData!.shippingCost);
    }
  }

  double get due {
    return _grandTotal - int.parse(_myData!.paidAmount);
  }

  String? _logo;

  String? _bgShape;
  var IMAGE_KEY = 'IMAGE_KEY';

  Future<Uint8List> buildPdf(PdfPageFormat pageFormat, MyData myData) async {
    // Create a PDF document.
    final doc = pw.Document();

    List<Map<String, dynamic>> info=await myData.getAddressInfo;

    _logo = await rootBundle.loadString('assets/medail.svg');
    _bgShape = await rootBundle.loadString('assets/bg2.svg');
    var bytesN = await rootBundle.load('assets/font/hs_m.ttf');
    var bytesB = await rootBundle.load('assets/font/hs_b.ttf');
    var bytesI = await rootBundle.load('assets/font/hs_m.ttf');
    final imageString = await ImageSharedPrefs.loadImageFromPrefs(IMAGE_KEY);
    SharedPreferences _pref = await SharedPreferences.getInstance();
    var width = (_pref.getDouble(ConstantWidget.width) ?? 104.8);
    var height = (_pref.getDouble(ConstantWidget.height) ?? 235);
    doc.addPage(
      pw.MultiPage(
        pageTheme: _buildTheme(
            PdfPageFormat(
              width * PdfPageFormat.mm,
              height * PdfPageFormat.mm,
              marginTop: .5 * PdfPageFormat.cm,
              marginBottom: .5 * PdfPageFormat.cm,
              marginLeft: .8 * PdfPageFormat.cm,
              marginRight: .8 * PdfPageFormat.cm,
            ),
            pw.TtfFont(bytesN),
            pw.TtfFont(bytesB),
            pw.TtfFont(bytesI)),
        // header: _buildHeader,
        footer: (context) {
          return pw.Column(children: [
            pw.Container(
                child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 5, top: 5),
                    child: pw.Text(
                      '${context.pageNumber}/${context.pagesCount}',
                      //Page
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.black,
                      ),
                    )),
              ],
            ))
          ]);
        },
        build: (context) => [
          // pw.SizedBox(height: 20),
          _contentMainHeader(context, myData, imageString, doc,width,height,info),
          pw.SizedBox(height: 5),
          // _contentHeader(context),
          _contentTable(context, myData),
          pw.SizedBox(height: 10),
          _contentFooter(context, myData),
          // pw.SizedBox(height: 10),
          _termsAndConditions(context, myData),
          pw.SizedBox(height: 10),
          if (myData.willShow)
            pw.Row(
              children: [
                pw.Text("Customer Phone:   ",
                    style: pw.TextStyle(
                        color: _blackTextColor,
                        fontSize: 16)),
                pw.Text("${myData.customer.phone}",
                    style: pw.TextStyle(
                        color: _blackTextColor,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18)),
              ]
            )

        ],
      ),
    );

    // Return the PDF file content
    return doc.save();
  }

  pw.PageTheme _buildTheme(
      PdfPageFormat pageFormat, pw.Font base, pw.Font bold, pw.Font italic) {
    return pw.PageTheme(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(
        base: base,
        bold: bold,
        italic: italic,
      ),
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
      ),
    );
  }

  pw.Widget _contentFooter(pw.Context context, MyData myData) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                  "Billing App: Instant Invoice Maker by AR Solutions\nFree Download from App Store & Play Store",
                  style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 5),
              pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _blackTextColor),
                      // color: _thankingbd,
                      // border: Border.all(color: Color(0XFF0000)),
                      borderRadius: pw.BorderRadius.circular(3)),
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.only(
                      left: 12, right: 12, top: 6, bottom: 6),
                  child: pw.Text(
                    myData.shop.welcomeText,
                    style: pw.TextStyle(
                        color: welcomeTextColor,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12),
                  ),
                  margin: const pw.EdgeInsets.only(right: 16)),
              pw.Container(
                // padding: const pw.EdgeInsets.only(left: 24),
                // height: 70,
                margin: const pw.EdgeInsets.only(top: 12, bottom: 12),
                child: pw.RichText(
                    text: pw.TextSpan(
                        text: '${myData.shop.name}\n',
                        style: pw.TextStyle(
                          color: _darkColor,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                      const pw.TextSpan(
                        text: '\n',
                        style: pw.TextStyle(
                          fontSize: 5,
                        ),
                      ),
                      pw.TextSpan(
                        text: myData.shop.address,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
                    ])),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.DefaultTextStyle(
            style: const pw.TextStyle(
              fontSize: 8,
              color: _darkColor,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Sub Total:'),
                    pw.Text(_formatCurrency(_total)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:'),
                    pw.Text("" + myData.discountTotal.toString()),
                  ],
                ),
                myData.tax == 0
                    ? pw.Container(height: 0, width: 0)
                    : pw.SizedBox(height: 5),
                myData.tax == 0
                    ? pw.Container(height: 0, width: 0)
                    : pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Tax(+${(tax * 100).toStringAsFixed(0)}%):'),
                          pw.Text(
                              "${(_total * myData.tax).toStringAsFixed(0)}"),
                        ],
                      ),
                myData.vat == 0
                    ? pw.Container(height: 0, width: 0)
                    : pw.SizedBox(height: 5),
                myData.vat == 0
                    ? pw.Container(height: 0, width: 0)
                    : pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                              'Vat(+${(myData.vat * 100).toStringAsFixed(0)}%):'),
                          pw.Text(
                              "${(_total * myData.vat).toStringAsFixed(0)}"),
                        ],
                      ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Shipping(+):'),
                    pw.Text("" + myData.shippingCost),
                  ],
                ),
                pw.Divider(color: accentColor),
                pw.DefaultTextStyle(
                  style: const pw.TextStyle(
                    color: _blackColor,
                    fontSize: 8,
                    // fontWeight: pw.FontWeight.bold,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total:'),
                      pw.Text((_grandTotal).toString()),
                    ],
                  ),
                ),
                pw.DefaultTextStyle(
                  style: const pw.TextStyle(
                    color: _blackColor,
                    fontSize: 8,
                    // fontWeight: pw.FontWeight.bold,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Paid amount:'),
                      pw.Text((myData.paidAmount.toString())),
                    ],
                  ),
                ),
                pw.Divider(color: accentColor),
                pw.DefaultTextStyle(
                  style: const pw.TextStyle(
                    color: _blackColor,
                    fontSize: 8,
                    // fontWeight: pw.FontWeight.bold,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Due Amount:'),
                      pw.Text(_formatCurrency(due)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _termsAndConditions(pw.Context context, MyData myData) {
    return myData.shop.tAndC == ""
        ? pw.SizedBox(height: 2)
        : pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        'Terms & Conditions',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: _blackTextColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Text(
                      myData.shop.tAndC,
                      textAlign: pw.TextAlign.justify,
                      style: const pw.TextStyle(
                        fontSize: 5,
                        lineSpacing: 2,
                        color: _darkColor,
                      ),
                    ),
                  ]
          );
  }

  pw.Widget _contentTable(pw.Context context, MyData myData) {
    const tableHeaders = [
      '  SKU#  ',
      'Item Description',
      '  Price  ',
      '  Qty  ',
      '  Dis  ',
      '  Total  '
    ];

    return pw.Table.fromTextArray(
      border: null,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        color: baseColor,
      ),
      headerHeight: 20,
      cellHeight: 20,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
      headerStyle: pw.TextStyle(
        color: _baseTextColor,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        color: _darkColor,
        fontSize: 8,
      ),
      rowDecoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: accentColor,
            width: .5,
          ),
        ),
      ),
      headers: List<String>.generate(
        tableHeaders.length,
        (col) => tableHeaders[col],
      ),
      data: List<List<String>>.generate(
        products.length,
        (row) => List<String>.generate(
          tableHeaders.length,
          (col) => products[row].getIndex(col),
        ),
      ),
    );
  }
  List<Map<String, dynamic>>secA=[];

  getAddressInfo(customerId) async {
  String query =
  "select Area.AreaCd as ac,Parties.AreaCd, Sector.SecCd as sc,Area.AreaNm,Sector.SecNm, Parties._id as pId from Parties inner join Area ON Area.AreaCd=Parties.AreaCd inner join Sector ON Sector.SecCd=Area.SecCd where pId=$customerId";

  final Database database = await openDatabase('my_database.db');
  List<Map<String, dynamic>> info = await database.rawQuery(query);
  print(info);
  secA.clear();
  secA.addAll(info);
  }
  pw.Widget _contentMainHeader(
      pw.Context context, MyData myData, String? imageString, pw.Document doc,double width,double height,List<Map<String,dynamic>>info) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            myData.shop.shopKey == ""
                ? pw.Expanded(
                    flex: 0, child: pw.Container(height: 80, width: 0))
                : pw.Expanded(
                    flex: 8,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.centerLeft,
                          padding: const pw.EdgeInsets.only(bottom: 8, left: 8),
                          height: 80,
                          width: 80,
                          child: myData.shop.shopKey == ""
                              ? pw.Container()
                              : pw.Image(
                                  pw.MemoryImage(
                                    base64Decode(myData.shop.shopKey),
                                  ),
                                  alignment: pw.Alignment.center,
                                  fit: pw.BoxFit.contain,
                                  width: 50 * PdfPageFormat.mm,
                                  height: 12.5 * PdfPageFormat.mm),
                        ),
                      ],
                    ),
                  ),
            pw.Expanded(
              flex: 12,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
/*
                  pw.Center(
                    child: pw.Container(
                      // height: 50,
                      child: pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          color: _blackTextColor,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
*/
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _blackTextColor),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(2)),
                      color: _whiteColor,
                    ),
                    padding: const pw.EdgeInsets.only(
                        left: 5, top: 5, bottom: 5, right: 5),
                    alignment: pw.Alignment.center,
                    child: pw.Column(children: [
                      pw.Text('Invoice: ${invoiceNumber}'),
                      pw.Text('Date   : ${_formatDate(DateTime.now())}')
                    ]),
                  ),
                ],
              ),
            ),
/*
            pw.Expanded(
              flex: 10,
              child: pw.Container(
                  alignment: pw.Alignment.center,
                  // margin: const pw.EdgeInsets.only(left: 2.0 * PdfPageFormat.cm,top: 2.0 * PdfPageFormat.cm,right: 2.0 * PdfPageFormat.cm),
                  margin: const pw.EdgeInsets.all(0.0 * PdfPageFormat.cm),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    // mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.only(left: 12),
                        // height: 70,
                        child: pw.RichText(
                            text: pw.TextSpan(
                                text: 'Bill To-\n${myData.customerName}\n',
                                style: pw.TextStyle(
                                  color: _darkColor,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,
                                ),
                                children: [
                                  const pw.TextSpan(
                                    text: '\n',
                                    style: pw.TextStyle(
                                      fontSize: 5,
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: myData.customerAddress,
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.normal,
                                      fontSize: 10,
                                    ),
                                  ),
                                ])),
                      ),
                    ],
                  )),
            )
*/
          ],
        ),
        pw.Container(
            margin: const pw.EdgeInsets.only(right: 50),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        pw.Expanded(
                            flex: 1,
                          child:pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.start,
                              children: [
                                pw.Text("Bill to: ",
                                    style: pw.TextStyle(
                                        fontSize: 10,
                                        fontWeight: pw.FontWeight.bold)),
                                pw.Text(customerName,
                                    style: const pw.TextStyle(fontSize: 10)),
                              ]),
                        ),
/*
                        pw.Expanded(
                            flex: 1,
                            child: pw.Container(
                                padding: const pw.EdgeInsets.only(right: 24),
                                child: pw.Row(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.start,
                                    children: [
                                      pw.Text("Address: ",
                                          softWrap: false,
                                          style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold)),
                                      pw.Container(
                                        width: 6 * PdfPageFormat.cm,
                                        child: pw.Text(customerAddress,
                                            style: const pw.TextStyle(
                                                fontSize: 8)),
                                      )
                                    ]))),
*/
                      ]),

                  pw.Container(
                      padding: const pw.EdgeInsets.only(right: 24),
                      child: pw.Row(
                          crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                          mainAxisAlignment:
                          pw.MainAxisAlignment.start,
                          children: [
                            pw.Text("Sector: ${info[0]["SecNm"]} Area: ${info[0]["AreaNm"]}",
                                softWrap: false,
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Container(
                              width: (width-6) * PdfPageFormat.cm,
                              child: pw.Text("",
                                  style: const pw.TextStyle(
                                      fontSize: 8)),
                            )
                          ])),

                  pw.Row(children: [
                    pw.Expanded(
                        flex: 1,
                        child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("Phone : ",
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(myData.customer.phone,
                                  style: const pw.TextStyle(fontSize: 8)),
                            ])),
                    pw.Expanded(
                        flex: 1,
                        child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("Email     : ",
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(myData.customer.email,
                                  style: const pw.TextStyle(fontSize: 8)),
                            ])),
                  ]),
                ]))
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final format = DateFormat.yMMMd('en_US');
    return format.format(date);
  }
}

String _formatCurrency(double amount) {
  return '${amount.toStringAsFixed(0)}';
}

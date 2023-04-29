import 'package:Mini_Bill/Widgets/ConstantWidget.dart';
import 'package:Mini_Bill/Widgets/DocSize.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DynamicPageSize extends StatefulWidget {
  const DynamicPageSize({Key? key}) : super(key: key);

  @override
  State<DynamicPageSize> createState() => _DynamicPageSizeState();
}

class _DynamicPageSizeState extends State<DynamicPageSize> {
  // Initial Selected Value
  String dropdownvalue = 'You 4';

  // List of format in our dropdown menu
  var items = [
    'You 4',
    'A4',
    'Letter',
    'Ledger',
    'Legal',
  ];
  var widthList = [
    '104.8',
    '210',
    '216',
    '279.4',
    '216',
  ];
  var heightList = [
    '235',
    '297',
    '279',
    '431.8',
    '356',
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkDropDown();
  }

  final dropdownState = GlobalKey<FormFieldState>();

  Future<void> checkDropDown() async {
    for (int i = 0; i < items.length; i++) {
      var element = items[i];
      var width = widthList[i];
      var height = heightList[i];
      _dynamic.add(DocSize(element, width, height));
    }
    SharedPreferences sharedPref = await SharedPreferences.getInstance();
    setState(() {
      dropdownvalue = (sharedPref.getString(ConstantWidget.format) ?? "You 4");
      dropdownState.currentState!.didChange(dropdownvalue);
      int i =
          _dynamic.indexWhere((element) => element.getFormat == dropdownvalue);
      widthController.text =
          sharedPref.getDouble(ConstantWidget.width).toString().isEmpty
              ? _dynamic[i].getWidth
              : sharedPref.getDouble(ConstantWidget.width).toString();
      heightController.text =
          sharedPref.getDouble(ConstantWidget.height).toString().isEmpty
              ? _dynamic[i].getHeight
              : sharedPref.getDouble(ConstantWidget.height).toString();
    });
  }

  List<DocSize> _dynamic = [];

  var widthController = TextEditingController();
  var heightController = TextEditingController();
  var formatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Format Page")),
      floatingActionButton: FloatingActionButton(
          onPressed: () {}, child: const Icon(Icons.done_outlined)),
      body: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.vertical,
        children: [
          Form(
              child: Column(
            children: [
              const SizedBox(
                height: 12,
              ),
              DropdownButtonFormField(
                key: dropdownState,
                decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.keyboard_arrow_down),
                    label: Text("Format")),
                // Initial Value
                value: dropdownvalue,
                icon: const SizedBox(),
                // Array list of items
                items: items.map((String items) {
                  return DropdownMenuItem(
                    value: items,
                    child: Text(items),
                  );
                }).toList(),
                // After selecting the desired option,it will
                // change button value to selected value
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownvalue = newValue!;
                    if (_dynamic != null) {
                      int i = _dynamic.indexWhere(
                          (element) => element.getFormat == dropdownvalue);
                      widthController.text = _dynamic[i].getWidth;
                      heightController.text = _dynamic[i].getHeight;
                    }
                  });
                },
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: widthController,
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(8),
                          labelText: 'Width',
                          hintText: 'Width',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: heightController,
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(8),
                          labelText: 'Height',
                          hintText: 'Height',
                          border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              ElevatedButton(
                  onPressed: () async {
                    if (dropdownvalue.trim() != "Select format") {
                      SharedPreferences _pref =
                          await SharedPreferences.getInstance();
                      _pref.setString(ConstantWidget.format, dropdownvalue);
                      _pref.setDouble(ConstantWidget.width,
                          double.parse(widthController.text));
                      _pref.setDouble(ConstantWidget.height,
                          double.parse(heightController.text));
                      _pref.commit();
                      Navigator.of(context).pop(true);
                    } else {
                      Fluttertoast.showToast(
                          msg: "Please select a page format",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 5,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0);
                    }
                  },
                  child: const SizedBox(
                      width: double.infinity,
                      child: Text(
                        "Save",
                        textAlign: TextAlign.center,
                      ))),
            ],
          ))
        ],
      ),
    );
  }
}

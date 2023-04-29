import 'dart:io';
import 'dart:typed_data';


import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../Utils/Utility.dart';
import '../Utils/Utils.dart';
import '../Widgets/ConstantWidget.dart';
import 'Shop.dart';


class SelectShop extends StatefulWidget {
  const SelectShop({Key? key, required this.shop}) : super(key: key);

  final List<Shop> shop;

  @override
  _SelectShopState createState() => _SelectShopState();
}

class _SelectShopState extends State<SelectShop> {
  var termsAndConditionC = TextEditingController();
  var thankingQuoteC = TextEditingController();
  var brandNameC = TextEditingController();
  var paymentInfoC = TextEditingController();
  final shopKey = GlobalKey<FormState>();

  String? editingId;

  void saveShop(String boxName, Shop shop) async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ShopAdapter());
    }
    var box = await Hive.openBox<Shop>(boxName);
    box.put(shop.id, shop);
    setState(() {
      widget.shop.add(shop);
    });
    print(box.values);
  }

  void UpdateShop(String boxName, Shop shop) async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ShopAdapter());
    }
    var box = await Hive.openBox<Shop>(boxName);
    box.put(shop.id, shop);
    setState(() {
      widget.shop.add(shop);
    });
    print(box.values);
  }

  String selectedImageFile = "";

  pickImage(ImageSource source) async {
    if (!kIsWeb) {
      final ImagePicker _picker = ImagePicker();

      XFile? _image = (await _picker.pickImage(source: source));

      File file = File(_image!.path);
      File? croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
        ],
        androidUiSettings: const AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blueAccent,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        /*iosUiSettings: const IOSUiSettings(
            minimumAspectRatio: 1.0,
          )*/
      );

      if (croppedFile != null) {
        setState(() {
          image = Image.file(
            croppedFile,
            height: 50,
            width: 200,
            fit: BoxFit.cover,
          );
          mainImageVisibility = true;
          selectedImageFile =
              ImageSharedPrefs.base64String(croppedFile.readAsBytesSync());
        });
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
          setState(() {
            mainImageVisibility = true;
            selectedImageFile = ImageSharedPrefs.base64String(fileBytes);
            image = ImageSharedPrefs.imageFrom64BaseString(
                ImageSharedPrefs.base64String(fileBytes));
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

  var IMAGE_KEY = "";
  bool mainImageVisibility = false;
  Image image = Image.asset(
    "name",
    height: 50,
    width: 200,
  );

  @override
  void initState() {
    super.initState();
    _shops();

    setState(() {
      widget.shop.sort((a, b) => a.name.compareTo(b.name));
    });
  }



  bool editing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Select Shop"),
        ),
        resizeToAvoidBottomInset: false,
        body: WillPopScope(
          onWillPop: () async {
            ImageSharedPrefs.emptyPrefs(IMAGE_KEY);
            return true;
          },
          child: Stack(
            children: [
              ListView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                children: [
                  Visibility(
                    visible: listVisibility,
                    child: widget.shop.isNotEmpty
                        ? Column(
                            children: [
                              ListView.separated(
                                physics: ClampingScrollPhysics(),
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  return InkWell(
                                    onTap: () {
                                      Navigator.of(context)
                                          .pop(widget.shop[index]);
                                    },
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    height: 50,
                                                    child: widget.shop[index]
                                                                .shopKey ==
                                                            ""
                                                        ? Container(
                                                            color: Colors.black,
                                                          )
                                                        : ImageSharedPrefs
                                                            .imageFrom64BaseString(
                                                            widget.shop[index]
                                                                .shopKey,
                                                          ),
                                                  ),
                                                  SizedBox(
                                                    width: 5,
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(widget
                                                            .shop[index].name),
                                                        Text("Address: " +
                                                            widget.shop[index]
                                                                .address),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    child: IconButton(
                                                        onPressed: () async {
                                                          setState(() {
                                                            editing = true;
                                                            editingId = widget
                                                                .shop[index].id;
                                                            listVisibility =
                                                                false;
                                                            if (widget
                                                                .shop[index]
                                                                .shopKey
                                                                .isNotEmpty) {
                                                              image = ImageSharedPrefs
                                                                  .imageFrom64BaseString(widget
                                                                      .shop[
                                                                          index]
                                                                      .shopKey);
                                                              selectedImageFile =
                                                                  widget
                                                                      .shop[
                                                                          index]
                                                                      .shopKey;
                                                              mainImageVisibility =
                                                                  true;
                                                            }
                                                          });
                                                          brandNameC.text =
                                                              widget.shop[index]
                                                                  .name;
                                                          paymentInfoC.text =
                                                              widget.shop[index]
                                                                  .address;
                                                          termsAndConditionC
                                                                  .text =
                                                              widget.shop[index]
                                                                  .tAndC;
                                                          thankingQuoteC.text =
                                                              widget.shop[index]
                                                                  .welcomeText;
                                                        },
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors.white,
                                                        )),
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  CircleAvatar(
                                                    backgroundColor: Colors.red,
                                                    child: IconButton(
                                                        onPressed: () async {
                                                          AlertDialog alert =
                                                              AlertDialog(
                                                            title: const Text(
                                                                'Are you sure?'),
                                                            content: const Text(
                                                                'By clicking this button, this shop will be deleted'),
                                                            actions: <Widget>[
                                                              TextButton(
                                                                child:
                                                                    const Text(
                                                                        'Yes'),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                  deleteShop(
                                                                      index);
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
                                                        )),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                itemCount: widget.shop.isEmpty
                                    ? 0
                                    : widget.shop.length,
                                separatorBuilder:
                                    (BuildContext context, int index) {
                                  return const Divider(
                                    height: 0,
                                  );
                                },
                              ),
                              SizedBox(
                                height: 150,
                              )
                            ],
                          )
                        : ConstantWidget.NotFoundWidget(
                            context, "Shop not created yet"),
                  ),
                  Visibility(
                    visible: !listVisibility,
                    child: Container(
                      margin: EdgeInsets.all(12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Form(
                            key: shopKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12.0),
                                  child: Text("Shop Info",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Column(
                                    children: [
                                      Visibility(
                                        visible: !mainImageVisibility,
                                        child: IconButton(
                                            onPressed: () {
                                              showModalBottomSheet<void>(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return SafeArea(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          ListTile(
                                                            leading: const Icon(
                                                                Icons.camera),
                                                            title: const Text(
                                                                'Camera'),
                                                            onTap: () {
                                                              pickImage(
                                                                  ImageSource
                                                                      .camera);
                                                              // this is how you dismiss the modal bottom sheet after making a choice
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                          ListTile(
                                                            leading: const Icon(
                                                                Icons.image),
                                                            title: const Text(
                                                                'Gallery'),
                                                            onTap: () {
                                                              pickImage(
                                                                  ImageSource
                                                                      .gallery);
                                                              // dismiss the modal sheet
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  });
                                            },
                                            icon:
                                                const Icon(Icons.add_a_photo)),
                                      ),
                                      Visibility(
                                        visible: mainImageVisibility,
                                        child: InkWell(
                                            onTap: () {
                                              showModalBottomSheet<void>(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return SafeArea(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          ListTile(
                                                            leading: const Icon(
                                                                Icons.camera),
                                                            title: const Text(
                                                                'Camera'),
                                                            onTap: () {
                                                              pickImage(
                                                                  ImageSource
                                                                      .camera);
                                                              // this is how you dismiss the modal bottom sheet after making a choice
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                          ListTile(
                                                            leading: const Icon(
                                                                Icons.image),
                                                            title: const Text(
                                                                'Gallery'),
                                                            onTap: () {
                                                              pickImage(
                                                                  ImageSource
                                                                      .gallery);
                                                              // dismiss the modal sheet
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  });
                                            },
                                            child: Stack(
                                              children: [
                                                SizedBox(
                                                    width: 200,
                                                    height: 50,
                                                    child: image),
                                                const Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: Icon(
                                                        Icons.create_outlined))
                                              ],
                                            )),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    controller: brandNameC,
                                    autofocus: false,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a shop name';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.all(8),
                                        labelText: 'Shop name',
                                        hintText: 'Enter shop name',
                                        border: OutlineInputBorder()),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    controller: paymentInfoC,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter address';
                                      }
                                      return null;
                                    },
                                    minLines: 2,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.all(8),
                                        labelText: 'Address',
                                        hintText: 'Enter Address',
                                        border: OutlineInputBorder()),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    controller: termsAndConditionC,
                                    minLines: 2,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.all(8),
                                        labelText: 'Terms and condition',
                                        hintText: 'Enter terms & conditions',
                                        border: OutlineInputBorder()),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    controller: thankingQuoteC,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a welcome again message';
                                      }
                                      return null;
                                    },
                                    minLines: 2,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.all(8),
                                        labelText: 'Welcome again',
                                        hintText:
                                            'Enter a welcome again  message',
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
                                            listVisibility = true;
                                            image = Image.asset(
                                              "name",
                                              height: 50,
                                              width: 200,
                                              fit: BoxFit.cover,
                                            );
                                            mainImageVisibility = false;
                                          });
                                          brandNameC.text = "";
                                          paymentInfoC.text = "";
                                          termsAndConditionC.text = "";
                                          thankingQuoteC.text = "";
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
                                                if (shopKey.currentState!
                                                    .validate()) {
                                                  setState(() {
                                                    listVisibility = true;
                                                  });

                                                  UpdateShop(
                                                      "Shop",
                                                      Shop(
                                                          brandNameC.text,
                                                          paymentInfoC.text,
                                                          termsAndConditionC
                                                              .text,
                                                          thankingQuoteC.text,
                                                          selectedImageFile,
                                                          Utils
                                                              .getTimestamp()));
                                                  brandNameC.text = "";
                                                  paymentInfoC.text = "";
                                                  termsAndConditionC.text = "";
                                                  thankingQuoteC.text = "";
                                                }
                                              },
                                              child: const Text("Add"))
                                          : ElevatedButton(
                                              onPressed: () async {
                                                if (shopKey.currentState!
                                                    .validate()) {
                                                  setState(() {
                                                    listVisibility = true;
                                                    editing = false;
                                                    image = Image.asset(
                                                      "name",
                                                      height: 50,
                                                      width: 200,
                                                      fit: BoxFit.cover,
                                                    );
                                                    mainImageVisibility = false;
                                                  });

                                                  saveShop(
                                                      "Shop",
                                                      Shop(
                                                          brandNameC.text,
                                                          paymentInfoC.text,
                                                          termsAndConditionC
                                                              .text,
                                                          thankingQuoteC.text,
                                                          selectedImageFile,
                                                          editingId!));
                                                  brandNameC.text = "";
                                                  paymentInfoC.text = "";
                                                  termsAndConditionC.text = "";
                                                  thankingQuoteC.text = "";
                                                  _shops();
                                                }
                                              },
                                              child: const Text("Update")),
                                      flex: 10,
                                    ),
                                  ],
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom))
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: Visibility(
          visible: listVisibility,
          child: Container(
            margin: EdgeInsets.only(bottom: 0),
            child: FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  listVisibility = false;
                });
              },
              label: const Text("Add Shop"),
              icon: const Icon(Icons.add),
            ),
          ),
        ));
  }

  bool listVisibility = true;

  Future<void> deleteShop(int index) async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ShopAdapter());
    }
    var box = await Hive.openBox<Shop>("Shop");
    box.delete(widget.shop[index].id);
    setState(() {
      widget.shop.removeWhere((element) => element.id == widget.shop[index].id);
    });
    print(box.values);
  }

  Future<void> _shops() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ShopAdapter());
    }

    var box = await Hive.openBox<Shop>("Shop");
    setState(() {
      shopList.clear();
      widget.shop.clear();
      for (var element in box.values) {
        widget.shop.add(element);
      }
    });
    print(shopList);
  }

  List<Shop> shopList = [];
}

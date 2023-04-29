import 'package:Mini_Bill/Customer/SelectCustomer.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'Area.dart';
import 'Sector.dart';

class SelectSectorAndArea extends StatefulWidget {
  const SelectSectorAndArea({Key? key}) : super(key: key);

  @override
  State<SelectSectorAndArea> createState() => _SelectSectorAndAreaState();
}

class _SelectSectorAndAreaState extends State<SelectSectorAndArea> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchSector();
  }

  List<Sector> fetchd = [];
  Sector selected=Sector(-1, -1, "Select Sector");
  Area selectedArea=Area(-1, -1, "Select Area",-1);
  fetchSector() async {

    fetchd.add(selected);
    final Database database = await openDatabase('my_database.db');

    List<Map<String, dynamic>> parties =
        await database.rawQuery("SELECT * FROM Sector where SecCd!=0");

    print("SELECT * FROM Sector where SecCd!=0");

    for (var sector in parties) {
      fetchd.add(
          Sector(sector['_id'], sector['SecCd'], "${sector['SecNm']}"));
    }

    setState(() {

    });

  }
  List<Area>areas=[Area(-1,-1,"Select Area",-1)];
  fetchArea() async {
    areas.clear();
    areas.add(Area(-1,-1,"Select Area",-1));
    final Database database = await openDatabase('my_database.db');

    List<Map<String, dynamic>> areaQuery =
        await database.rawQuery("SELECT * FROM Area where SecCd=${selected.scCode}");

    print("SELECT * FROM Area where SecCd=${selected.scCode}");

    for (var area in areaQuery) {
      areas.add(
          Area(area['_id'], area['AreaCd'], "${area['AreaNm']}",area['SecCd']));
    }
    setState(() {

    });
  }

  String selectedSectorItem="Select Sector";
bool sectorSelected=false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Sector and Area"),
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Text("Select Sector:"),
          SizedBox(height: 8,),
          DropdownButton<Sector>(
            value: selected,
            onChanged: (Sector? newValue) async{
              selected = newValue!;
              fetchArea();
              setState(() {

                if(selected!=fetchd[0]){
                  sectorSelected=true;
                }else{
                  sectorSelected=false;
                }
              });
            },
            items: fetchd.map<DropdownMenuItem<Sector>>((Sector value) {
              return DropdownMenuItem<Sector>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(value.scName),
                ),
              );
            }).toList(),
          ),

          Visibility(
            visible: sectorSelected,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Select Area"),
                SizedBox(height: 8,),
                Container(
                  width: double.infinity,
                  child: DropdownButton<Area>(
                    value: areas[0],
                    onChanged: (Area? newValue) {
                      setState(() {
                        selectedArea = newValue!;
                        if(selectedArea!=areas[0]){
                          Navigator.push(context, MaterialPageRoute(builder: (context) =>  SelectCustomer(sectorId: selected,areaId: selectedArea,)));
                        }
                      });
                    },
                    items: areas.map<DropdownMenuItem<Area>>((Area value) {
                      return DropdownMenuItem<Area>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(value.AreaNm),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

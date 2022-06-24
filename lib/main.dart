import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';

const String mapboxAccessKey = "pk.eyJ1IjoiaW1qam1vYSIsImEiOiJja3J1OTV3ejkzcGYxMnBrZHQwdHlvbjZwIn0.pTqvTUJZAenAgxUDY_pQEA";

class FeatureModel {
  String? id;
  LatLng? latLng;
  FeatureModel(this.id, this.latLng);

  FeatureModel.fromMap(dynamic map) {
    id = map["properties"]["id"];
    latLng = LatLng(map["geometry"]["coordinates"][1], map["geometry"]["coordinates"][0]);
  }
}

List<FeatureModel> featureModels = [];

Future<String> getFileData(String path) async {
  return await rootBundle.loadString(path);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  getFileData("assets/toilet.geojson").then((value) {
    var models = json.decode(value);
    models["features"].forEach((e) {
      featureModels.add(FeatureModel.fromMap(e));
    });
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WHERE IS TOILET',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'WHERE IS TOILET'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Position? position;
  Completer<MapboxMapController> mapController = Completer();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentLocation();
  }

  void _onFeatureTapped(dynamic id, Point<double> point, LatLng coordinates) async {
    print("PATTT ${id}");
  }

  void _onSymbolTapped(Symbol symbol) {
    print("MATTT ${symbol.data}");
    /*if (_selectedSymbol != null) {
      _updateSelectedSymbol(
        const SymbolOptions(iconSize: 1.0),
      );
    }
    setState(() {
      _selectedSymbol = symbol;
    });
    _updateSelectedSymbol(
      SymbolOptions(
        iconSize: 1.4,
      ),
    );*/
  }

  getCurrentLocation() async {
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    var controller = await mapController.future;
    if(position != null) {
      controller.addCircle(CircleOptions(
        circleColor: '#ffbf00',
        circleRadius: 10,
        geometry: LatLng(position!.latitude, position!.longitude)
      ));
    }
  }

  findNearest() async {
    if(position == null)
      return ;
    if(featureModels.isEmpty)
      return ;

    double minDis = 9999999999;
    FeatureModel? minFeature;
    for (var value in featureModels) {
      double distance = Geolocator.distanceBetween(position!.latitude, position!.longitude, value.latLng!.latitude, value.latLng!.longitude);
      if(minDis > distance) {
        minDis = distance;
        minFeature = value;
      }
    }

    var controller = await mapController.future;
    if(minFeature != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(minFeature.latLng!, 15));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: MapboxMap(
        compassEnabled: false,
        accessToken: mapboxAccessKey,
        onMapCreated: (controller) async {
          await Future.delayed(Duration(milliseconds: 500));
          mapController.complete(controller);

          await controller.addSource(
              "toilet",
              GeojsonSourceProperties(
                  data: 'assets/toilet.geojson',
                  cluster: true,
                  clusterMaxZoom: 14, // Max zoom to cluster points on
                  clusterRadius: 50 // Radius of each cluster when clustering points (defaults to 50)
              ));
          await controller.addLayer(
              "toilet",
              "toilet-symbol",
              SymbolLayerProperties(
                iconImage: 'stadium-15',
                iconSize: 2,
                textField : "{point_count_abbreviated}",
                textFont : ["DIN Offc Pro Medium", "Arial Unicode MS Bold"],
                textSize : 15,
                textAnchor : "top",
                textColor: '#1900ff',
                textLineHeight : 3
              ),
              filter: ["has", "point_count"],
            );
          await controller.addLayer(
            "toilet",
            "toilet-symbol-uncluster",
            SymbolLayerProperties(
              iconImage: 'stadium-15',
              iconSize: 1.5,
            ),
            filter: ["!has", "point_count"],
          );
          controller.onSymbolTapped.add(_onSymbolTapped);
          controller.onFeatureTapped.add(_onFeatureTapped);
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(37.123, 127.123),
          zoom: 8
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 50),
        child: FloatingActionButton(
          onPressed: () {
            findNearest();
          },
          tooltip: 'SEARCH NEAREST',
          child: const Icon(Icons.search),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

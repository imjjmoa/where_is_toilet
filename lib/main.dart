import 'dart:async';
import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
// import 'package:mapbox_gl/mapbox_gl.dart';
// import 'package:where_is_toilet/mapbox_page.dart';

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
 /* getFileData("toilet.geojson").then((value) {
    var models = json.decode(value);
    models["features"].forEach((e) {
      featureModels.add(FeatureModel.fromMap(e));
    });
  });*/
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
      home: FlutterMapPage(),
    );
  }
}

class FlutterMapPage extends StatefulWidget {
  @override
  State<FlutterMapPage> createState() => _FlutterMapPageState();
}

class _FlutterMapPageState extends State<FlutterMapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(51.5, -0.09),
          zoom: 13.0,
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayerOptions(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(51.5, -0.09),
                builder: (ctx) =>
                    Container(
                      child: FlutterLogo(),
                    ),
              ),
            ],
          ),
        ],
        nonRotatedChildren: [
          AttributionWidget.defaultWidget(
            source: 'OpenStreetMap contributors',
            onSourceTapped: () {},
          ),
        ],
      ),
    );
  }
}

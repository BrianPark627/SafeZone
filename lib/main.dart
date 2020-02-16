import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocation/geolocation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'test',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  LatLng SOURCE_LOCATION;
  LatLng DEST_LOCATION;
  Set<Marker> markers = {};
  GoogleMapController _controller;
  Map hazardModels;
  Map safeModels;
  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();

    hazardModels = {
      "1": {
        "markerId": "1",
        "description": "Broken Tree",
        "lat": "43.037770",
        "lng": "-76.137500"
      },
      "2": {
        "markerId": "2",
        "description": "Broken powerline",
        "lat": "43.03760709",
        "lng": "-76.13370091"
      },
      "3": {
        "markerId": "3",
        "description": "flooding",
        "lat": "43.03673273",
        "lng": "-76.13139421"
      },
    };

    hazardModels.forEach((k, v) => {
          markers.add(Marker(
              markerId: MarkerId(v["markerId"]),
              draggable: true,
              infoWindow: InfoWindow(title: v["description"]),
              position: LatLng(double.parse(v["lat"]), double.parse(v["lng"]))))
        });

    safeModels = {
      "1": {
        "markerId": "1",
        "description": "1",
        "lat": "43.044190",
        "lng": "-76.135660"
      },
      "2": {
        "markerId": "2",
        "description": "2",
        "lat": "43.037319",
        "lng": "-76.138847"
      },
    };

    safeModels.forEach((k, v) => {
          markers.add(Marker(
              markerId: MarkerId(v["markerId"]),
              draggable: true,
              infoWindow: InfoWindow(title: v["description"]),
              position: LatLng(double.parse(v["lat"]), double.parse(v["lng"])),
              icon: BitmapDescriptor.defaultMarkerWithHue(110)))
        });
  }

  CameraPosition current = CameraPosition(target: LatLng(0, 0));

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(title: const Text('SafeZone')),
      body: Stack(children: [
        Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: GoogleMap(
              myLocationEnabled: true,
              mapType: MapType.normal,
              initialCameraPosition: current,
              markers: Set.from(markers),
              polylines: _polylines,
              onMapCreated: onMapCreated,
            )),
      ]),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.local_hospital),
        onPressed: () async {
          _polylines.clear();
          polylineCoordinates = [];
          LocationResult result = await Geolocation.lastKnownLocation();
          LatLng latlng =
              LatLng(result.location.latitude, result.location.longitude);
          setState(() {
            SOURCE_LOCATION = latlng;
            DEST_LOCATION = LatLng(43.037319, -76.138847);
          });
          // setMapPins();
          setPolylines();
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(icon: Icon(Icons.menu), onPressed: () async {}),
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  _asyncInputDialog(context);
                })
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
  }

  Future<void> _goToCurrent() async {
    LocationResult result = await Geolocation.lastKnownLocation();
    CameraPosition newcurrent = CameraPosition(
        target: LatLng(result.location.latitude, result.location.longitude),
        zoom: 17.5);
    // final GoogleMapController controller = await _controller.future;
    _controller.animateCamera(CameraUpdate.newCameraPosition(newcurrent));
  }

  void setMapPins() {
    setState(() {
      // source pin
      markers.add(Marker(
        markerId: MarkerId('sourcepin'),
        position: SOURCE_LOCATION,
        //  icon: sourceIcon
      ));
      // destination pin
      markers.add(Marker(
        markerId: MarkerId('destpin'),
        position: DEST_LOCATION,
        //  icon: destinationIcon
      ));
    });
  }

  setPolylines() async {
    print(SOURCE_LOCATION.latitude);
    print(DEST_LOCATION.longitude);
    List<PointLatLng> result = await polylinePoints?.getRouteBetweenCoordinates(
        "",
        SOURCE_LOCATION.latitude,
        SOURCE_LOCATION.longitude,
        DEST_LOCATION.latitude,
        DEST_LOCATION.longitude);
    if (result.isNotEmpty) {
      result.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    setState(() {
      Polyline polyline = Polyline(
          polylineId: PolylineId("poly"),
          color: Color.fromARGB(255, 40, 122, 198),
          points: polylineCoordinates);
      _polylines.add(polyline);
    });
  }

  Future<String> _asyncInputDialog(BuildContext context) async {
    String hazard = '';
    return showDialog<String>(
      context: context,
      barrierDismissible:
          false, // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Hazard'),
          content: new Row(
            children: <Widget>[
              new Expanded(
                  child: new TextField(
                autofocus: true,
                decoration: new InputDecoration(
                    labelText: 'Hazard', hintText: 'eg. Collapsed Powerlines'),
                onChanged: (value) {
                  hazard = value;
                },
              ))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop("CANCEL");
              },
            ),
            FlatButton(
              child: Text('Confirm'),
              onPressed: () async {
                LocationResult result = await Geolocation.lastKnownLocation();
                markers.add(Marker(
                    markerId: MarkerId("hazard"),
                    draggable: true,
                    infoWindow: InfoWindow(title: hazard),
                    position: LatLng(
                        result.location.latitude, result.location.longitude)));
                Navigator.of(context).pop(hazard);
              },
            )
          ],
        );
      },
    );
  }
  // Future<LatLng> _getCurrent() async {
  //   LocationResult result = await Geolocation.lastKnownLocation();
  //   return LatLng(result.location.latitude, result.location.longitude);
  // }
}

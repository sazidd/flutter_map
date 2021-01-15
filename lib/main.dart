import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/location.dart';

import 'package:flutter_map/web_socket.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:web_socket_channel/io.dart';

const double CAMERA_ZOOM = 18;
const double CAMERA_TILT = 0;
const double CAMERA_BEARING = 30;
const LatLng SOURCE_LOCATION = LatLng(42.747932, -71.167889);
const LatLng DEST_LOCATION = LatLng(37.335685, -122.0605916);
const String _apiKey = "AIzaSyCqbqRJV54QBO3KoHyZGrRI25adiisl9vg";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final WebSocketChannel channel =
      IOWebSocketChannel.connect('ws://echo.websocket.org');

  @override
  _HomePageState createState() => _HomePageState(channel: channel);
}

class _HomePageState extends State<HomePage> {
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set<Marker>();
  // for my drawn routes on the map
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints;
  String googleAPIKey = _apiKey;
  // for my custom marker pins
  BitmapDescriptor sourceIcon;
  BitmapDescriptor destinationIcon;
  // the user's initial location and current location
  // as it moves
  LocationData currentLocation;
  // a reference to the destination location
  LocationData destinationLocation;
  // wrapper around the location API
  Location location;

  @override
  void initState() {
    super.initState();

    // create an instance of Location
    location = Location();
    polylinePoints = PolylinePoints();

    // subscribe to changes in the user's location
    // by "listening" to the location's onLocationChanged event
    location.onLocationChanged.listen((LocationData cLoc) {
      // cLoc contains the lat and long of the
      // current user's position in real time,
      // so we're holding on to it
      currentLocation = cLoc;
      updatePinOnMap();
    });
    // set custom marker pins
    setSourceAndDestinationIcons();
    // set the initial location
    setInitialLocation();

    // locationList.forEach((element) {
    //   // element.lat;
    //   // element.lon;
    //   channel.sink.add("${element.lat}, ${element.lon}");
    //   sleep(Duration(seconds: 2));
    // });
  }

  @override
  void didChangeDependencies() {
    sendLocation();
    super.didChangeDependencies();
  }

  final WebSocketChannel channel;
  final inputController = TextEditingController();
  List<String> messageList = [];
  String lat;
  String lon;

  _HomePageState({this.channel}) {
    channel.stream.listen((data) {
      setState(() {
        final split = data.split(',');
        final Map<int, String> values = {
          for (int i = 0; i < split.length; i++) i: split[i]
        };
        lat = values[0];
        lon = values[1];
        print('response server data---------- $lat, $lon');
        messageList.add(data);
      });
    });
  }

  @override
  void dispose() {
    inputController.dispose();
    widget.channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialCameraPosition = CameraPosition(
      zoom: CAMERA_ZOOM,
      tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
      target: SOURCE_LOCATION,
    );

    if (currentLocation != null) {
      initialCameraPosition = CameraPosition(
        target: LatLng(currentLocation.latitude, currentLocation.longitude),
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Google Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WebSocketPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            height: 200,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: inputController,
                    decoration: InputDecoration(
                      labelText: 'Send Message',
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(fontSize: 22),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                    child: Text(
                      'Send',
                      style: TextStyle(fontSize: 20),
                    ),
                    onPressed: () {
                      if (inputController.text.isNotEmpty) {
                        print(inputController.text);
                        channel.sink.add(inputController.text);
                      }
                      inputController.text = '';
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 400,
            child: GoogleMap(
                myLocationEnabled: true,
                compassEnabled: true,
                tiltGesturesEnabled: false,
                markers: _markers,
                polylines: _polylines,
                mapType: MapType.normal,
                initialCameraPosition: initialCameraPosition,
                onMapCreated: (controller) {
                  _controller.complete(controller);
                  showPinsOnMap();
                }),
          ),
        ],
      ),
    );
  }

  void setSourceAndDestinationIcons() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/driving_pin.png',
    );

    destinationIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/marker.png',
    );
  }

  void setInitialLocation() async {
    // set the initial location by pulling the user's
    // current location from the location's getLocation()
    currentLocation = await location.getLocation();

    // hard-coded destination for this example
    destinationLocation = LocationData.fromMap({
      "latitude": double.parse(lat),
      "longitude": double.parse(lon),
      // "latitude": DEST_LOCATION.latitude,
      // "longitude": DEST_LOCATION.longitude
    });
  }

  void showPinsOnMap() {
    // get a LatLng for the source location
    // from the LocationData currentLocation object
    var pinPosition = LatLng(
      currentLocation.latitude,
      currentLocation.longitude,
    );
    // get a LatLng out of the LocationData object
    var destPosition = LatLng(
      destinationLocation.latitude,
      destinationLocation.longitude,
    );
    // add the initial source location pin
    _markers.add(Marker(
      markerId: MarkerId('sourcePin'),
      position: pinPosition,
      icon: sourceIcon,
    ));
    // destination pin
    _markers.add(Marker(
      markerId: MarkerId('destPin'),
      position: destPosition,
      icon: destinationIcon,
    ));
    // set the route lines on the map from source to destination
    // for more info follow this tutorial
//    setPolylines();
  }

//  void setPolylines() async {
//    List<PointLatLng> result = await polylinePoints.getRouteBetweenCoordinates(
//      _apiKey,
//      currentLocation.latitude,
//      currentLocation.longitude,
//      destinationLocation.latitude,
//      destinationLocation.longitude,
//    );
//
//    if (result.isNotEmpty) {
//      result.forEach((PointLatLng point) {
//        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
//      });
//
//      setState(() {
//        _polylines.add(Polyline(
//            width: 2, // set the width of the polylines
//            polylineId: PolylineId("poly"),
//            color: Color.fromARGB(255, 40, 122, 198),
//            points: polylineCoordinates));
//      });
//    }
//  }

  void updatePinOnMap() async {
    // create a new CameraPosition instance
    // every time the location changes, so the camera
    // follows the pin as it moves with an animation
    CameraPosition cPosition = CameraPosition(
      zoom: CAMERA_ZOOM,
      tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
      target: LatLng(
        double.parse(lat),
        double.parse(lon),
      ),
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
    // do this inside the setState() so Flutter gets notified
    // that a widget update is due
    setState(() {
      // updated position
      var pinPosition = LatLng(
        // currentLocation.latitude,
        // currentLocation.longitude,
        double.parse(lat), double.parse(lon),
      );

      // the trick is to remove the marker (by id)
      // and add it again at the updated location
      _markers.removeWhere((m) => m.markerId.value == "sourcePin");
      _markers.add(
        Marker(
          markerId: MarkerId("sourcePin"),
          position: pinPosition, // updated position
          icon: sourceIcon,
        ),
      );
    });
  }

  void sendLocation() async {
    // await Future.delayed(Duration(milliseconds: 700));
    for (var i = 0; i < locationList.length; i++) {
      channel.sink.add("${locationList[i].lat}, ${locationList[i].lon}");
      await Future.delayed(Duration(milliseconds: 900));
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// import 'location.dart';

// class WebSocketPage extends StatefulWidget {
//   final WebSocketChannel channel =
//       IOWebSocketChannel.connect('ws://echo.websocket.org');

//   @override
//   _WebSocketPageState createState() => _WebSocketPageState(channel: channel);
// }

// class _WebSocketPageState extends State<WebSocketPage> {
//   final WebSocketChannel channel;
//   final inputController = TextEditingController();
//   List<String> messageList = [];

//   _WebSocketPageState({this.channel}) {
//     channel.stream.listen((data) {
//       setState(() {
//         print('response server data---------- $data');
//         messageList.add(data);
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Web Socket'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Padding(
//             padding: EdgeInsets.all(10.0),
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   child: TextField(
//                     controller: inputController,
//                     decoration: InputDecoration(
//                       labelText: 'Send Message',
//                       border: OutlineInputBorder(),
//                     ),
//                     style: TextStyle(fontSize: 22),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: RaisedButton(
//                     child: Text(
//                       'Send',
//                       style: TextStyle(fontSize: 20),
//                     ),
//                     onPressed: () {
//                       if (inputController.text.isNotEmpty) {
//                         print(inputController.text);
//                         channel.sink.add(inputController.text);
//                       }
//                       inputController.text = '';

//                       // fetchLocation().then((value) => print(
//                       //     "Latitude: ${LocationModel(lat: value[0].lat, lon: value[0].lon)}"));

//                       // final locationData = fetchLocation().then((value) =>
//                       //     LocationModel(lat: value[0].lat, lon: value[0].lon));

//                       // Navigator.of(context).pushReplacement(MaterialPageRoute(
//                       //     builder: (context) => HomePage(
//                       //           locationModel: LocationModel(
//                       //             lat: "23.73009",
//                       //             lon: "90.41075",
//                       //           ),
//                       //         )));
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: getMessageList(),
//           ),
// //          Expanded(
// //            child: StreamBuilder(
// //              stream: channel.stream,
// //              builder: (context, snapshot) {
// //                if (snapshot.hasData) {
// //                  messageList.add(snapshot.data);
// //                }
// //
// //                return getMessageList();
// //              },
// //            ),
// //          ),
//         ],
//       ),
//     );
//   }

//   ListView getMessageList() {
//     List<Widget> listWidget = [];

//     for (String message in messageList) {
//       listWidget.add(ListTile(
//         title: Container(
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               message,
//               style: TextStyle(fontSize: 22),
//             ),
//           ),
//           color: Colors.teal[50],
//           height: 60,
//         ),
//       ));
//     }

//     return ListView(children: listWidget);
//   }

//   @override
//   void dispose() {
//     inputController.dispose();
//     widget.channel.sink.close();
//     super.dispose();
//   }

//   Future<List<LocationModel>> fetchLocation() async {
//     final data = await rootBundle.loadString('assets/locations.json');
//     return locationModelFromMap(data);
//   }
// }

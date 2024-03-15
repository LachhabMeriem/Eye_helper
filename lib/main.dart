// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'home.dart';
//
// List<CameraDescription> cameras = <CameraDescription>[];
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   try {
//     cameras = await availableCameras();
//     print(cameras);
//   } on CameraException catch (e) {
//     print(e.toString());
//   }
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('Eye Helper'),
//           centerTitle: true,
//           backgroundColor: Colors.lightGreen.withOpacity(0.8),
//         ),
//         body: MyHomePage(),
//         floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//       ),
//     );
//   }
// }
//
// class MyHomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           SizedBox(height: 20),
//           Text('Press the camera button below to launch the camera'),
//           SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => HomePage(cameras)),
//               );
//             },
//             child: Icon(
//               Icons.camera,
//               size: 60.0,
//               color: Colors.white,
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.lightGreen.withOpacity(0.8),
//               elevation: 6,
//               shape: CircleBorder(),
//               padding: EdgeInsets.all(20),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'object_detection.dart';
// import 'dart:io' show Platform;
//
// void main() => runApp(const MyApp());
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.orange,
//         ),
//       ),
//       home: const MyHome(),
//     );
//   }
// }
//
// class MyHome extends StatefulWidget {
//   const MyHome({super.key});
//
//   @override
//   State<MyHome> createState() => _MyHomeState();
// }
//
// class _MyHomeState extends State<MyHome> {
//   final imagePicker = ImagePicker();
//
//   ObjectDetection? objectDetection;
//
//   Uint8List? image;
//
//   @override
//   void initState() {
//     super.initState();
//     objectDetection = ObjectDetection();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Image.asset('assets/download.jpg'),
//         backgroundColor: Colors.black.withOpacity(0.5),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: <Widget>[
//             Expanded(
//               child: Center(
//                 child: (image != null) ? Image.memory(image!) : Container(),
//               ),
//             ),
//             SizedBox(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   if (Platform.isAndroid || Platform.isIOS)
//                     IconButton(
//                       onPressed: () async {
//                         final result = await imagePicker.pickImage(
//                           source: ImageSource.camera,
//                         );
//                         if (result != null) {
//                           image = objectDetection!.analyseImage(result.path);
//                           setState(() {});
//                         }
//                       },
//                       icon: const Icon(
//                         Icons.camera,
//                         size: 64,
//                       ),
//                     ),
//                   IconButton(
//                     onPressed: () async {
//                       final result = await imagePicker.pickImage(
//                         source: ImageSource.gallery,
//                       );
//                       if (result != null) {
//                         image = objectDetection!.analyseImage(result.path);
//                         setState(() {});
//                       }
//                     },
//                     icon: const Icon(
//                       Icons.photo,
//                       size: 64,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'home.dart';

List<CameraDescription> cameras = <CameraDescription>[];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
    print(cameras);
  } on CameraException catch (e) {
    print(e.toString());
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Eye Helper'),
          centerTitle: true,
          backgroundColor: Colors.lightGreen.withOpacity(0.8),
        ),
        body: HomePage(cameras),
      ),
    );
  }
}







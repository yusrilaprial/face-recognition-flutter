import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:face_recognition/utils/widget_util.dart';
import 'package:face_recognition/screens/home_screen.dart';

List<CameraDescription> cameras = <CameraDescription>[];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(navigatorKey: navigatorKey, home: const HomeScreen());
  }
}

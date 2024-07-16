import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
// import 'package:image/image.dart' as img;

const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";

class TFLiteHomeScreen extends StatefulWidget {
  const TFLiteHomeScreen({super.key});

  @override
  State<TFLiteHomeScreen> createState() => _TFLiteHomeScreenState();
}

class _TFLiteHomeScreenState extends State<TFLiteHomeScreen> {
  final String _model = ssd;
  File? _image;
  double? _imageWidth;
  double? _imageHeight;
  bool _busy = false;

  List<dynamic>? _recognitions;

  @override
  void initState() {
    super.initState();
    _busy = true;
    _loadModel().then((_) {
      setState(() {
        _busy = false;
      });
    });
  }

  Future<void> _loadModel() async {
    await Tflite.close();
    try {
      String? res;
      if (_model == yolo) {
        res = await Tflite.loadModel(
          model: "assets/tflite/yolov2_tiny.tflite",
          labels: "assets/tflite/yolov2_tiny.txt",
        );
      } else {
        res = await Tflite.loadModel(
          model: "assets/tflite/ssd_mobilenet.tflite",
          labels: "assets/tflite/ssd_mobilenet.txt",
        );
      }
      print(res);
    } on PlatformException {
      print('Failed to load the model');
    }
  }

  Future<void> selectFromImagePicker() async {
    var image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _busy = true);
    predictImage(File(image.path));
  }

  Future<void> predictImage(File image) async {
    if (_model == yolo) {
      await yolov2Tiny(image);
    } else {
      await ssdMobileNet(image);
    }

    FileImage(image)
        .resolve(const ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        })));

    setState(() {
      _image = image;
      _busy = false;
    });
  }

  Future<void> yolov2Tiny(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
      path: image.path,
      model: "YOLO",
      threshold: 0.3,
      imageMean: 0.0,
      imageStd: 0.0,
      numResultsPerClass: 1,
    );

    setState(() {
      _recognitions = recognitions;
    });
  }

  Future<void> ssdMobileNet(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
      path: image.path,
      numResultsPerClass: 1,
    );

    setState(() {
      _recognitions = recognitions;
    });
  }

  List<Widget> _renderBoxes(Size size) {
    if (_recognitions == null) return [];
    if (_imageWidth == null || _imageHeight == null) return [];

    double factorX = size.width;
    double factorY = _imageHeight! / _imageWidth! * size.width;

    Color blue = Colors.blue;

    return _recognitions!.map((re) {
      return Positioned(
        left: re["rect"]["x"] * factorX,
        top: re["rect"]["y"] * factorY,
        width: re["rect"]["w"] * factorX,
        height: re["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: blue, width: 4),
          ),
          child: Text(
            "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = blue,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget> stackChildren = [];
    stackChildren.add(Positioned(
      top: 0,
      left: 0,
      width: size.width,
      child: _image == null
          ? const Text("No Image")
          : Image.file(
              _image!,
            ),
    ));
    stackChildren.addAll(_renderBoxes(size));

    if (_busy) {
      stackChildren.add(const Center(
        child: CircularProgressIndicator(),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("TFLite Home")),
      floatingActionButton: FloatingActionButton(
        tooltip: "Pick Image From Gallery",
        onPressed: () => selectFromImagePicker(),
        child: const Icon(Icons.image),
      ),
      body: Stack(
        children: stackChildren,
      ),
    );
  }
}

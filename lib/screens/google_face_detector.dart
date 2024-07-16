import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class GoogleFaceDetector extends StatefulWidget {
  const GoogleFaceDetector({super.key});

  @override
  State<GoogleFaceDetector> createState() => _GoogleFaceDetectorState();
}

class _GoogleFaceDetectorState extends State<GoogleFaceDetector> {
  File? _image;
  List<Face>? _faces;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      // enableContours: true,
      // enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<void> _pickFromCamera() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 50);
    _pickImage(pickedFile);
  }

  Future<void> _pickFromGallery() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);
    _pickImage(pickedFile);
  }

  Future<void> _pickImage(XFile? pickedFile) async {
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
        _faces = null;
      });
      await _detectFaces(imageFile);
    }
  }

  Future<void> _detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final List<Face> faces = await _faceDetector.processImage(inputImage);

    setState(() {
      _faces = faces;
    });
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Detection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? const Text('No image selected.')
                : FittedBox(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width *
                          (_image!.height / _image!.width),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_image!),
                          if (_faces != null)
                            ..._faces!.map((face) => Positioned(
                                  left: face.boundingBox.left *
                                      MediaQuery.of(context).size.width /
                                      _image!.width,
                                  top: face.boundingBox.top *
                                      MediaQuery.of(context).size.width *
                                      (_image!.height / _image!.width) /
                                      _image!.height,
                                  width: face.boundingBox.width *
                                      MediaQuery.of(context).size.width /
                                      _image!.width,
                                  height: face.boundingBox.height *
                                      MediaQuery.of(context).size.width *
                                      (_image!.height / _image!.width) /
                                      _image!.height,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.red, width: 2),
                                    ),
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickFromGallery,
              onLongPress: _pickFromCamera,
              child: const Text('Choose/Capture Image'),
            ),
          ],
        ),
      ),
    );
  }
}

extension on File {
  int get width {
    final decodedImage = img.decodeImage(readAsBytesSync());
    return decodedImage?.width ?? 0;
  }

  int get height {
    final decodedImage = img.decodeImage(readAsBytesSync());
    return decodedImage?.height ?? 0;
  }
}

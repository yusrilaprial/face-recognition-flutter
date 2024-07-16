import 'package:face_recognition/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class LiveGfaceDetector extends StatefulWidget {
  const LiveGfaceDetector({super.key});

  @override
  State<LiveGfaceDetector> createState() => _LiveGfaceDetectorState();
}

class _LiveGfaceDetectorState extends State<LiveGfaceDetector> {
  final selectedCamera = cameras.first;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      // enableContours: true,
      // enableLandmarks: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  List<Face> _faces = [];
  final List<Face> _registerFaces = [];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
      fps: 12,
    );

    _initializeControllerFuture = _controller.initialize().then((_) {
      _controller.startImageStream((CameraImage image) async {
        // Proses setiap frame dari stream kamera
        await _processCameraImage(image);
      });
    });
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    // Konversi kamera image ke InputImage
    final inputImage = _getInputImage(cameraImage);
    if (inputImage == null) return;

    // Lakukan deteksi wajah
    final faces = await _faceDetector.processImage(inputImage);
    setState(() {
      var ids = _registerFaces.map((rFace) => rFace.trackingId).toList();
      for (var face in faces) {
        if (!ids.contains(face.trackingId) && face.trackingId != null) {
          _registerFaces.add(face);
        }
      }
      _faces = faces;
    });
  }

  Uint8List _yuv420ToNV21(CameraImage image) {
    var nv21 = Uint8List(image.planes[0].bytes.length +
        image.planes[1].bytes.length +
        image.planes[2].bytes.length);

    var yBuffer = image.planes[0].bytes;
    var uBuffer = image.planes[1].bytes;
    var vBuffer = image.planes[2].bytes;

    nv21.setRange(0, yBuffer.length, yBuffer);

    int i = 0;
    while (i < uBuffer.length) {
      nv21[yBuffer.length + i] = vBuffer[i];
      nv21[yBuffer.length + i + 1] = uBuffer[i];
      i += 2;
    }

    return nv21;
  }

  InputImage? _getInputImage(CameraImage cameraImage) {
    Uint8List newImg = _yuv420ToNV21(cameraImage);
    final plane = cameraImage.planes.first;
    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
    final rotation =
        InputImageRotationValue.fromRawValue(selectedCamera.sensorOrientation);
    if (rotation == null) return null;

    return InputImage.fromBytes(
      bytes: newImg,
      metadata: InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: rotation,
        format: format!,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller),
                if (_faces.isNotEmpty)
                  ..._faces.map((face) {
                    final boundingBox = face.boundingBox;

                    // Get the size of the CameraPreview
                    final previewSize = _controller.value.previewSize!;
                    final screenHeight = MediaQuery.of(context).size.height;
                    final screenWidth = MediaQuery.of(context).size.width;

                    // Calculate the scale factors
                    final scaleX = screenWidth / previewSize.height;
                    final scaleY = screenHeight / previewSize.width;

                    return Positioned(
                      left: boundingBox.left * scaleX,
                      top: boundingBox.top * scaleY,
                      width: boundingBox.width * scaleX,
                      height: boundingBox.height * scaleY,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                      ),
                    );
                  }),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    "Total Faces: ${_registerFaces.length}",
                    style: const TextStyle(
                      backgroundColor: Colors.white,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

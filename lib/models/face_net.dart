// import 'dart:typed_data';
// import 'package:tflite_flutter/tflite_flutter.dart';

// class FaceNet {
//   Interpreter? _interpreter;

//   FaceNet() {
//     _loadModel();
//   }

//   void _loadModel() async {
//     _interpreter = await Interpreter.fromAsset('assets/faceantispoof.tflite');
//   }

//   Future<List<double>> getFaceEmbedding(Float32List imageBytes) async {
//     // // Konversi byte array ke format yang sesuai
//     // var input = _preprocess(imageBytes);
//     // var output = List.filled(128, 0.0).reshape([1, 128]);

//     // _interpreter?.run(input, output);

//     // return output[0];

//     if (_interpreter == null) {
//       _loadModel();
//     }

//     if (_interpreter == null) {
//       throw Exception('Failed to load model.');
//     }

//     var input = imageBytes.reshape([1, 160, 160, 3]);
//     var output = List.generate(1, (index) => List.filled(128, 0.0));

//     _interpreter?.run(input, output);

//     return output[0];
//   }

//   // List<List<List<List<double>>>> _preprocess(Float32List imageBytes) {
//   //   var buffer = Float32List(160 * 160 * 3);

//   //   for (var i = 0; i < imageBytes.length; i++) {
//   //     buffer[i] = imageBytes[i] / 255.0;
//   //   }

//   //   var reshaped = List.generate(
//   //     1,
//   //     (index) => List.generate(
//   //       160,
//   //       (y) => List.generate(
//   //         160,
//   //         (x) => List.generate(
//   //             3, (c) => buffer[(y * 160 * 3) + (x * 3) + c].toDouble()),
//   //       ),
//   //     ),
//   //   );

//   //   return reshaped;
//   // }

//   void close() {
//     _interpreter?.close();
//   }
// }

// extension Reshape on List<double> {
//   List<List<double>> reshape(List<int> shape) {
//     int total = shape.reduce((value, element) => value * element);
//     if (total != length) {
//       throw Exception(
//           'Total elements mismatch expected: $total but found $length');
//     }
//     List<List<double>> reshaped = [];
//     for (int i = 0; i < length; i += shape[1]) {
//       reshaped.add(sublist(i, i + shape[1]));
//     }
//     return reshaped;
//   }
// }

import 'dart:async';
import 'dart:io';
// import 'dart:typed_data';
import 'package:face_recognition/models/member.dart';
import 'package:face_recognition/models/presence.dart';
import 'package:face_recognition/screens/camera_screen.dart';
import 'package:face_recognition/screens/detector_screen.dart';
import 'package:face_recognition/screens/google_face_detector.dart';
import 'package:face_recognition/screens/live_gface_detector.dart';
import 'package:face_recognition/screens/local_auth_screen.dart';
// import 'package:face_recognition/screens/tflite_home_screen.dart';
import 'package:face_recognition/utils/widget_util.dart';
import 'package:face_recognition/widgets/my_image_view.dart';
import 'package:flutter_face_api/flutter_face_api.dart';
// import 'package:image/image.dart' as img;
// import 'package:face_recognition/models/face_net.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int indexMenu = 0;
  final List<Map<String, dynamic>> menus = [
    {
      'label': 'Home',
      'icon': Icons.home,
      'widget': const Home(),
    },
    {
      'label': 'Attendance',
      'icon': Icons.person,
      'widget': const Attendance(),
    },
    {
      'label': 'Registration',
      'icon': Icons.app_registration,
      'widget': const Register(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Face Recognition")),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indexMenu,
        onDestinationSelected: (int index) => setState(() => indexMenu = index),
        destinations: menus.map((menu) {
          return NavigationDestination(
            icon: Icon(menu['icon']),
            label: menu['label'],
          );
        }).toList(),
      ),
      body: menus[indexMenu]['widget'] as Widget,
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Home"),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DetectorScreen()),
              );
            },
            child: const Text("Face Detector"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
            },
            child: const Text("Camera"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoogleFaceDetector(),
                ),
              );
            },
            child: const Text("Google Face Detector"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LiveGfaceDetector(),
                ),
              );
            },
            child: const Text("Live G-Face Detector"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocalAuthScreen(),
                ),
              );
            },
            child: const Text("Local Auth"),
          ),
          const ElevatedButton(
            onPressed: null,
            // onPressed: () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => const TFLiteHomeScreen(),
            //     ),
            //   );
            // },
            child: Text("TfLite Home"),
          )
        ],
      ),
    );
  }
}

class Attendance extends StatefulWidget {
  const Attendance({super.key});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  final FaceSDK faceSdk = FaceSDK.instance;
  bool isReady = false;
  bool isLoading = false;
  List<Member> members = [];
  List<Presence> presences = [];

  @override
  void initState() {
    super.initState();
    initFaceSdk();
    getMembers();
    getTodayPresences();
  }

  void initFaceSdk() async {
    final (success, error) = await faceSdk.initialize();
    if (!success) {
      showMyOkDialog(title: "Error", message: "Error: ${error?.message}");
      return;
    }
    setState(() => isReady = true);
  }

  Future<void> getMembers() async {
    members = await MemberSQLite().getTodayPresenceMemberList();
    setState(() => members);
  }

  Future<void> getTodayPresences() async {
    presences = await PresenceSQLite().getTodayPresenceList();
    setState(() => presences);
  }

  Future<FaceCaptureImage?> faceCapture() async {
    final response = await faceSdk.startFaceCapture();
    return response.image;
  }

  Future<double> matchFaces(List<MatchFacesImage> matchFacesImages) async {
    final request = MatchFacesRequest(matchFacesImages);
    final response = await faceSdk.matchFaces(request);
    final split = await faceSdk.splitComparedFaces(response.results, 0.75);
    final match = split.matchedFaces;
    if (match.isEmpty) return 0;
    return match[0].similarity * 100;
  }

  Future<List<MatchFacesImage>> createCompareImages(Member member) async {
    if (member.imagePath == null) {
      throw Exception("Please add member image first");
    }
    final memberImageByte = File(member.imagePath!).readAsBytesSync();
    final mfMemberImage = MatchFacesImage(
      memberImageByte,
      ImageType.PRINTED,
    );

    final captImage = await faceCapture();
    if (captImage == null) {
      throw Exception("Please capture photo first");
    }
    final mfCapturedImage = MatchFacesImage(
      captImage.image,
      captImage.imageType,
    );

    return [mfMemberImage, mfCapturedImage];
  }

  Future<double> checkSimilarity(List<MatchFacesImage> matchFacesImages) async {
    final similarity = await matchFaces(matchFacesImages);
    if (similarity < 90) {
      throw Exception(
        "Your face doesn't match!. Your similarity is ${similarity.toStringAsFixed(2)}%",
      );
    }
    return similarity;
  }

  Future<void> startPresent(Member member) async {
    setState(() => isLoading = true);
    try {
      final compareImages = await createCompareImages(member);
      final similarity = await checkSimilarity(compareImages);
      final presence = Presence(memberId: member.id, startTime: DateTime.now());
      await PresenceSQLite().insertPresence(presence);
      getMembers();
      getTodayPresences();
      showMySnackBar(
        message:
            "Start presence saved successfully. Similarity ${similarity.toStringAsFixed(2)}%",
      );
    } catch (error) {
      showMyOkDialog(title: "Error", message: error.toString());
    }
    setState(() => isLoading = false);
  }

  Future<void> finishPresent(Member member) async {
    setState(() => isLoading = true);
    try {
      final compareImages = await createCompareImages(member);
      final similarity = await checkSimilarity(compareImages);
      final presence = Presence(
        id: member.presence?.id,
        memberId: member.id,
        startTime: member.presence?.startTime,
        finishTime: DateTime.now(),
      );
      await PresenceSQLite().updatePresence(presence);
      getMembers();
      getTodayPresences();
      showMySnackBar(
        message:
            "Finish presence saved successfully. Similarity ${similarity.toStringAsFixed(2)}%",
      );
    } catch (error) {
      showMyOkDialog(title: "Error", message: error.toString());
    }
    setState(() => isLoading = false);
  }

  IconButton _buildPresenceButton(Member member) {
    final presence = member.presence;
    if (presence == null || presence.startTime == null) {
      return IconButton(
        onPressed: () => startPresent(member),
        icon: const Icon(Icons.login),
        style: ButtonStyle(
          iconColor: WidgetStateProperty.all(Colors.white),
          backgroundColor: WidgetStateProperty.all(Colors.green),
        ),
      );
    }
    if (presence.finishTime == null) {
      return IconButton(
        onPressed: () => finishPresent(member),
        icon: const Icon(Icons.logout),
        style: ButtonStyle(
          iconColor: WidgetStateProperty.all(Colors.white),
          backgroundColor: WidgetStateProperty.all(Colors.red),
        ),
      );
    }
    return IconButton(
      onPressed: null,
      icon: const Icon(Icons.person),
      style: ButtonStyle(
        iconColor: WidgetStateProperty.all(Colors.white),
        backgroundColor: WidgetStateProperty.all(Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await getMembers();
        await getTodayPresences();
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Column(
                children: [
                  Text(
                    "Presences: ${DateFormat("E, d MMM yyyy").format(DateTime.now())}",
                  ),
                  Expanded(
                    child: ListView(
                      children: List.generate(members.length, (i) {
                        return Card(
                          child: ListTile(
                            leading: MyImageView(
                              image: members[i].imagePath,
                              imageType: MyImageViewType.file,
                            ),
                            title: Text(members[i].name ?? "-"),
                            trailing: _buildPresenceButton(members[i]),
                          ),
                        );
                      }),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: List.generate(presences.length, (i) {
                        return Card(
                          child: ListTile(
                            leading: MyImageView(
                              image: presences[i].member?.imagePath,
                              imageType: MyImageViewType.file,
                            ),
                            title: Text(presences[i].member?.name ?? "-"),
                            subtitle: ListBody(children: [
                              Text(
                                  "Start: ${presences[i].startTime != null ? DateFormat("H:m:s").format(presences[i].startTime!) : "-"}"),
                              Text(
                                  "Finish: ${presences[i].finishTime != null ? DateFormat("H:m:s").format(presences[i].finishTime!) : "-"}"),
                            ]),
                            trailing: Icon(
                              presences[i].startTime != null &&
                                      presences[i].finishTime != null
                                  ? Icons.check_circle
                                  : Icons.work,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          myLoading(isLoading),
        ],
      ),
    );
  }
}

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _isFaceDetected = false;
  File? _image;
  final _nameCtrl = TextEditingController();
  late ImagePicker _imagePicker;
  late FaceDetector _faceDetector;
  List<Member> members = [];
  String message = "No Face Detected";

  @override
  void initState() {
    super.initState();

    // Initialized Image Picker
    _imagePicker = ImagePicker();

    // Initialized Face Detector
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
    initMembers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _faceDetector.close();
    super.dispose();
  }

  initMembers() async {
    members = await MemberSQLite().getMemberList();
    setState(() {});
  }

  chooseImage() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) _image = File(image.path);
    doFaceDetection();
  }

  captureImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image != null) _image = File(image.path);
    doFaceDetection();
  }

  // Future<List<double>> extractFaceEmbedding(InputImage image) async {
  //   // Konversi InputImage ke format yang diterima oleh model TFLite
  //   final imageBytes = await _imageToByteList(image);

  //   final faceNetModel = FaceNet();
  //   final embedding = faceNetModel.getFaceEmbedding(imageBytes);
  //   faceNetModel.close();

  //   return embedding;
  // }

  // Future<Float32List> _imageToByteList(InputImage image) async {
  //   // Baca gambar dari file path
  //   final File file = File(image.filePath!);
  //   final img.Image? originalImage = img.decodeImage(file.readAsBytesSync());

  //   if (originalImage == null) {
  //     throw Exception('Failed to decode image');
  //   }

  //   // Ubah ukuran gambar ke 160x160 (atau sesuai dengan input model)
  //   final img.Image resizedImage =
  //       img.copyResize(originalImage, width: 160, height: 160);

  //   // Konversi gambar ke format float
  //   final List<int> imageBytes = resizedImage.getBytes();
  //   final Float32List floatList = Float32List(160 * 160 * 3);

  //   for (int i = 0; i < imageBytes.length; i++) {
  //     floatList[i] = imageBytes[i] / 255.0; // Normalisasi nilai ke [0, 1]
  //   }

  //   return floatList;
  // }

  Future<void> registerFace() async {
    try {
      if (_image == null || _nameCtrl.text.isEmpty) {
        setState(() {
          message = "Please Add Image or Name";
        });
        return;
      }
      final InputImage inputImage = InputImage.fromFile(_image!);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        print('No faces detected!');
      } else {
        print('Face detected and registered!');
        // final embedding = await extractFaceEmbedding(inputImage);
        // print(embedding);
        final newFace = Member(
          imagePath: _image!.path,
          name: _nameCtrl.text,
          // embedding: embedding,
        );
        await MemberSQLite().insertMember(newFace);
        _image = null;
        _nameCtrl.clear();
        _isFaceDetected = false;
        initMembers();
        print('Face saved to database!');
        message = "Face Saved";
      }
    } catch (e) {
      print(e);
      message = "Error: $e";
    }
    setState(() {});
  }

  doFaceDetection() async {
    try {
      if (_image == null) return;
      final InputImage inputImage = InputImage.fromFile(_image!);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      // for (Face face in faces) {
      //   final Rect boundingBox = face.boundingBox;
      //   print("React bounding box:$boundingBox");
      // }

      if (faces.isEmpty) {
        print('No faces detected!');
        message = "No Face Detected";
        _isFaceDetected = false;
      } else {
        print('Face detected!');
        message = "Face Detected";
        _isFaceDetected = true;
      }
    } catch (e) {
      print(e);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 150, width: 150)
                : const Icon(Icons.image, size: 150),
            TextField(
              decoration: const InputDecoration(labelText: "Name"),
              controller: _nameCtrl,
            ),
            _isFaceDetected
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => registerFace(),
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(Colors.green),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _image = null;
                            _nameCtrl.clear();
                            _isFaceDetected = false;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(Colors.red),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: () => chooseImage(),
                    onLongPress: () => captureImage(),
                    child: const Text("Choose/Capture Image"),
                  ),
            Text(message),
            Expanded(
                child: ListView(children: [
              for (Member member in members)
                Card(
                  child: ListTile(
                    leading: MyImageView(
                      image: member.imagePath,
                      imageType: MyImageViewType.file,
                    ),
                    title: Text(member.name ?? "-"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await MemberSQLite().deleteMember(member.id!);
                        initMembers();
                      },
                    ),
                  ),
                ),
            ])),
          ],
        ),
      ),
    );
  }
}

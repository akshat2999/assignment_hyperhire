import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toast/toast.dart';
import 'package:unicons/unicons.dart';

import 'drawing_room_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  bool isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  Future<void> _initializeCamera() async {
    CameraLensDirection initialDirection =
        isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back;

    final List<CameraDescription> cameras = await availableCameras();
    final CameraDescription selectedCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == initialDirection,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();

    setState(() {});
  }

  Future<void> _toggleCamera() async {
    await _controller.dispose();
    isFrontCamera = !isFrontCamera;
    await _initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          Icon(
            UniconsLine.ellipsis_v,
            color: Colors.white,
          )
        ],
      ),
      body: Column(
        children: [
          FutureBuilder(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          SizedBox(
            height: 10,
          ),
          TextButton(
            onPressed: () async {
              try {
                await _initializeControllerFuture;
                final image = await _controller.takePicture();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DrawingRoomScreen(imagePath: image.path),
                  ),
                );
              } catch (e) {
                print(e);
              }
            },
            child: Image.asset(
              'images/camera_button.png',
              width: 64,
              height: 64,
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 35.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            FloatingActionButton(
              backgroundColor: Colors.transparent,
              heroTag: "btn1",
              onPressed: () async {
                final pickedFile =
                    await ImagePicker().pickImage(source: ImageSource.gallery);

                if (pickedFile != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DrawingRoomScreen(imagePath: pickedFile.path!),
                    ),
                  );
                }
              },
              child: Icon(
                Icons.insert_photo_outlined,
                size: 30,
                color: Colors.white,
              ),
            ),
            FloatingActionButton(
              backgroundColor: Colors.transparent,
              heroTag: "btn2",
              onPressed: () async {
                try {
                  await _toggleCamera();
                } catch (e) {
                  print(e);
                }
              },
              child: Icon(
                UniconsLine.sync,
                size: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

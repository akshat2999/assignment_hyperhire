import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:unicons/unicons.dart';

import 'drawing_point.dart';

class DrawingRoomScreen extends StatefulWidget {
  final String imagePath;

  const DrawingRoomScreen({super.key, required this.imagePath});

  @override
  State<DrawingRoomScreen> createState() => _DrawingRoomScreenState();
}

class _DrawingRoomScreenState extends State<DrawingRoomScreen> {
  Uint8List? _imageFile;
  ScreenshotController screenshotController = ScreenshotController();
  bool enabled = false;
  bool saveEnabled = false;
  var historyDrawingPoints = <DrawingPoint>[];
  var drawingPoints = <DrawingPoint>[];

  var selectedColor = Color.fromRGBO(1, 255, 11, 0.5);
  double selectedWidth = 0;
  double selectedHeight = 0;

  DrawingPoint? currentDrawingPoint;
  late File imageFile;
  late List<Face> faces;

  @override
  void initState() {
    super.initState();
    imageFile = File(widget.imagePath);
    faces = [];
    detectFaces();
  }

  Future<void> detectFaces() async {
    final inputImage = InputImage.fromFilePath(widget.imagePath);
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final List<Face> detectedFaces =
        await faceDetector.processImage(inputImage);

    setState(() {
      faces = detectedFaces;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (faces.length > 2) {
      Fluttertoast.showToast(
          msg: '2개 이상의 얼굴이 감지되었어요!',
          fontSize: 18,
          gravity: ToastGravity.TOP,
          textColor: Colors.white);
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            UniconsLine.times,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Icon(
            UniconsLine.ellipsis_v,
            color: Colors.white,
          )
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Canvas
          Screenshot(
            controller: screenshotController,
            child: Container(
              width: 520,
              height: 520,
              child: GestureDetector(
                onPanStart: (details) {
                  if (enabled)
                    setState(() {
                      saveEnabled = true;
                      currentDrawingPoint = DrawingPoint(
                        id: DateTime.now().microsecondsSinceEpoch,
                        offsets: details.localPosition,
                        color: selectedColor,
                        width: selectedWidth,
                        height: selectedHeight,
                      );

                      if (currentDrawingPoint == null) return;
                      drawingPoints.add(currentDrawingPoint!);
                      historyDrawingPoints = List.of(drawingPoints);
                    });
                },
                onPanUpdate: (details) {
                  if (enabled)
                    setState(() {
                      if (currentDrawingPoint == null) return;
                      drawingPoints.last = currentDrawingPoint!;
                      historyDrawingPoints = List.of(drawingPoints);
                    });
                },
                onPanEnd: (_) {
                  if (enabled) currentDrawingPoint = null;
                },
                child: Container(
                  width: 520,
                  height: 520,
                  child: CustomPaint(
                    foregroundPainter: DrawingPainter(
                      drawingPoints: drawingPoints,
                    ),
                    child: Center(
                      child: Container(
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.contain,
                        ),
                        width: 520,
                        height: 520,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      UniconsLine.corner_up_left_alt,
                      color: Colors.white,
                    ),
                    label: Text(
                      "다시찍기",
                      style: TextStyle(color: Colors.white),
                    ))
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Visibility(
                  visible: faces.length <= 2,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        enabled = true;
                        selectedWidth = 45;
                        selectedHeight = 26;
                      });
                    },
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "눈",
                          style: TextStyle(color: Colors.black),
                        )),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ))),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                Visibility(
                  visible: faces.length <= 2,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        enabled = true;
                        selectedWidth = 66;
                        selectedHeight = 30;
                      });
                    },
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "입",
                          style: TextStyle(color: Colors.black),
                        )),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ))),
                  ),
                )
              ],
            ),
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        margin: EdgeInsets.only(bottom: 20),
        child: Visibility(
          visible: faces.length <= 2,
          child: ElevatedButton(
            onPressed: () async {
              Uint8List? img = await screenshotController.capture();
              final result = await ImageGallerySaver.saveImage(img!,
                  quality: 60, name: "hello");
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text("Image saved")));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              child: Text(
                "저장하기",
                style: TextStyle(color: Colors.white),
              ),
            ),
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    !saveEnabled ? Color(0xffD3D3D3) : Color(0xff7B8FF7)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ))),
          ),
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> drawingPoints;

  DrawingPainter({required this.drawingPoints});

  @override
  void paint(Canvas canvas, Size size) {
    for (var drawingPoint in drawingPoints) {
      final paint = Paint()
        ..color = drawingPoint.color
        ..isAntiAlias = true
        ..strokeWidth = drawingPoint.width
        ..strokeCap = StrokeCap.butt;
      canvas.drawOval(
          Rect.fromCenter(
              center: drawingPoint.offsets,
              width: drawingPoint.width,
              height: drawingPoint.height),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

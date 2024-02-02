import 'package:flutter/material.dart';

class DrawingPoint {
  int id;
  Offset offsets;
  Color color;
  double width;
  double height;

  DrawingPoint({
    this.id = -1,
    this.offsets = Offset.zero,
    this.color = Colors.black,
    this.width = 2,
    this.height = 4,
  });
}

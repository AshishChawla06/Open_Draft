import 'dart:io';
import 'package:flutter/material.dart';

/// Native implementation - uses FileImage for local files
ImageProvider getImageProvider(String path) {
  return FileImage(File(path));
}

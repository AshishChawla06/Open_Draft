// Stub implementation for web (dart:io not available)
// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:typed_data';

class File {
  File(String path);

  Future<bool> exists() async => false;

  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('File operations not supported on web');
  }

  Future<File> copy(String newPath) async {
    throw UnsupportedError('File operations not supported on web');
  }
}

class Directory {
  Directory(String path);

  String get path => '';

  Future<bool> exists() async => false;

  Future<Directory> create({bool recursive = false}) async {
    throw UnsupportedError('Directory operations not supported on web');
  }
}

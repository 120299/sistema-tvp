import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';

class ImageStorageService {
  static const String _boxName = 'product_images';
  Box<String>? _box;
  final StreamController<void> _imageChangeController =
      StreamController<void>.broadcast();

  Stream<void> get onImageChanged => _imageChangeController.stream;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<String> saveImage(String productoId, Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);
    final imagePath = 'products/$productoId.jpg';
    await _box?.put(imagePath, base64Image);
    _imageChangeController.add(null);
    return imagePath;
  }

  Future<Uint8List?> getImage(String imagePath) async {
    final base64Image = _box?.get(imagePath);
    if (base64Image != null) {
      return base64Decode(base64Image);
    }
    return null;
  }

  Future<void> deleteImage(String imagePath) async {
    await _box?.delete(imagePath);
    _imageChangeController.add(null);
  }

  Future<String> saveImageFromBase64(
    String productoId,
    String base64String,
  ) async {
    final imagePath = 'products/$productoId.jpg';
    await _box?.put(imagePath, base64String);
    _imageChangeController.add(null);
    return imagePath;
  }

  String getBase64FromPath(String imagePath) {
    return _box?.get(imagePath) ?? '';
  }

  bool hasImage(String imagePath) {
    return _box?.containsKey(imagePath) ?? false;
  }

  Future<void> clearAll() async {
    await _box?.clear();
    _imageChangeController.add(null);
  }

  int get imageCount => _box?.length ?? 0;

  void dispose() {
    _imageChangeController.close();
  }
}

final imageStorageService = ImageStorageService();

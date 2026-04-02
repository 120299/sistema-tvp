import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';

class ImageStorageService {
  static const String _boxName = 'product_images';
  static const int _maxCacheSize = 100;
  Box<String>? _box;
  final StreamController<void> _imageChangeController =
      StreamController<void>.broadcast();

  final Map<String, Uint8List> _cache = {};
  final List<String> _cacheOrder = [];

  Stream<void> get onImageChanged => _imageChangeController.stream;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<String> saveImage(String productoId, Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);
    final imagePath = 'products/$productoId.jpg';
    await _box?.put(imagePath, base64Image);
    _addToCache(imagePath, imageBytes);
    _imageChangeController.add(null);
    return imagePath;
  }

  Future<Uint8List?> getImage(String imagePath) async {
    if (_cache.containsKey(imagePath)) {
      return _cache[imagePath];
    }
    final base64Image = _box?.get(imagePath);
    if (base64Image != null) {
      final bytes = base64Decode(base64Image);
      _addToCache(imagePath, bytes);
      return bytes;
    }
    return null;
  }

  Future<void> deleteImage(String imagePath) async {
    await _box?.delete(imagePath);
    _cache.remove(imagePath);
    _cacheOrder.remove(imagePath);
    _imageChangeController.add(null);
  }

  Future<String> saveImageFromBase64(
    String productoId,
    String base64String,
  ) async {
    final imagePath = 'products/$productoId.jpg';
    await _box?.put(imagePath, base64String);
    final bytes = base64Decode(base64String);
    _addToCache(imagePath, bytes);
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
    _cache.clear();
    _cacheOrder.clear();
    _imageChangeController.add(null);
  }

  int get imageCount => _box?.length ?? 0;

  void clearCache() {
    _cache.clear();
    _cacheOrder.clear();
  }

  void _addToCache(String path, Uint8List bytes) {
    if (_cache.containsKey(path)) {
      _cacheOrder.remove(path);
      _cacheOrder.add(path);
      return;
    }

    while (_cache.length >= _maxCacheSize && _cacheOrder.isNotEmpty) {
      final oldest = _cacheOrder.removeAt(0);
      _cache.remove(oldest);
    }

    _cache[path] = bytes;
    _cacheOrder.add(path);
  }

  void dispose() {
    _imageChangeController.close();
  }
}

final imageStorageService = ImageStorageService();

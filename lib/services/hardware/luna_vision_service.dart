import 'dart:io';
import 'package:flutter/foundation.dart'; // [추가] debugPrint 사용을 위해 필요
import 'package:image_picker/image_picker.dart';

class LunaVisionService {
  static final LunaVisionService instance = LunaVisionService._internal();
  factory LunaVisionService() => instance;
  LunaVisionService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<File?> captureOptimization() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 60, // 비용 절감을 위한 최적화
        maxWidth: 1024,
      );
      if (photo != null) return File(photo.path);
    } catch (e) {
      // [수정] print -> debugPrint
      debugPrint("Vision Error: $e");
    }
    return null;
  }
}
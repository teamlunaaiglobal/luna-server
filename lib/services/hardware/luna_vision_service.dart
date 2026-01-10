import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LunaVisionService {
  static final LunaVisionService instance = LunaVisionService._internal();
  factory LunaVisionService() => instance;
  LunaVisionService._internal();

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// 카메라로 사진 찍기
  Future<File?> captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (photo != null) return File(photo.path);
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
    return null;
  }

  /// 갤러리에서 이미지 선택
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (image != null) return File(image.path);
    } catch (e) {
      debugPrint("Gallery Error: $e");
    }
    return null;
  }

  /// 이미지에서 텍스트 추출 (OCR) - 온디바이스
  Future<String> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText result = await _textRecognizer.processImage(inputImage);
      return result.text;
    } catch (e) {
      debugPrint("OCR Error: $e");
      return "";
    }
  }

  /// 영수증 스캔 (촬영 + OCR)
  Future<String> scanReceipt() async {
    File? image = await captureImage();
    if (image == null) return "사진 촬영이 취소됐어요.";
    
    String text = await extractText(image);
    if (text.isEmpty) return "텍스트를 인식하지 못했어요.";
    
    return text;
  }

  /// 명함 스캔 (촬영 + OCR)
  Future<String> scanBusinessCard() async {
    File? image = await captureImage();
    if (image == null) return "사진 촬영이 취소됐어요.";
    
    String text = await extractText(image);
    if (text.isEmpty) return "텍스트를 인식하지 못했어요.";
    
    return text;
  }

  /// 리소스 해제
  void dispose() {
    _textRecognizer.close();
  }
}
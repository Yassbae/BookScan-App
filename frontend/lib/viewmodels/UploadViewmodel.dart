import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/UploadResponse.dart';
import '../services/upload_service.dart';

class UploadViewModel extends ChangeNotifier {
  final UploadService _uploadService;
  // Utilisez 'late' pour un initialisation ultérieure, permise par le setter de test
  late ImagePicker _picker;

  bool _loading = false;
  String? _error;
  UploadResponse? _response;
  List<File> _images = [];

  UploadViewModel(this._uploadService) {
    _picker = ImagePicker();
  }

  bool get loading => _loading;
  String? get error => _error;
  UploadResponse? get response => _response;
  List<File> get images => _images;

  // Ce setter permet à vos tests d'injecter un faux objet ImagePicker.
  @visibleForTesting
  set picker(ImagePicker value) {
    _picker = value;
  }

  void reset() {
    _error = null;
    _response = null;
    _images.clear();
    notifyListeners();
  }

  Future<void> pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _images.add(File(pickedFile.path));
      notifyListeners();
    }
  }

  Future<void> pickImagesFromGallery() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      _images.addAll(pickedFiles.map((f) => File(f.path)));
      notifyListeners();
    }
  }

  Future<void> uploadImages() async {
    if (_images.isEmpty) {
      _error = "No image selected.";
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _uploadService.uploadImages(_images);
      _response = result;

      print("✅ Message: ${_response?.message}");

      for (var item in _response?.data ?? []) {
        print("📘 Item:");
        item.forEach((key, value) {
          print("   $key: $value");
        });
      }    } catch (e) {
      print(e.toString());
      _error = "Erreur lors de l'envoi ";
    }

    _loading = false;
    notifyListeners();
  }

  void removeImageAt(int index) {
    images.removeAt(index);
    notifyListeners();
  }

  void resetScreen() {
    images.clear();
    _response = null;
    _error = null;
    notifyListeners();
  }
}
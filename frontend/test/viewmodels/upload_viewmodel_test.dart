import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:scan_book/models/UploadResponse.dart';
import 'package:scan_book/viewmodels/UploadViewmodel.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'mock_upload_service.mocks.dart';

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late UploadViewModel viewModel;
  late MockUploadService mockUploadService;
  late MockImagePicker mockImagePicker;

  setUp(() {
    mockUploadService = MockUploadService();
    mockImagePicker = MockImagePicker();
    viewModel = UploadViewModel(mockUploadService);
    viewModel.picker = mockImagePicker;
  });

  test('initial state should be correct', () {
    expect(viewModel.images, isEmpty);
    expect(viewModel.loading, false);
    expect(viewModel.error, isNull);
    expect(viewModel.response, isNull);
  });

  test('pickImageFromCamera should add an image to the list', () async {
    final pickedFile = XFile('dummy_path/test_image.jpg');
    when(mockImagePicker.pickImage(source: ImageSource.camera))
        .thenAnswer((_) async => pickedFile);

    await viewModel.pickImageFromCamera();

    expect(viewModel.images.length, 1);
    expect(viewModel.images.first.path, 'dummy_path/test_image.jpg');
  });

  test('pickImageFromCamera should not add image if user cancels', () async {
    when(mockImagePicker.pickImage(source: ImageSource.camera))
        .thenAnswer((_) async => null);

    await viewModel.pickImageFromCamera();

    expect(viewModel.images.isEmpty, true);
  });

  test('pickImagesFromGallery should add multiple images', () async {
    final pickedFiles = [
      XFile('dummy_path/image1.jpg'),
      XFile('dummy_path/image2.jpg'),
    ];
    when(mockImagePicker.pickMultiImage()).thenAnswer((_) async => pickedFiles);

    await viewModel.pickImagesFromGallery();

    expect(viewModel.images.length, 2);
  });

  test('pickImagesFromGallery should do nothing if no images picked', () async {
    when(mockImagePicker.pickMultiImage()).thenAnswer((_) async => []);

    await viewModel.pickImagesFromGallery();

    expect(viewModel.images.isEmpty, true);
  });

  test('uploadImages should set error if no image selected', () async {
    await viewModel.uploadImages();

    expect(viewModel.error, equals("No image selected."));
    expect(viewModel.loading, false);
  });

  test('uploadImages - success path', () async {
    final testFile = File('test_resources/sample.jpg');
    viewModel.images.add(testFile);

    final response = UploadResponse(
      message: "Success",
      data: [
        {"title": "Example", "author": "Author"},
      ],
      file: "file.pdf",
    );

    when(mockUploadService.uploadImages(any)).thenAnswer((_) async => response);

    await viewModel.uploadImages();

    expect(viewModel.loading, false);
    expect(viewModel.error, isNull);
    expect(viewModel.response, isNotNull);
    expect(viewModel.response!.message, "Success");
    verify(mockUploadService.uploadImages([testFile])).called(1);
  });

  test('uploadImages - failure path', () async {
    final testFile = File('test_resources/sample.jpg');
    viewModel.images.add(testFile);

    when(mockUploadService.uploadImages(any))
        .thenThrow(Exception("Upload failed"));

    await viewModel.uploadImages();

    expect(viewModel.loading, false);
    expect(viewModel.response, isNull);
    expect(viewModel.error, "Erreur lors de l'envoi ");
  });

  test('removeImageAt should remove an image', () {
    final file1 = File('dummy1.jpg');
    final file2 = File('dummy2.jpg');
    viewModel.images.addAll([file1, file2]);

    viewModel.removeImageAt(0);

    expect(viewModel.images.length, 1);
    expect(viewModel.images.first.path, 'dummy2.jpg');
  });

  test('removeImageAt should throw RangeError if index invalid', () {
    expect(() => viewModel.removeImageAt(0), throwsRangeError);
  });

  test('reset should clear data', () {
    viewModel.images.add(File('dummy.jpg'));
    viewModel
      ..reset()
      ..resetScreen();

    expect(viewModel.images.isEmpty, true);
    expect(viewModel.response, isNull);
    expect(viewModel.error, isNull);
  });
}

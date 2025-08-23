// scan_history_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:scan_book/models/history_request.dart';
import 'package:scan_book/services/history_service.dart';
import 'package:scan_book/viewmodels/HistoryViewModel.dart';

import 'scan_history_viewmodel_test.mocks.dart';

@GenerateMocks([HistoryService])
void main() {
  late ScanHistoryViewModel viewModel;
  late MockHistoryService mockHistoryService;
  final mockScans = [
    Scan(
      id: 1,
      userId: 1,
      timestamp: DateTime.now(),
      images: ['image1.jpg'],
      ocrResult: [{'text': 'Sample OCR'}],
    ),
    Scan(
      id: 2,
      userId: 1,
      timestamp: DateTime.now(),
      images: ['image2.jpg'],
      ocrResult: [{'text': 'Another OCR'}],
    ),
  ];

  setUp(() {
    mockHistoryService = MockHistoryService();
    viewModel = ScanHistoryViewModel(mockHistoryService);
  });

  group('fetchHistory()', () {
    test('should load scans successfully', () async {
      when(mockHistoryService.getScanHistory())
          .thenAnswer((_) async => mockScans);

      await viewModel.fetchHistory();

      expect(viewModel.scans, mockScans);
      expect(viewModel.isLoading, false);
      expect(viewModel.error, isNull);
      verify(mockHistoryService.getScanHistory()).called(1);
    });

    test('should handle errors during fetch', () async {
      when(mockHistoryService.getScanHistory())
          .thenThrow(Exception('Database error'));

      await viewModel.fetchHistory();

      expect(viewModel.scans, isEmpty);
      expect(viewModel.isLoading, false);
      expect(viewModel.error, 'une erreur est survenu ...');
    });
  });

  group('deleteScansByIds()', () {
    test('should delete scans successfully', () async {
      // 1. Initialisation avec 2 scans
      when(mockHistoryService.getScanHistory())
          .thenAnswer((_) async => [
        Scan(id: 1, userId: 1, timestamp: DateTime.now(), images: [], ocrResult: []),
        Scan(id: 2, userId: 1, timestamp: DateTime.now(), images: [], ocrResult: []),
      ]);
      await viewModel.fetchHistory();
      expect(viewModel.scans.length, 2);

      // 2. Simulation de suppression réussie
      when(mockHistoryService.deleteScans([1])).thenAnswer((_) async {});

      // 3. Tentative de suppression
      await viewModel.deleteScansByIds([1]);

      // 4. Vérifications
      expect(viewModel.scans.length, 1);
      expect(viewModel.scans.any((scan) => scan.id == 1), isFalse);
      expect(viewModel.isLoading, false);
      expect(viewModel.error, isNull);
      verify(mockHistoryService.deleteScans([1])).called(1);
    });
    
    test('should handle deletion errors without modifying scans list', () async {
      // 1. Initialisation avec 2 scans
      when(mockHistoryService.getScanHistory())
          .thenAnswer((_) async => [
        Scan(id: 1, userId: 1, timestamp: DateTime.now(), images: [], ocrResult: []),
        Scan(id: 2, userId: 1, timestamp: DateTime.now(), images: [], ocrResult: []),
      ]);
      await viewModel.fetchHistory();

      // 2. Simulation d'échec de suppression
      when(mockHistoryService.deleteScans([1]))
          .thenThrow(Exception('Deletion failed'));

      // 3. Capture de l'état avant suppression
      final scansBeforeDeletion = viewModel.scans.toList();

      // 4. Tentative de suppression
      await viewModel.deleteScansByIds([1]);

      // 5. Vérifications
      expect(viewModel.scans.length, 2); // Doit rester inchangé
      expect(viewModel.scans, scansBeforeDeletion); // Liste identique
      expect(viewModel.error, 'Delete Failed');
    });
  });

  group('State Management', () {
    test('should notify listeners on state changes', () async {
      when(mockHistoryService.getScanHistory())
          .thenAnswer((_) async => mockScans);
      var listenerCalled = false;
      viewModel.addListener(() => listenerCalled = true);

      await viewModel.fetchHistory();

      expect(listenerCalled, true);
    });
  });
}
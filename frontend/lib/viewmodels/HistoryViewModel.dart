import 'package:flutter/material.dart';
import '../models/history_request.dart';
import '../services/history_service.dart';

class ScanHistoryViewModel extends ChangeNotifier {
  final HistoryService _historyService;

  List<Scan> _scans = [];

  List<Scan> get scans => _scans;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _error;

  String? get error => _error;

  ScanHistoryViewModel(this._historyService);

  Future<void> fetchHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _historyService.getScanHistory();
      print("Fetched scans count: ${data.length}");

      _scans = data;
    } catch (e) {
      _error = "une erreur est survenu ...";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteScansByIds(List<int> ids) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _historyService.deleteScans(ids);
      _scans.removeWhere((scan) => ids.contains(scan.id));
    } catch (e) {
      _error = "Delete Failed";
    }

    _isLoading = false;
    notifyListeners();
  }

}

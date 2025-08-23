import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:scan_book/views/scan_detail_screen.dart';

import '../utils/NetworkUtils.dart' as networkUtils;
import '../viewmodels/HistoryViewModel.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final Set<int> _selectedScanIds = {};

  String formatDate(DateTime dt) {
    return DateFormat('MMM d, yyyy – hh:mm a').format(dt);
  }

  void _onLongPressToggle(int scanId) {
    setState(() {
      if (_selectedScanIds.contains(scanId)) {
        _selectedScanIds.remove(scanId);
      } else {
        _selectedScanIds.add(scanId);
      }
    });
  }

  void _onCheckboxChanged(bool? value, int scanId) {
    setState(() {
      if (value == true) {
        _selectedScanIds.add(scanId);
      } else {
        _selectedScanIds.remove(scanId);
      }
    });
  }

  Future<void> _deleteSelected(ScanHistoryViewModel viewModel) async {
    if (_selectedScanIds.isEmpty) return;

    await viewModel.deleteScansByIds(_selectedScanIds.toList());
    setState(() {
      _selectedScanIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ScanHistoryViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedScanIds.isEmpty
            ? "Scan History"
            : "${_selectedScanIds.length} files selected"),
        actions: [
          if (_selectedScanIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSelected(viewModel),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.fetchHistory(),
        child: Builder(
          builder: (context) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(child: Text("Error: ${viewModel.error}"));
            }

            if (viewModel.scans.isEmpty) {
              return const Center(child: Text("No Scan History"));
            }

            final scans = viewModel.scans;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scans.length,
              itemBuilder: (context, index) {
                final scan = scans[index];
                final isSelected = _selectedScanIds.contains(scan.id);
                final imageUrl = scan.images.isNotEmpty
                    ? "${networkUtils.baseUrl}/${scan.images.first}"
                    : null;
                final bookCount = scan.ocrResult.length;
                final firstBookTitle = bookCount > 0
                    ? scan.ocrResult.first['Title']
                    : "No books found";

                return GestureDetector(
                  onLongPress: () => _onLongPressToggle(scan.id),
                  onTap: () {
                    if (_selectedScanIds.isNotEmpty) {
                      _onLongPressToggle(scan.id);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScanDetailScreen(scan: scan),
                        ),
                      );
                    }
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatDate(scan.timestamp),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$bookCount books detected",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  firstBookTitle,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) =>
                                _onCheckboxChanged(value, scan.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

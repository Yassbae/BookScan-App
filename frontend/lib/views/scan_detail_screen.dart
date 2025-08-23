import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_request.dart';
import '../utils/NetworkUtils.dart' as networkUtils;

class ScanDetailScreen extends StatelessWidget {
  final Scan scan;

  const ScanDetailScreen({super.key, required this.scan});

  String formatDate(DateTime dt) {
    return DateFormat('MMM d, yyyy – hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final images = scan.images;
    final results = scan.ocrResult;

    return Scaffold(
      appBar: AppBar(title: const Text("Scan details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDate(scan.timestamp),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Horizontal Image List
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final imageUrl = "${networkUtils.baseUrl}/${images[index]}";
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "OCR results",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final book = results[index];
                  return ListTile(
                    title: Text(book['Title'] ?? "Title not found"),
                    subtitle: Text(book['Author(s)'] ?? "Unknown author"),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

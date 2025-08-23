import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/generate_excel.dart';
import '../helper/generate_pdf.dart';
import '../viewmodels/UploadViewmodel.dart';

class PrincipleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uploadVM = Provider.of<UploadViewModel>(context);

    void showMessage(String message, {Color backgroundColor = Colors.black87}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reset",
            onPressed: () {
              uploadVM.resetScreen();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sign out",
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              // Supprimer la clé 'jwt_token' qui contient le token JWT
              await prefs.remove('jwt_token');

              await prefs.setBool('isLoggedIn', false);

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await uploadVM.pickImagesFromGallery();
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade100,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await uploadVM.pickImageFromCamera();
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade100,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            uploadVM.images.isEmpty
                ? Image.asset(
              'assets/placeholder.png',
              width: 150,
              height: 200,
              fit: BoxFit.cover,
            )
                : SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: uploadVM.images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            uploadVM.images[index],
                            width: 160,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            uploadVM.removeImageAt(index);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Upload button
            uploadVM.loading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text("Scan images"),
                      onPressed: uploadVM.images.isEmpty
                          ? null
                          : () async {
                              await uploadVM.uploadImages();

                              if (uploadVM.error != null) {
                                showMessage(
                                  uploadVM.error!,
                                  backgroundColor: Colors.red,
                                );
                              } else if (uploadVM.response != null) {
                                showMessage(
                                  "Upload Successful !",
                                  backgroundColor: Colors.green,
                                );
                              }

                              if (uploadVM.response == null ||
                                  uploadVM.response!.data.isEmpty) {
                                showMessage(
                                  "No results detected",
                                  backgroundColor: Colors.orange,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 10),

            const Text(
              "📚 Detected results :",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (uploadVM.response != null &&
                uploadVM.response!.data.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final path = await generateAndSavePdf(
                        uploadVM.response!.data
                            .map(
                              (item) => item.map(
                                (key, value) =>
                                    MapEntry(key, value?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                      );
                      showMessage(
                        path != null
                            ? "PDF saved at : $path"
                            : "Permission denied or error",
                        backgroundColor: path != null
                            ? Colors.green
                            : Colors.red,
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final path = await generateAndSaveExcel(
                        uploadVM.response!.data
                            .map(
                              (item) => item.map(
                                (key, value) =>
                                    MapEntry(key, value?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                      );
                      showMessage(
                        path != null
                            ? "Excel saved at : $path"
                            : "Permission denied or error",
                        backgroundColor: path != null
                            ? Colors.green
                            : Colors.red,
                      );
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text("Excel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Liste des résultats
              Expanded(
                child: ListView.builder(
                  itemCount: uploadVM.response!.data.length,
                  itemBuilder: (context, index) {
                    final item = uploadVM.response!.data[index];
                    return Card(
                      color: Colors.grey[100],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: item.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                "${entry.key} : ${entry.value}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "No results for the moment.\ Please upload images.",
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../shared/firestore_constants.dart';
import '../../shared/theme/colors.dart';

class LegalContentPage extends StatelessWidget {
  final String title;
  final List<String> fieldKeys;

  const LegalContentPage({
    super.key,
    required this.title,
    required this.fieldKeys,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(title),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection(FirestoreConstants.appConfig)
            .doc(FirestoreAppConfigDocs.legal)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fieldKeys.map((key) {
                  final content = (data?[key] as String?) ?? '';
                  if (content.isEmpty) return const SizedBox.shrink();
                  // Add a header if we have multiple keys? Or just spacing.
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      content,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

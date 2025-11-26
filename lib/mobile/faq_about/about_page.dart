import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.deepLayer, AppColors.primaryBackground], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          SizedBox(height: 60),
          Icon(Icons.token_rounded, size: 72, color: AppColors.secondaryAccent),
          SizedBox(height: 12),
          Text('ETA Network', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Expanded(child: SingleChildScrollView(child: Text('ETA Network is a points-earning ecosystem focused on utility and future marketplace integration.'))),
        ]),
      ),
    );
  }
}

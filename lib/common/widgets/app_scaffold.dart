// lib/common/widget/app_scaffold.dart

import 'package:flutter/material.dart';
import 'package:moods/common/widgets/custom_bottom_nav.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}

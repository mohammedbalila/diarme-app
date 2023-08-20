import 'package:flutter/material.dart';

class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Diarme',
      style: TextStyle(
          fontFamily: 'Satisfy', fontWeight: FontWeight.w400, fontSize: 95),
    );
  }
}

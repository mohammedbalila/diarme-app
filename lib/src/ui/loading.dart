import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
    );
  }
}

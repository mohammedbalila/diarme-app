import 'dart:math';

import 'package:flutter/material.dart';
import 'package:empty_widget/empty_widget.dart';

// ignore: must_be_immutable
class EmptyScreen extends StatelessWidget {
  EmptyScreen({
    super.key,
    required this.title,
    required this.subTitle,
  });

  final String title;
  final String subTitle;

  List images = [
    PackageImage.Image_1,
    PackageImage.Image_2,
    PackageImage.Image_3,
    PackageImage.Image_4,
  ];
  @override
  Widget build(BuildContext context) {
    return EmptyWidget(
      image: null,
      packageImage: images[Random().nextInt(4)],
      title: title,
      subTitle: subTitle,
      titleTextStyle: TextStyle(
        fontSize: 22,
        color: Theme.of(context).colorScheme.secondary,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
      ),
    );
  }
}

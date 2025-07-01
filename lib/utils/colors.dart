import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controls theme colors used across the app.
class AppColorsController extends GetxController {
  /// Primary brand color.
  final Rx<Color> primaryColor = Colors.blue.obs;

  /// Background color for dark surfaces.
  final Rx<Color> blackColor = Colors.black.obs;

  /// Default text color on dark backgrounds.
  final Rx<Color> whiteColor = Colors.white.obs;

  /// Text color for unselected elements.
  final Rx<Color> white70Color = Colors.white70.obs;

  /// Neutral grey used for borders and icons.
  final Rx<Color> greyColor = Colors.grey.obs;
}

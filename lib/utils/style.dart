import 'package:flutter/material.dart';

/// A simple reusable button style used throughout the app.
ButtonStyle defaultButtonStyle(Color color) {
  return ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: Colors.white,
    textStyle: const TextStyle(fontSize: 16),
  );
}

// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'package:flutter/material.dart';

class UiHelper {
  static Widget sectionHeader(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );

  static Widget get divider => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0),
        child: Divider(thickness: 2.0),
      );

  static Widget get dividerNoLine => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0),
      );
}

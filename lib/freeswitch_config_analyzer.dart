// Copyright (c) 2015, bitstackers. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library freeswitch_config_analyzer;

import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as libpath;
import 'package:xml/xml.dart';

import 'model.dart';

part 'ivr_analyzer.dart';
part 'dialplan_analyzer.dart';

Map<String, String> variables = {r"$${sounds_dir}": '/usr/local/freeswitch/sounds'};

bool isNotComment(XmlNode node) => node is! XmlComment;

bool fileExists(String path) {
  String unfoldedPath = unfoldVariables(path);

  File file = new File(unfoldedPath);
  return file.existsSync();
}

String unfoldVariables(String text) {
  String unfoldedText = text;
  for (String key in variables.keys) {
    if (unfoldedText.contains(key)) {
      String value = variables[key];
      unfoldedText = unfoldedText.replaceAll(key, value);
    }
  }
  return unfoldedText;
}

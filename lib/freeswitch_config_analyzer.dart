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

bool validTimeOfDay(String timeOfDay) {
  var times = timeOfDay.split('-');
  var componentsA = times[0].split(':');
  var componentsB = times[1].split(':');

  var hourA = int.parse(componentsA[0]);
  var minuteA = int.parse(componentsA[1]);

  var hourB = int.parse(componentsB[0]);
  var minuteB = int.parse(componentsB[1]);

  var a = new DateTime(0,1,1,hourA, minuteA);
  var b = new DateTime(0,1,1,hourB, minuteB);

  if(hourA < 0 || hourA > 24 ||
     hourB < 0 || hourB > 24) {
    return false;
  }

  if(minuteA < 0 || minuteA > 59 ||
     minuteB < 0 || minuteB > 59) {
    return false;
  }

  if(hourA == 24 && minuteA > 0  ||
     hourB == 24 && minuteB > 0 ) {
    return false;
  }

  return a.isBefore(b);
}

bool validWday(String text) {
  List<String> commaSegments = text.split(',');
  for(String comma in commaSegments) {
    List<String> dashSegments = comma.split('-');
    if(dashSegments.length == 1 || dashSegments.length == 2) {
      for(String item in dashSegments) {
        int value = int.parse(item, onError: (source) => null);
        if(value == null) {
          return false;
        } else if(value < 1 || value > 7) {
          return false;
        }
      }
    } else {
      return false;
    }
  }

  return true;
}

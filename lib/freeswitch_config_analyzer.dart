// Copyright (c) 2015, bitstackers. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// The freeswitch_config_analyzer library.
library freeswitch_config_analyzer;

import 'dart:io';

import 'package:path/path.dart' as libpath;
import 'package:xml/xml.dart';

import 'ivr_menu_model.dart';
import 'result.dart';

Map<String, String> variables = {r"$${sounds_dir}": '/usr/local/freeswitch/sounds'};

List<String> skipFiles = ['record_ivr.xml', 'demo_ivr.xml'];
void validateIvrMenus(String path) {
  Directory directory = new Directory(path);
  for (FileSystemEntity entity in directory.listSync()) {
    File file = entity as File;
    if (file != null && file.path.endsWith('.xml') && !skipFiles.any((skip) => file.path.endsWith(skip))) {
      String receptionId = libpath.basenameWithoutExtension(file.path);
      String content = file.readAsStringSync();
      XmlDocument tree = parse(content);
      IvrFile model = XmlToIvrModel(tree, receptionId);
      if (model.errors.isNotEmpty) {
        print('---- Errors in file: "${file.path}" ----');
        model.errors.forEach(print);
      }
    }
  }
}

/**
 * Converts the xml document to a dart model, and validate the strucure of it.
 */
IvrFile XmlToIvrModel(XmlDocument doc, String filename) {
  IvrFile model = new IvrFile();

  //Checks there is only one top Element
  if (doc.children.where(isNotComment).length != 1) {
    model.errors.add('It should start with just one include node.');
    return model;
  }

  //Checks the first element is an include element
  XmlElement includeNode = doc.children.where(isNotComment).first;
  if (includeNode.name.toString() != 'include') {
    model.errors.add('It should start with a "include" node. "${includeNode.name}" != "include"');
    return model;
  }

  for (XmlNode node in includeNode.children.where(isNotComment)) {
    if (node is XmlElement) {
      XmlElement menuElement = node;
      if (menuElement.name.toString() != 'menu') {
        model.errors.add('Inside its include node, should come menu nodes. ${menuElement.name.toString()} != "${menuElement.name.toString()}"');
      } else {
        IvrMenu menu = XmlToIvrMenuModel(node);
        if (!menu.name.startsWith(filename)) {
          menu.errors.add('Menu name does not match file name. Menu: ${menu.name}');
        }
        model.menus.add(menu);
      }
    } else if (node is XmlText && node.text.trim().length > 0) {
      //This might happend if there are a line-break.
      model.errors.add('Beside the menus are there other stuff than XmlElements Type:(${node.runtimeType}) Content:[${node}]');
    }
  }

  for(IvrMenu menu in model.menus) {
    Iterable<IvrEntry> menuSubEntries = menu.entries.where((IvrEntry entry) => entry.action == 'menu-sub');
    for(IvrEntry entry in menuSubEntries) {
      if(!model.menus.any((IvrMenu m) => m.name == entry.param)) {
        entry.errors.add('The referenced menu does not exists. Param="${entry.param}" in menu ${menu.name} for entry with digit ${entry.digits}');
      }
    }
  }

  return model;
}

/**
 * Converts the Xml Structure into dart model.
 */
IvrMenu XmlToIvrMenuModel(XmlElement xml) {
  IvrMenu menu = new IvrMenu();

  Result<XmlAttribute> name = extractAttribute(xml, 'name', required: true);
  if (name.IsValid) {
    menu.name = name.result.value;
  } else {
    menu.errors.addAll(name.errors);
  }

  Result<XmlAttribute> greetLong = extractAttribute(xml, 'greet-long', required: true);
  if (greetLong.IsValid) {
    menu.longGreeting = greetLong.result.value;
    if (!fileExists(menu.longGreeting)) {
      menu.errors.add('Could not find greet-long file. "${unfoldVariables(menu.longGreeting)}"');
    }
  } else {
    menu.errors.addAll(greetLong.errors);
  }

  Result<XmlAttribute> greetShort = extractAttribute(xml, 'greet-short');
  if (greetShort.IsValid && greetShort.result != null) {
    menu.shortGreeting = greetShort.result.value;
    if (!fileExists(menu.shortGreeting)) {
      menu.errors.add('Could not find greet-short file. "${unfoldVariables(menu.shortGreeting)}"');
    }
  } else {
    menu.errors.addAll(greetShort.errors);
  }

  Result<XmlAttribute> invalidSound = extractAttribute(xml, 'invalid-sound');
  if (invalidSound.IsValid && invalidSound.result != null) {
    menu.invalidSound = invalidSound.result.value;
    if (!fileExists(menu.invalidSound)) {
      menu.errors.add('Could not find invalid-sound file. "${unfoldVariables(menu.invalidSound)}"');
    }
  } else {
    menu.errors.addAll(invalidSound.errors);
  }

  Result<XmlAttribute> timeout = extractAttribute(xml, 'timeout');
  if (timeout.IsValid && timeout.result != null) {
    menu.timeout = timeout.result.value;
  } else {
    menu.errors.addAll(timeout.errors);
  }

  Result<XmlAttribute> maxFailures = extractAttribute(xml, 'max-failures');
  if (maxFailures.IsValid && maxFailures.result != null) {
    menu.maxFailues = maxFailures.result.value;
  } else {
    menu.errors.addAll(maxFailures.errors);
  }

  Result<XmlAttribute> maxTimeouts = extractAttribute(xml, 'max-timeouts');
  if (maxTimeouts.IsValid && maxTimeouts.result != null) {
    menu.maxTimeouts = maxTimeouts.result.value;
  } else {
    menu.errors.addAll(maxTimeouts.errors);
  }

  Iterable<XmlElement> elements = xml.children.where((XmlNode node) => node is XmlElement);
  menu.entries.addAll(elements.map(XmlToIvrEntry));

  //Check for duplicate digits
  if (menu.entries.any((IvrEntry a) =>
      menu.entries.any((IvrEntry b) => a != b && a.digits == b.digits))) {
    menu.errors.add('There exists entries with the same digits.');
  }

  //Check for identical params
  if (menu.entries.any((IvrEntry a) =>
      menu.entries.any((IvrEntry b) => a != b && a.param == b.param && a.param != null && a.param.isNotEmpty))) {
    menu.errors.add('There exists entries with the same param.');
  }

  List<String> validActions = ['menu-exec-app', 'menu-sub', 'menu-top'];
  for (IvrEntry entry in menu.entries) {
    if (!validActions.contains(entry.action)) {
      entry.errors.add('Unknown action used. "${entry.action}"');
    }
  }

  return menu;
}

IvrEntry XmlToIvrEntry(XmlElement xml) {
  IvrEntry model = new IvrEntry();
  if (xml.name.toString() != 'entry') {
    model.errors.add('Menu contains elements other than Entry. Elementname: "${xml.name}"');
  }

  Result<XmlAttribute> action = extractAttribute(xml, 'action', required: true);
  if (action.IsValid) {
    model.action = action.result.value;
  } else {
    model.errors.addAll(action.errors);
  }

  Result<XmlAttribute> digits = extractAttribute(xml, 'digits', required: true);
  if (digits.IsValid) {
    model.digits = digits.result.value;
  } else {
    model.errors.addAll(digits.errors);
  }

  Result<XmlAttribute> param = extractAttribute(xml, 'param');
  if (param.IsValid && param.result != null) {
    model.param = param.result.value;
  } else {
    model.errors.addAll(param.errors);
  }

  return model;
}

Result<XmlAttribute> extractAttribute(XmlElement xml, String AttributeName, {bool required: false}) {
  Result<XmlAttribute> result = new Result<XmlAttribute>();

  Iterable<XmlAttribute> nameElem = xml.attributes.where((XmlAttribute attribute) => attribute.name.toString() == AttributeName);
  if (required && (nameElem == null || nameElem.isEmpty)) {
    result.errors.add('Missing "<$AttributeName>" attribute');
  } else if (nameElem.length > 1) {
    result.errors.add('Multiple "<$AttributeName>" attribute');
  } else if (nameElem.isNotEmpty) {
    result.result = nameElem.first;
  }

  return result;
}

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

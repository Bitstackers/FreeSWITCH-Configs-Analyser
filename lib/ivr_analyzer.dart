part of freeswitch_config_analyzer;

List<String> _ivrSkipFiles = ['record_ivr.xml', 'demo_ivr.xml'];

List<IvrFile> readInIvrFiles(String path) {
  List<IvrFile> models = new List<IvrFile>();
  Directory directory = new Directory(path);

  for (File file in directory.listSync().where((FileSystemEntity entity) => entity is File)) {
    if (file != null && file.path.endsWith('.xml') && !_ivrSkipFiles.any(file.path.endsWith)) {
      XmlDocument tree = parse(file.readAsStringSync());
      models.add(new IvrFile.fromXml(tree)..filePath = file.path);
    }
  }

  return models;
}

int validateIvrMenus(Freeswitch model) {
  for (IvrFile file in model.ivrFiles) {
    _validateIvrFile(file);
  }

  int errorCount = 0;
  //Look for multiple menus with the same name.
  HashMap<String, String> menuNames = new HashMap<String, String>();
  for (IvrFile model in model.ivrFiles) {
    for (IvrMenu menu in model.menus) {
      if (menuNames.containsKey(menu.name)) {
        errorCount += 1;
        print( 'There exists multiple menus with the name: "${menu.name}" File: "${model.filePath}" AND File: "${menuNames[menu.name]}"');
      } else {
        menuNames[menu.name] = model.filePath;
      }
    }
  }

  //Print Errors
  for (IvrFile model in model.ivrFiles) {
    List<String> allErrors = model.allErrors;
    if (allErrors.isNotEmpty) {
      print('---- Errors in IVR file: "${model.filePath}" ----');
      allErrors.forEach(print);
      errorCount += allErrors.length;
    }
  }

  return errorCount;
}

/**
 * Validates an IVR file.
 */
void _validateIvrFile(IvrFile file) {
  String filename = libpath.basenameWithoutExtension(file.filePath);

  //Check if the menu name matches the filename.
  for (IvrMenu menu in file.menus) {
    if (!menu.name.startsWith(filename)) {
      menu.errors.add('Menu name does not match file name. Menu: ${menu.name}');
    }
  }

  //Check if references to other IvrMenus is valid.
  for (IvrMenu menu in file.menus) {
    Iterable<IvrEntry> menuSubEntries = menu.entries.where((IvrEntry entry) => entry.action == 'menu-sub');
    for (IvrEntry entry in menuSubEntries) {
      if (!file.menus.any((IvrMenu m) => m.name == entry.param)) {
        entry.errors.add(
            'The referenced menu does not exists. Param="${entry.param}" in menu ${menu.name} for entry with digit ${entry.digits}');
      }
    }
  }

  file.menus.forEach(_validateMenus);
}

/**
 * Validates a menu.
 */
void _validateMenus(IvrMenu menu) {
  if(!fileExists(menu.longGreeting)) {
    menu.errors.add('The greet-long file does not exists: "${unfoldVariables(menu.longGreeting)}"');
  }

  if(menu.shortGreeting != null && menu.shortGreeting.trim().isNotEmpty && !fileExists(menu.shortGreeting)) {
    menu.errors.add('The greet-short file does not exists: "${unfoldVariables(menu.shortGreeting)}"');
  }

  if(menu.invalidSound != null && menu.invalidSound.trim().isNotEmpty && !fileExists(menu.invalidSound)) {
    menu.errors.add('The invalid-sound file does not exists: "${unfoldVariables(menu.invalidSound)}"');
  }

  //Check for duplicate digits
  if (menu.entries.any((IvrEntry a) =>
      menu.entries.any((IvrEntry b) => a != b && a.digits == b.digits))) {
    menu.errors.add('There exists entries with the same digits.');
  }

  //Check for identical params
  if (menu.entries.any((IvrEntry a) =>
      menu.entries.any((IvrEntry b) => a != b &&
                                       a.param == b.param &&
                                       a.param != null &&
                                       a.param.isNotEmpty))) {
    menu.errors.add('There exists entries with the same param in menu ${menu.name}.');
  }

  menu.entries.forEach(_validateEntries);
}

/**
 * Validates an entry.
 */
void _validateEntries(IvrEntry entry) {
  List<String> knownActions = ['menu-exec-app', 'menu-sub', 'menu-top'];
  if (!knownActions.contains(entry.action)) {
    entry.errors.add('Unknown action used. "${entry.action}"');
  }
}

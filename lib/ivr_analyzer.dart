part of freeswitch_config_analyzer;

List<String> _ivrSkipFiles = ['record_ivr.xml', 'demo_ivr.xml'];
void validateIvrMenus(String path) {
  Directory directory = new Directory(path);
  List<IvrFile> models = new List<IvrFile>();
  for (FileSystemEntity entity in directory.listSync()) {
    File file = entity as File;
    if (file != null && file.path.endsWith('.xml') && !_ivrSkipFiles.any(file.path.endsWith)) {
      String filename = libpath.basenameWithoutExtension(file.path);
      String content = file.readAsStringSync();
      XmlDocument tree = parse(content);
      IvrFile model = new IvrFile.fromXml(tree);
      models.add(model);
      model.filePath = file.path;
      _validateIvrFile(model, filename);
    }
  }

  //Look for multiple menus with the same name.
  HashMap<String, String> menuNames = new HashMap<String, String>();
  for(IvrFile model in models) {
    for(IvrMenu menu in model.menus) {
      if(menuNames.containsKey(menu.name)) {
        print('There exists multiple menus with the name: "${menu.name}" File: "${model.filePath}" AND File: "${menuNames[menu.name]}"');
      } else {
        menuNames[menu.name] = model.filePath;
      }
    }
  }

  //Print Errors
  for(IvrFile model in models) {
    if (model.allErrors.isNotEmpty) {
      print('---- Errors in file: "${model.filePath}" ----');
      model.allErrors.forEach(print);
    }
  }
}

/**
 * Validates an IVR file.
 */
void _validateIvrFile(IvrFile model, String filename) {
  //Check if the menu name matches the filename.
  for(IvrMenu menu in model.menus) {
    if (!menu.name.startsWith(filename)) {
      menu.errors.add('Menu name does not match file name. Menu: ${menu.name}');
    }
  }

  //Check if references to other IvrMenus is valid.
  for(IvrMenu menu in model.menus) {
    Iterable<IvrEntry> menuSubEntries = menu.entries.where((IvrEntry entry) => entry.action == 'menu-sub');
    for(IvrEntry entry in menuSubEntries) {
      if(!model.menus.any((IvrMenu m) => m.name == entry.param)) {
        entry.errors.add('The referenced menu does not exists. Param="${entry.param}" in menu ${menu.name} for entry with digit ${entry.digits}');
      }
    }
  }

  model.menus.forEach(_validateMenus);
}

/**
 * Validates a menu.
 */
void _validateMenus(IvrMenu menu) {
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
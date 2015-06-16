part of freeswitch_config_analyzer;

void validateDialplans(String path) {
  Directory receptionsDirectory = new Directory(libpath.join(path, 'receptions'));
  List<DialplanFile> receptionDialplans = new List<DialplanFile>();

  for (FileSystemEntity entity in receptionsDirectory.listSync()) {
    File file = entity as File;
    if (file != null && file.path.endsWith('.xml')) {
      String filename = libpath.basenameWithoutExtension(file.path);
      String content = file.readAsStringSync();
      XmlDocument tree = parse(content);
      DialplanFile model = new DialplanFile.fromXml(tree);
      receptionDialplans.add(model);
      model.filePath = file.path;
      _validateDialplanFile(model, filename);
    }
  }

  //Look for multiple menus with the same name.
  HashMap<String, String> menuNames = new HashMap<String, String>();
  for(DialplanFile model in receptionDialplans) {
    for(Extension extension in model.extensions) {
      if(menuNames.containsKey(extension.name)) {
        print('There exists multiple extensions with the name: "${extension.name}" File: "${model.filePath}" AND File: "${menuNames[extension.name]}"');
      } else {
        menuNames[extension.name] = model.filePath;
      }
    }
  }

  //Print Errors
  for(DialplanFile model in receptionDialplans) {
    if (model.allErrors.isNotEmpty) {
      print('---- Errors in file: "${model.filePath}" ----');
      model.allErrors.forEach(print);
    }
  }
}

void _validateDialplanFile(DialplanFile dialplan, String filename) {
  //Check if the extension name matches the filename.
  for(Extension extension in dialplan.extensions) {
    if (!extension.name.startsWith(filename)) {
      extension.errors.add('Extension name does not match file name. Extension: ${extension.name}');
    }
  }

}

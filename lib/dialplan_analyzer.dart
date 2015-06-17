part of freeswitch_config_analyzer;

List<DialplanFile> readInDialplanFiles(String path) {
  List<DialplanFile> receptionDialplans = new List<DialplanFile>();
  Directory receptionsDirectory = new Directory(libpath.join(path, 'receptions'));

  for (FileSystemEntity entity in receptionsDirectory.listSync()) {
    File file = entity as File;
    if (file != null && file.path.endsWith('.xml')) {
      XmlDocument tree = parse(file.readAsStringSync());
      receptionDialplans.add(new DialplanFile.fromXml(tree)
                               ..filePath = file.path);
    }
  }

  return receptionDialplans;
}

int validateDialplans(Freeswitch model) {
  for(DialplanFile file in model.dialplanFiles) {
    _validateDialplanFile(file, model);
  }

  int errorCount = 0;
  //Look for multiple menus with the same name.
  HashMap<String, String> menuNames = new HashMap<String, String>();
  for (DialplanFile model in model.dialplanFiles) {
    for (Extension extension in model.extensions) {
      if (menuNames.containsKey(extension.name)) {
        errorCount += 1;
        print('There exists multiple extensions with the name: "${extension.name}" File: "${model.filePath}" AND File: "${menuNames[extension.name]}"');
      } else {
        menuNames[extension.name] = model.filePath;
      }
    }
  }

  //Print Errors
  for (DialplanFile model in model.dialplanFiles) {
    if (model.allErrors.isNotEmpty) {
      errorCount += model.allErrors.length;
      print('---- Errors in Dialplan file: "${model.filePath}" ----');
      model.allErrors.forEach(print);
    }
  }

  return errorCount;
}

void _validateDialplanFile(DialplanFile dialplan, Freeswitch model) {
  String filename = libpath.basenameWithoutExtension(dialplan.filePath);

  //Check if the extension name matches the filename.
  for (Extension extension in dialplan.extensions) {
    if (!extension.name.startsWith('reception_$filename')) {
      extension.errors.add('Extension name does not match file name. Extension: ${extension.name}');
    }
  }

  dialplan.extensions.forEach((Extension extension) => validateExtension(extension, dialplan, model));
}

void validateExtension(Extension extension, DialplanFile currentFile, Freeswitch model) {
  //Check if the extension is empty.
  if (extension.conditions.length == 0) {
    extension.errors.add('Extension: ${extension.name} has no conditions.');
  }

  extension.conditions.forEach((Condition condition) => validateCondition(condition, currentFile, model));
}

void validateCondition(Condition condition, DialplanFile currentFile, Freeswitch model) {
  String receptionNumber = libpath.basenameWithoutExtension(currentFile.filePath);
  if(condition.field != null && condition.field == 'destination_number' && condition.expression != '^$receptionNumber\$') {
    condition.errors.add('Conditions destination_number does not match the file name. expression: ${condition.expression}');
  }

  //Validate Wday
  if(condition.wday != null && !validWday(condition.wday)) {
    condition.errors.add('wday has an error: wday="${condition.wday}"');
  }

  //Validate time-of-day
  if (condition.timeOfDay != null && !validTimeOfDay(condition.timeOfDay)) {
    condition.errors.add('time-of-day has an error: time-of-day="${condition.timeOfDay}"');
  }

  condition.conditions.forEach((Condition condition) => validateCondition(condition, currentFile, model));
  condition.actions.forEach((Action action) => validateAction(action, currentFile, model));
}

void validateAction(Action action, DialplanFile currentFile, Freeswitch model) {
  List<String> knownApplication = ['answer', 'hangup', 'ivr', 'log', 'playback', 'set', 'transfer', 'voicemail'];
  if(!knownApplication.contains(action.application)) {
    action.errors.add('Action has unknown application: "${action.application}"');
  }

  switch(action.application) {
    case 'ivr':
      if(!model.IvrNames().contains(action.data)) {
        action.errors.add('Dialplan action references Ivr menu: "${action.data}" which does not exists');
      }
      break;
    case 'playback':
      //HACK. This is clearly a hack, and may work for reception files.
      String audioPath = action.data.replaceAll(r'${destination_number}', libpath.basenameWithoutExtension(currentFile.filePath));
      //Playback' working directory is the sounds_dir.
      if(!audioPath.contains(r'$${sounds_dir}') || !libpath.isAbsolute(audioPath)) {
        var soundsDir = unfoldVariables(r'$${sounds_dir}');
        audioPath = libpath.join(soundsDir, audioPath);
      }
      if(!fileExists(audioPath)) {
        action.errors.add('Playback action references: ${unfoldVariables(audioPath)} which does not exists.');
      }
      break;
    case 'transfer':
      //Check if extension exists
      break;
    case 'voicemail':
      if(!action.data.startsWith(r'default $${domain} vm-${destination_number}')) {
        action.errors.add('Voicemail action has unknown data format. "${action.data}"');
      }
      break;
  }
}

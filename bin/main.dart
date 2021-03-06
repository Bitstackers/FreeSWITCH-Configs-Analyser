// Copyright (c) 2015, bitstackers. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'package:freeswitch_config_analyzer/freeswitch_config_analyzer.dart';
import 'package:path/path.dart' as path;

import 'package:freeswitch_config_analyzer/model.dart';
import 'package:freeswitch_config_analyzer/conf.dart';

main(List<String> arguments) {
  Freeswitch model = new Freeswitch();

  print('Analysing...');
  model.ivrFiles = readInIvrFiles(path.join(FREESWITCH_DIR, 'conf/ivr_menus'));
  model.dialplanFiles = readInDialplanFiles(path.join(FREESWITCH_DIR, 'conf/dialplan'));

  var IvrErrors = validateIvrMenus(model);
  var DialplanError = validateDialplans(model);

  if (IvrErrors + DialplanError > 0) {
    print('================================');
    print('Number of Dialplan Errors: $DialplanError');
    print('Number of Ivr Errors: $IvrErrors');
  }

  print('Done');
}

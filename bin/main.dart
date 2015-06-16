// Copyright (c) 2015, bitstackers. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:freeswitch_config_analyzer/freeswitch_config_analyzer.dart' as freeswitch_config_analyzer;
import 'package:path/path.dart' as path;

main(List<String> arguments) {
  String freeswitchpath = '/usr/local/freeswitch';

  print('Analysing...');
  freeswitch_config_analyzer.validateIvrMenus(path.join(freeswitchpath, 'conf/ivr_menus'));
  freeswitch_config_analyzer.validateDialplans(path.join(freeswitchpath, 'conf/dialplan'));

  print('Done');
}

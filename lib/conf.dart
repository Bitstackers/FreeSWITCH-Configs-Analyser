library conf;

const String FREESWITCH_DIR = '/usr/local/freeswitch';

Map<String, String> hardcodedVariables =
  {r"$${sounds_dir}": '$FREESWITCH_DIR/sounds'};

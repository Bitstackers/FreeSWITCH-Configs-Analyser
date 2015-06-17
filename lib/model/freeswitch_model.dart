part of model;

class Freeswitch {
  List<IvrFile> ivrFiles;
  List<DialplanFile> dialplanFiles;

  HashSet<String> _IvrNames;
  /**
   * All names get cached, so once this is called will it always return the same thing.
   */
  HashSet<String> IvrNames() {
    if(_IvrNames != null) {
      return _IvrNames;
    }

    _IvrNames = new HashSet<String>();
    for(IvrFile ivrFile in ivrFiles) {
      _IvrNames.addAll(ivrFile.menus.map((IvrMenu menu) => menu.name));
    }

    return _IvrNames;
  }

}

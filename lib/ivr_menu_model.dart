library model;

class IvrFile {
  List<IvrMenu> menus = new List<IvrMenu>();
  List<String> _errors = new List<String>();

  void addError(String error) => _errors.add(error);

  List<String> get errors {
    var list = new List.from(_errors);
    for(IvrMenu menu in menus) {
      list.addAll(menu.errors);
      for(IvrEntry entry in menu.entries) {
        list.addAll(entry.errors);
      }
    }

    return list;
  }
}

class IvrMenu {
  String name;
  String longGreeting;
  String shortGreeting;
  String invalidSound;
  String timeout;
  String maxFailues;
  String maxTimeouts;

  List<IvrEntry> entries = new List<IvrEntry>();
  List<String> errors = new List<String>();
}

class IvrEntry {
  String digits;
  String action;
  String param;

  List<String> errors = new List<String>();
}

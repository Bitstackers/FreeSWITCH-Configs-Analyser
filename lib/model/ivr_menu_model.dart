part of model;

class IvrFile {
  String filePath;
  List<IvrMenu> menus = new List<IvrMenu>();
  List<String> errors = new List<String>();

  List<String> get allErrors {
    var list = new List.from(errors);
    for (IvrMenu menu in menus) {
      list.addAll(menu.errors);
      for (IvrEntry entry in menu.entries) {
        list.addAll(entry.errors);
      }
    }

    return list;
  }

  IvrFile.fromXml(XmlDocument xml) {
    //Checks there is only one top Element
    if (xml.children.where(isNotComment).length != 1) {
      errors.add('It should start with just one include node.');
      return;
    }

    //Checks the first element is an include element
    XmlElement includeNode = xml.children.where(isNotComment).first;
    if (includeNode.name.toString() != 'include') {
      errors.add('It should start with a "include" node. "${includeNode.name}" != "include"');
      return;
    }

    for (XmlNode node in includeNode.children.where(isNotComment)) {
      if (node is XmlElement) {
        XmlElement menuElement = node;
        if (menuElement.name.toString() != 'menu') {
          errors.add('Inside its include node, should only be menu nodes. ${menuElement.name.toString()} != "${menuElement.name.toString()}"');
        } else {
          menus.add(new IvrMenu.fromXml(node));
        }
      } else if (node is XmlText && node.text.trim().length > 0) {
        //This might happend if there are a line-break.
        errors.add('Beside the menus are there other stuff than XmlElements Type:(${node.runtimeType}) Content:[${node}]');
      }
    }
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

  IvrMenu.fromXml(XmlElement xml) {
    if (xml.name.toString() != 'menu') {
      errors.add('File contains elements other than "menu". Elementname: "${xml.name}"');
      return;
    }

    this.name = extractAttributeValue(xml, 'name', errors, required: true);
    this.longGreeting = extractAttributeValue(xml, 'greet-long', errors, required: true);
    this.shortGreeting = extractAttributeValue(xml, 'greet-short', errors);
    this.invalidSound = extractAttributeValue(xml, 'invalid-sound', errors);
    this.timeout = extractAttributeValue(xml, 'timeout', errors);
    this.maxFailues = extractAttributeValue(xml, 'max-failures', errors);
    this.maxTimeouts = extractAttributeValue(xml, 'max-timeouts', errors);

    List<String> knownAttributes = ['name', 'greet-long', 'greet-short', 'invalid-sound', 'timeout', 'max-failures', 'max-timeouts'];
    xml.attributes
      .where((XmlAttribute attribute) => !knownAttributes.contains(attribute.name.toString()))
      .forEach((XmlAttribute attribute) => errors.add('Menu: $name has unknown attribute: ${attribute}'));

    Iterable<XmlElement> elements = xml.children.where((XmlNode node) => node is XmlElement);
    this.entries.addAll(elements.map((XmlElement element) => new IvrEntry.fromXml(element)));
  }
}

class IvrEntry {
  String digits;
  String action;
  String param;

  List<String> errors = new List<String>();

  IvrEntry.fromXml(XmlElement xml) {
    if (xml.name.toString() != 'entry') {
      errors.add('Menu contains elements other than "entry". Elementname: "${xml.name}"');
      return;
    }

    this.action = extractAttributeValue(xml, 'action', errors, required: true);
    this.digits = extractAttributeValue(xml, 'digits', errors, required: true);
    this.param =  extractAttributeValue(xml, 'param', errors);

    List<String> knownAttributes = ['action', 'digits', 'param'];
    xml.attributes
      .where((XmlAttribute attribute) => !knownAttributes.contains(attribute.name.toString()))
      .forEach((XmlAttribute attribute) => errors.add('Entry $xml has unknown attribute: ${attribute}'));
  }
}

String extractAttributeValue(XmlElement xml, String AttributeName, List<String> errors, {bool required: false}) {
  String result;

  Iterable<XmlAttribute> nameElem = xml.attributes.where(
      (XmlAttribute attribute) => attribute.name.toString() == AttributeName);

  if (required && (nameElem == null || nameElem.isEmpty)) {
    errors.add('Missing "<$AttributeName>" attribute');
  } else if (nameElem.length > 1) {
    errors.add('Multiple "<$AttributeName>" attribute');
  } else if (nameElem.isNotEmpty) {
    result = nameElem.first.value;
  }

  return result;
}

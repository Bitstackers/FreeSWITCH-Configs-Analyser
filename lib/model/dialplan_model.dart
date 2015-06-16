part of model;

class DialplanFile {
  String filePath;
  List<Extension> extensions = new List<Extension>();
  List<String> errors = new List<String>();

  List<String> get allErrors {
    var list = new List.from(errors);
    for (Extension menu in extensions) {
      list.addAll(menu.errors);
    }

    return list;
  }

  DialplanFile.fromXml(XmlDocument xml) {
    //Checks there is only one top Element
    if (xml.children.where(isNotComment).length != 1) {
      errors.add('It should start with just one include node.');
      return;
    }

    //Checks the first element is an include element
    XmlElement includeNode = xml.children.where(isNotComment).first;
    if (includeNode.name.toString() != 'include') {
      errors.add(
          'It should start with a "include" node. "${includeNode.name}" != "include"');
      return;
    }

    for (XmlNode node in includeNode.children.where(isNotComment)) {
      if (node is XmlElement) {
        XmlElement menuElement = node;
        String elementName = 'extension';
        if (menuElement.name.toString() != elementName) {
          errors.add('Inside its include node, should only be $elementName nodes. ${menuElement.name.toString()} != "$elementName"');
        } else {
          extensions.add(new Extension.fromXml(node));
        }
      } else if (node is XmlText && node.text.trim().length > 0) {
        //This might happend if there are a line-break.
        errors.add('Beside the menus are there other stuff than XmlElements Type:(${node.runtimeType}) Content:[${node}]');
      }
    }
  }
}

class Extension {
  List<String> errors = new List<String>();

  String name;

  Extension.fromXml(XmlElement xml) {
    this.name = extractAttributeValue(xml, 'name', errors, required: true);
  }
}

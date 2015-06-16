part of model;

class DialplanFile {
  String filePath;
  List<Extension> extensions = new List<Extension>();
  List<String> errors = new List<String>();

  List<String> get allErrors {
    var list = new List.from(errors);
    extensions.forEach((e) => list.addAll(e.allErrors));
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
  List<Condition> conditions = new List<Condition>();

  List<String> get allErrors {
    var list = new List.from(errors);
    conditions.forEach((e) => list.addAll(e.allErrors));
    return list;
  }

  Extension.fromXml(XmlElement xml) {
    String elementName = 'extension';
    if (xml.name.toString() != elementName) {
      errors.add('Inside Files include does it contain elements other than "$elementName". Elementname: "${xml.name}"');
      return;
    }

    this.name = extractAttributeValue(xml, 'name', errors, required: true);

    Iterable<XmlElement> elements = xml.children.where((XmlNode node) => node is XmlElement);
    this.conditions.addAll(elements.map((XmlElement element) => new Condition.fromXml(element)));
  }
}

class Condition {
  List<String> errors = new List<String>();

  List<Action> actions = new List<Action>();
  List<Condition> conditions = new List<Condition>();
  String field;
  String expression;
  String wday;
  String timeOfDay;
  String break_;

  List<String> get allErrors {
    var list = new List.from(errors);
    actions.forEach((e) => list.addAll(e.allErrors));
    conditions.forEach((e) => list.addAll(e.allErrors));
    return list;
  }

  Condition.fromXml(XmlElement xml) {
    this.field = extractAttributeValue(xml, 'field', errors);
    this.expression = extractAttributeValue(xml, 'expression', errors);
    this.wday = extractAttributeValue(xml, 'wday', errors);
    this.timeOfDay = extractAttributeValue(xml, 'time-of-day', errors);
    this.break_ = extractAttributeValue(xml, 'break', errors);

    List<String> knownAttributes = ['field', 'expression', 'wday', 'time-of-day', 'break'];
    xml.attributes
      .where((XmlAttribute attribute) => !knownAttributes.contains(attribute.name.toString()))
      .forEach((XmlAttribute attribute) => errors.add('Condition $xml has unknown attribute: ${attribute}'));

    for(XmlElement element in xml.children.where((XmlNode node) => node is XmlElement)) {
      if(element.name.toString() == 'condition') {
        conditions.add(new Condition.fromXml(element));

      } else if(element.name.toString() == 'action') {
        actions.add(new Action.fromXml(element));

      } else {
        errors.add('Condtion contains unknown element: $element');
      }
    }
  }
}

class Action {
  List<String> errors = new List<String>();

  String application;
  String data;

  List<String> get allErrors => errors;

  Action.fromXml(XmlElement xml) {

  }
}

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:source_gen/source_gen.dart';

class HelperParameterAnnotatedField {
  final DartObject annotation;
  final FieldElement element;

  const HelperParameterAnnotatedField(this.annotation, this.element);

  DartType? get paramAnnotationType => annotation.type;

  String get fieldType => element.type.getDisplayString(withNullability: true);
  String get fieldName => element.name;
}

class HelperArgsConstructorParameter {
  final FieldFormalParameterElement element;

  const HelperArgsConstructorParameter(this.element);
}

class HelperArgsConstructor {
  final ConstructorElement element;
  final List<ParameterElement> params = [];

  HelperArgsConstructor(this.element);

  static String _paramTypeString(ParameterElement element) => element.type.getDisplayString(withNullability: true);
  static String _paramNameString(ParameterElement element) => element.name;

  List<String> get positionalArgs {
    final positionals = params.where((element) => !element.isNamed);
    return positionals.map(_paramTypeString).toList();
  }

  Map<String, String> get namedArgs {
    final named = params.where((element) => element.isNamed);
    return named.fold({}, (map, element) {
      // final useName = ConstantReader(value.annotation).peek('useName')?.stringValue;
      map[_paramNameString(element)] = _paramTypeString(element);
      return map;
    });
  }
}

class WidgetTemplateHelperVistor extends SimpleElementVisitor<void> {
  List<HelperParameterAnnotatedField> _positionalArgAnnotations = [];
  List<HelperParameterAnnotatedField> _namedArgAnnotations = [];
  // Map<String, HelperParameterAnnotatedField> _namedArgParameter = [];
  ConstructorElement? _unnamedConstructor;
  Map<String, HelperArgsConstructor> _helperArgsConstructor = {};

  HelperArgsConstructor? get unnamedConstructor => _helperArgsConstructor[''];

  @override
  void visitConstructorElement(ConstructorElement element) {
    print('Constructor name: ${element.name}');
    _helperArgsConstructor[element.name] = HelperArgsConstructor(element);
    element.visitChildren(this);
  }

  @override
  void visitParameterElement(ParameterElement element) {
    print('Field parameter of ${element.enclosingElement?.name}: ${element.name}');
    _helperArgsConstructor[element.enclosingElement?.name ?? '']!.params.add(element);
  }

  @override
  visitFieldFormalParameterElement(FieldFormalParameterElement element) {
    visitParameterElement(element);
  }

  List<String> get positionalArgs {
    return _positionalArgAnnotations.map((e) => e.fieldType).toList();
  }
  Map<String, NamedParameter> get namedArgs {
    return _namedArgAnnotations.fold({}, (map, value) {
      final useName = ConstantReader(value.annotation).peek('useName')?.stringValue;
      map[value.fieldName] = NamedParameter(value.fieldType, useName ?? value.fieldName);
      return map;
    });
  }
}

class NamedParameter {
  final String type;
  final String? useName;

  const NamedParameter(this.type, this.useName);
}

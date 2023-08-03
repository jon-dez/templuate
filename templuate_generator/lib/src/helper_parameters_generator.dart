import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'helper_args.dart';
import 'visitors/template_helper_visitor.dart';

// TODO: Import package:templuate/evaluable.dart

class HelperParametersGenerator extends GeneratorForAnnotation<HelperArgs> {
  @override
  String generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    if(element is ClassElement) {
      final className = element.name;
      print('heheofji ${className.runtimeType}');
      final visitor = WidgetTemplateHelperVistor();
      element.visitChildren(visitor);
      final StringBuffer buffer = StringBuffer();
      final genClassName = '${className}Evaluable';
      final unnamedConstructor = visitor.unnamedConstructor;
      if(unnamedConstructor == null) return '';

      final posArgs = unnamedConstructor.positionalArgs;
      // capitalize(String str) => str[0].toUpperCase() + str.substring(1);
      final namedArgs = unnamedConstructor.namedArgs;

      buffer.writeln('class $genClassName implements Evaluable<$className> {');
      
      
      genClassFields(buffer, posArgs, namedArgs);

      genClassConstructor(buffer, genClassName, posArgs, namedArgs);

      genClassFactoryConstructor(buffer, genClassName, posArgs, namedArgs);

      genClassEvalOverride(buffer, className, posArgs, namedArgs);

      buffer.writeln('}');
      return buffer.toString();
    }
    return throw Exception('$HelperParametersGenerator: $element is not a `$ClassElement`');
  }

  String removeNullability(bool nullable, String type) => nullable
        ? type.substring(0, type.length-1)
        : type;

  void genClassFields(StringBuffer buffer, List<String> posArgs, Map<String, String> namedArgs) {
    fieldLine(String type, String fieldName) {
      final nullable = type.endsWith('?');
      buffer.writeln('final Evaluable<${removeNullability(nullable, type)}>${nullable ? '?' : ''} $fieldName;');
    }

    for (var i = 0; i < posArgs.length ; i++) {
      fieldLine(posArgs[i], 'pos$i');
    }

    for (var namedArg in namedArgs.entries) {
      fieldLine(namedArg.value, namedArg.key);
    }
  }

  void genClassConstructor(StringBuffer buffer, String genClassName, List<String> posArgs, Map<String, String> namedArgs) {
    final numArgs = posArgs.length + namedArgs.length;
    buffer.write('const $genClassName(');
    {
      var i = 0;
      for(; i < posArgs.length; i++) {
        buffer.write('this.pos$i');
        if(i != numArgs - 1) buffer.write(', ');
      }

      if(namedArgs.isNotEmpty) {
        buffer.write('{');
        for (var name in namedArgs.entries) {
          buffer.write('required this.${name.key}');
          if(i != numArgs - 1) buffer.write(', ');
          i++;
        }
        buffer.write('}');
      }
    }
    buffer.write(');');
  }

  String argumentCastString(bool positional, String arg, String type) {
    typeCast(String baseType) {
      switch(baseType) {
        case 'String':
          return '.asString()';
        case 'bool':
          return '.asBool()';
        case 'dynamic':
          return '.as()'; // Essentially casts as dynamic.
        case 'num':
          return '.asNum()';
        case 'double':
          return '.asDouble()';
        case 'int':
          return '.asInt()';
        default:
          if(baseType.startsWith('List') && baseType.contains('<')) {
            // Is a generic list type.
            return '.asList()';
          }
          throw Exception('Argument of type `$baseType` not allowed.');
      }
    }
    final nullable = type.endsWith('?');
    return '${nullable ? 'optional' : (positional ? 'positional' : 'named' )}($arg)${nullable ? 
    '?' : ''}${
        typeCast(removeNullability(nullable, type))
    }';
  }

  void genClassFactoryConstructor(StringBuffer buffer, String genClassName, List<String> posArgs, Map<String, String> namedArgs) {
    final numArgs = posArgs.length + namedArgs.length;
    // TODO: Use import for type HelperParameters and $ formatting.
    buffer.writeln('factory $genClassName.fromArguments(HelperParameters arguments) {');
    buffer.writeln('return $genClassName(');
    {
      var i = 0;
      for(; i < posArgs.length; i++) {
        buffer.write('arguments.${argumentCastString(true, '$i', posArgs[i])}');
        if(i != numArgs - 1) buffer.write(', ');
      }
      for (var name in namedArgs.entries) {
        buffer.write("${name.key}: arguments.${argumentCastString(false, "'${name.key}'", name.value)}");
        if(i != numArgs - 1) buffer.write(', ');
        i++;
      }
    }
    buffer.writeln(');');
    buffer.writeln('}');
  }

  void genClassEvalOverride(StringBuffer buffer, String className, List<String> posArgs, Map<String, String> namedArgs) {
    final numArgs = posArgs.length + namedArgs.length;
    // TODO: Use import for type WidgetTemplateVariablesContext and $ formatting.
    buffer.writeln('@override\n$className eval(WidgetTemplateVariablesContext variablesContext) {');
    eval(String type, String fieldName) {
      final nullable = type.endsWith('?');
      buffer.write('$fieldName${nullable ? '?' : ''}.eval(variablesContext)');
    }
    buffer.writeln('return $className(');
    {
      var i = 0;
      for(; i < posArgs.length; i++) {
        eval(posArgs[i], 'pos$i');
        if(i != numArgs - 1) buffer.write(', ');
      }
      for (var name in namedArgs.entries) {
        buffer.write('${name.key}: ');
        eval(name.value, name.key);
        if(i != numArgs - 1) buffer.write(', ');
        i++;
      }
    }
    buffer.writeln(');');
    buffer.writeln('}');
  }
}

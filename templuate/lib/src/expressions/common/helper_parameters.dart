
import '../bracket_arguments/identifier_args/helper_function_or_variable.dart';
import '../bracket_arguments/identifier_args/path_identifier_arg.dart';
import '../../compiler.dart';
import '../../variables.dart';
import '../arguments.dart';
import '../bracket_argument.dart';
import '../evaluable.dart';
import 'helper_function.dart';

class HelperParameter {
  /// TODO: [_linker] is used only for accessing custom nested helper functions, consider replacing this member with 
  final TemplateLinker _linker;
  final BracketArgument _argument;
  const HelperParameter(
    this._argument,
    this._linker,
  );
  
  Evaluable<bool> asBool() {
    return _evaluableArgFromBracketArg<bool>(_argument);
  }

  Evaluable<int> asInt() {
    return _evaluableArgFromBracketArg<int>(_argument);
  }

  Evaluable<double> asDouble() {
    return _evaluableArgFromBracketArg<double>(_argument);
  }

  Evaluable<List> asList() {
    return _evaluableArgFromBracketArg<List>(_argument);
  }

  Evaluable<num> asNum() {
    return _evaluableArgFromBracketArg<num>(_argument);
  }

  Evaluable<T> as<T>() {
    return _evaluableArgFromBracketArg<T>(_argument);
  }

  Evaluable<T> asBoundNestedHelperFnArg<T>() {
    final argument = _argument;
    if (argument is! NestedHelperFnArg) {
      throw Exception(
          'The argument is not a $NestedHelperFnArg.');
    }
    final boundFn = argument.bind<T>(_linker);
    return boundFn as Evaluable<T>;
  }

  Evaluable<String> asString() {
    return _evaluableArgFromBracketArg<String>(_argument);
  }

  LayoutVariableRef asVariableRef() {
    final argument = _argument;
    if (argument is! LayoutVariableRef) {
      throw Exception('`$_argument` is not a variable reference.');
    }
    return argument;
  }

  Evaluable<T> _evaluableArgFromBracketArg<T>(BracketArgument argument) {
    if (argument is LiteralArg<T>) {
      return argument;
    } else if (argument is IdentifierArg) {
      if (argument is PathIdentifierArg) {
        return argument.cast();
      } else if (argument is HelperFunctionOrVariableRef) {
        return NestedHelperFnArg(argument.asFunction()).tryBind<T>(_linker) as Evaluable<T>?
          ?? argument.asVariableRef<T>();
      }
      throw Exception('`${argument.identifier}` could not be represented as `$T`');
    } else if (argument is NestedHelperFnArg) {
      return argument.bind<T>(_linker) as Evaluable<T>;
    }
    throw Exception(
        '`${argument.runtimeType}` could not be converted to a $Evaluable of type $T');
  }
}

/// TODO: Rename [HelperParameters] to [HelperArguments]
class HelperParameters {
  final HelperFunction _function;
  final TemplateLinker _linker;
  const HelperParameters(
    this._function,
    this._linker,
  );

  String get functionName => _function.name;

  static T _getTemplate<T>(param, T Function(int) positionalFn, T Function(String) namedFn) {
     switch (param.runtimeType) {
      case int:
        return positionalFn(param as int);
      case String:
        return namedFn(param as String);
      default:
        throw Exception('Cannot look up parameter.');
    }
  }

  HelperParameter _requiredArg(BracketArgument? arg, Exception exception) {
    if(arg == null) {
      throw exception;
    }
    return HelperParameter(arg, _linker);
  }

  /// Convenience function to get parameter by its position or name.
  HelperParameter operator [](param) => _getTemplate(param, positional, named);

  void expectNotEmpty() {
    if (_function.args.isEmpty) {
      throw Exception('The `${_function.name}` helper expects argument(s).');
    }
  }

  HelperParameter? optional(param) {
    final arg = _get(param);
    if (arg == null) {
      return null;
    }
    return HelperParameter(arg, _linker);
  }

  HelperParameter positional(int index) => _requiredArg(
    _positional(index),
    Exception(
          'Helper function `${_function.name}` expected a positional argument at `$index`.')
  );

  BracketArgument? _get(param) => _getTemplate(param, _positional, _named);

  BracketArgument? _positional(int index) => index >= _function.args.length
    ? null
    : _function.args[index];

  HelperParameter named(String name) => _requiredArg(
    _named(name),
    Exception(
          'Helper function `${_function.name}` expected a named argument `$name`.')
  );

  BracketArgument? _named(String name) => _function.namedArgs[name];

  int get positionalArgLength => _function.args.length;

  Iterable<String> get namedArgs => _function.namedArgs.keys;
}

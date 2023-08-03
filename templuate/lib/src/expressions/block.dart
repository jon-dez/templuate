import 'arguments/bracket_argument.dart';
import 'common/helper_function.dart';
import 'brackets.dart';
import 'expression.dart';

class BlockExpression implements ValidatedExpression {
  final HelperFunction function;
  final List<ValidatedExpression> children;

  const BlockExpression(this.function, {
    this.children = const []
  });

  const BlockExpression.withChildren({
    required this.function,
    required this.children
  });

  @override
  String toString() {
    return '$function\n${children.map((e) => e.toString()).join(' ')}';
  }

  OpenBracket get open => OpenBracket(function);

  CloseBracket get close => CloseBracket(function.name);
  
  @override
  String get expression => '${open.expression}${children.map((e) => e.expression).join()}${close.expression}';
}

BlockExpression blockExpression({
  required String identifier,
  List<BracketArgument> args = const [],
  List<ValidatedExpression> children = const []
}) {
  return BlockExpression.withChildren(
    function: HelperFunction(identifier, args: args),
    children: children
  );
}
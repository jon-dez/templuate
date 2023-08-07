import 'package:templuate/src/expressions/brackets/close_bracket.dart';
import 'package:templuate/src/expressions/brackets/open_bracket.dart';

import 'bracket_argument.dart';
import 'common/helper_function.dart';
import 'bracket_expression.dart';
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

  BracketExpression get open => BracketExpression(OpenBracketArgs(function));

  BracketExpression get close => BracketExpression(CloseBracketArgs(function.name));
  
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
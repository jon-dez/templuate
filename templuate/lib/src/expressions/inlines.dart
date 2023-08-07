import 'package:templuate/src/expressions/bracket_arguments/literal.dart';
import 'package:templuate/src/variables.dart';

import 'common/helper_function.dart';
import 'bracket_expression.dart';
import 'evaluable.dart';
import 'expression.dart';

final class InlineBracket extends BracketExpression implements ValidatedExpression {
  const InlineBracket(super.args);
}

class EvaluableArgumentExpressionContent<T extends EvaluableArgument> implements ExpressionContent {
  final T evaluble;

  const EvaluableArgumentExpressionContent(this.evaluble);
  
  @override
  String get content => evaluble.argString;
}

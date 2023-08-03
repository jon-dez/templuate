import 'common/helper_function.dart';
import 'expression.dart';

/// An [Expression] with its [Expression.expression] returning [content] surrounded by brackets.
abstract class BracketExpression implements Expression {
  const BracketExpression();
  String get content;
  @override
  String get expression => '{{$content}}';
}

class OpenBracket extends BracketExpression {
  final HelperFunction function;
  const OpenBracket(this.function);
  
  @override
  String get content => '#$function';
}

class CloseBracket extends BracketExpression {
  final String name;
  const CloseBracket(this.name);
  
  @override
  String get content => '/$name';
}

import 'expression.dart';

/// An [Expression] with its [Expression.expression] returning [content] surrounded by brackets.
base class BracketExpression implements Expression {
  final ExpressionContent content;
  
  const BracketExpression(this.content);

  @override
  String get expression => '{{${content.content}}}';
}

import 'expression.dart';

class TextExpression implements ValidatedExpression {
  final String text;
  const TextExpression(this.text);
  
  @override
  String get expression => text;
}

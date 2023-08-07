import 'package:templuate/src/expressions/expression.dart';

class CloseBracketArgs implements ExpressionContent {
  final String name;
  const CloseBracketArgs(this.name);
  
  @override
  String get content => '/$name';
}

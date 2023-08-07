import 'package:templuate/src/expressions/expression.dart';

import '../common/helper_function.dart';

class OpenBracketArgs implements ExpressionContent {
  final HelperFunction function;

  const OpenBracketArgs(this.function);

  @override
  String get content => '#$function';
}

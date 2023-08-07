import 'package:templuate/src/expressions/bracket_arguments/identifier_args/path_identifier_arg.dart';

import '../../../variables.dart';
import '../../common/helper_function.dart';
import '../../expression.dart';
import '../identifier.dart';

class HelperFunctionOrVariable implements ExpressionContent, IdentifierArg {
  @override
  final String identifier;
  const HelperFunctionOrVariable(this.identifier);

  HelperFunction asFunction() => HelperFunction(identifier, args: []);
  LayoutVariableRef<T> asVariableRef<T>() => PathIdentifierArg([identifier]);
  
  @override
  String get content => identifier;
  
  @override
  String get argString => identifier;
}

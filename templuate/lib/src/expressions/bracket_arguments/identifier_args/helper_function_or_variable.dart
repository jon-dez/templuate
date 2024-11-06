import 'package:templuate/src/expressions/bracket_arguments/identifier_args/path_identifier_arg.dart';

import '../../../variables.dart';
import '../../common/helper_function.dart';
import '../../expression.dart';
import '../identifier.dart';

/// An [ExpressionContent] that is also an [IdentifierArg].
///
/// This is an ambiguous definition since a helper function that takes in no parameters and a variable reference can be identified by this definition.
/// The only thing we can do is check if a helper function that is identified by [identifier] exists in the template linker,
/// and if not we can consider it a reference to a variable in some context during runtime.
///
class HelperFunctionOrVariableRef implements ExpressionContent, IdentifierArg {
  final PathIdentifierArg pathIdentifierArg;
  const HelperFunctionOrVariableRef(this.pathIdentifierArg);

  HelperFunction asFunction() => HelperFunction(identifier, args: []);
  LayoutVariableRef<T> asVariableRef<T>() => pathIdentifierArg.cast();
  
  @override
  String get identifier => pathIdentifierArg.identifier;

  @override
  String get content => identifier;

  @override
  String get argString => identifier;
}

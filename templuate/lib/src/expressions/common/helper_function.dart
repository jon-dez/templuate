import 'package:templuate/src/expressions/expression.dart';

import '../bracket_argument.dart';

/// TODO: Rename [HelperFunction] to [HelperFunctionCall]
/// - Rationale: This represents an invocation to a helper function.
class HelperFunction implements ExpressionContent {
  final String name;
  final List<BracketArgument> args;
  final Map<String, BracketArgument> namedArgs;

  const HelperFunction(this.name,{
    required this.args,
    this.namedArgs = const {},
  });

  @override
  String toString() {
    final positionalArgsString = args.map((e) => e.argString).join(' ');
    final namedArgsString = namedArgs.entries.map((e) => '${e.key}=${e.value.argString}').join(' ');
    return [
      name,
      if(positionalArgsString.isNotEmpty)
        positionalArgsString,
      if(namedArgsString.isNotEmpty)
        namedArgsString
    ].join(' ');
  }
  
  @override
  String get content => toString();
}

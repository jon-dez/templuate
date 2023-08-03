import '../arguments/bracket_argument.dart';
import '../arguments/identifier.dart';

class HelperFunction {
  final String name;
  final List<BracketArgument> args;
  final Map<String, BracketArgument> namedArgs;

  const HelperFunction(this.name,{
    required this.args,
    this.namedArgs = const {},
  });

  /// [args] must not be empty.
  factory HelperFunction.fromBracketArgs(List<BracketArgument> args) {
    final nestedArgsIdentifier = expectHelperIdentifier(args[0], 'helper function');
    return HelperFunction(nestedArgsIdentifier.identifier, args: args.sublist(1));
  }

  @override
  String toString() {
    final positionalArgsString = args.map((e) => e.value).join(' ');
    final namedArgsString = namedArgs.entries.map((e) => '${e.key}=${e.value.value}').join(' ');
    return [
      name,
      if(positionalArgsString.isNotEmpty)
        positionalArgsString,
      if(namedArgsString.isNotEmpty)
        namedArgsString
    ].join(' ');
  }
}


IdentifierArg expectHelperIdentifier(BracketArgument bracketArgument, String errorHelper) {
  if (bracketArgument is! IdentifierArg) {
    throw Exception('The $errorHelper must start with an identifier. Got ${bracketArgument.runtimeType}');
  }
  if (bracketArgument.identifier.contains('.')) {
    throw Exception('The $errorHelper identifier cannot be a variable identifier.');
  }
  return bracketArgument;
}

import 'bracket_argument.dart';

class IdentifierArg extends BracketArgument {
  final String identifier;
  const IdentifierArg(this.identifier);
  
  @override
  String get value => identifier;
}

class PathIdentifierArg extends BracketArgument implements IdentifierArg {
  final bool fromParentPath;
  final List<String> paths;

  const PathIdentifierArg(this.paths, {
    this.fromParentPath = false,
  });

  const PathIdentifierArg.currentPath() : paths = const [], fromParentPath = false;

  /// Determines whether [PathIdentifierArg] can not be known to be a helper or variable before runtime.
  /// 
  /// If `false`, then [PathIdentifierArg] can only be a variable.
  /// If `true`, then [PathIdentifierArg] can be either a helper or a variable.
  bool get isAmbiguousIdentifier => !(fromParentPath || paths.isEmpty);

  bool get identifiesCurrentPath => !fromParentPath && paths.isEmpty;

  List<String> get fullPath => identifiesCurrentPath
    ? ['.']
    : [if(fromParentPath) '../', ...paths];

  @override
  String get identifier => identifiesCurrentPath
    ? '.'
    : [if(fromParentPath) '../', paths.join('.')].join();
  
  @override
  String get value => identifier;
}

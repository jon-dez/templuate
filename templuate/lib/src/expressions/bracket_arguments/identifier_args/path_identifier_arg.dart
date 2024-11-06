import '../../../variables.dart';
import '../identifier.dart';

class PathIdentifierArg<T> extends LayoutVariableRef<T>
    implements IdentifierArg {
  final bool fromParentPath;
  final List<String> paths;

  const PathIdentifierArg(
    this.paths, {
    this.fromParentPath = false,
  });

  const PathIdentifierArg.currentPath()
      : paths = const [],
        fromParentPath = false;

  /// Determines whether [PathIdentifierArg] can not be known to be a helper or variable before runtime.
  ///
  /// If `false`, then [PathIdentifierArg] can only be a variable.
  /// If `true`, then [PathIdentifierArg] can be either a helper or a variable.
  bool get isAmbiguousIdentifier => !(fromParentPath || paths.isEmpty);

  bool get identifiesCurrentPath => !fromParentPath && paths.isEmpty;

  List<String> get fullPath =>
      identifiesCurrentPath ? ['.'] : [if (fromParentPath) '../', ...paths];

  @override
  String get argString => identifiesCurrentPath
      ? '.'
      : [if (fromParentPath) '../', paths.join('.')].join();

  @override
  VariableSelector get selector => identifiesCurrentPath
      ? const CurrentContextSelector()
      : VariablePathSelector(fullPath);

  @override
  String get identifier => argString;

  @override
  LayoutVariableRef<U> cast<U>() {
    return PathIdentifierArg(paths, fromParentPath: fromParentPath);
  }
}

class CurrentContextSelector implements VariableSelector {
  const CurrentContextSelector();
  @override
  get(WidgetTemplateVariablesContext context) {
    return context.variables.select((data) => data);
  }

  @override
  String toString() {
    return '$CurrentContextSelector';
  }
}

class VariablePathSelector implements VariableSelector {
  static const pathToken = '.';
  final List<String> segments;
  const VariablePathSelector(this.segments);
  factory VariablePathSelector.fromString(String path) {
    // if(!path.startsWith(pathToken)) {
    //   throw Exception('A $VariableDepthSelector must begin with `$pathToken`');
    // }
    return VariablePathSelector(path.split(pathToken));
  }

  /// TODO: Go into the parent context if `../` is found
  /// TODO: If segments.length == 1, and segment == '.', then return the original context.
  @override
  get(context) {
    return context.variables.select((data) {
      var curr = data;
      for (var seg in segments) {
        final map = Map<String, dynamic>.from(curr);
        if (!map.containsKey(seg)) {
          throw Exception(
              '`$this` selects an undefined variable `$seg`. Consider defining `$variableRef`.\n'
              'Context data: $data');
        }
        curr = map[seg];
        if (curr == null) {
          return null;
        }
      }
      return curr;
    });
  }

  bool get isEmpty => segments.isEmpty;

  String get variableRef => segments.join('.');

  @override
  String toString() {
    // return '$pathToken${segments.join(pathToken)}';
    return '$VariablePathSelector: $variableRef';
  }
}

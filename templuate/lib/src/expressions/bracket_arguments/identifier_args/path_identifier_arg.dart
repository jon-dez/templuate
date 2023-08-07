import '../../../variables.dart';
import '../identifier.dart';

class PathIdentifierArg<T> extends LayoutVariableRef<T> implements IdentifierArg {
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
  String get argString => identifiesCurrentPath
    ? '.'
    : [if(fromParentPath) '../', paths.join('.')].join();
  
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
    return context.data;
  }

  @override
  String toString() {
    return '$CurrentContextSelector';
  }
}

/// Select a variable named [name] in the current context.
class NamedSelector implements VariableSelector {
  final String name;

  const NamedSelector(this.name);

  @override
  get(WidgetTemplateVariablesContext context) {
    return context.data[name];
  }

  @override
  String toString() {
    return '$NamedSelector: $name';
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
    var curr = context.data;
    for (var seg in segments) {
      curr = curr[seg];
      if(curr == null) {
        return null;
      }
    }
    return curr;
  }

  bool get isEmpty => segments.isEmpty;

  @override
  String toString() {
    // return '$pathToken${segments.join(pathToken)}';
    return '$VariablePathSelector: ${segments.join('.')}';
  }
}

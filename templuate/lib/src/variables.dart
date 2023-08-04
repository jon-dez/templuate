import 'package:flutter/foundation.dart';
import './nodes/evaluable.dart';
import 'expressions/arguments/bracket_argument.dart';
import 'expressions/arguments/identifier.dart';
import 'expressions/arguments/literal.dart';

class WidgetTemplateVariablesContext<T> {
  /// The variables context that this context is nested in.
  /// 
  /// This variables context could be nested when inside a loop.
  final WidgetTemplateVariablesContext? parent;
  final T data;
  const WidgetTemplateVariablesContext(this.data, [this.parent]);

  /// Create a new [WidgetTemplateVariablesContext] with this as the parent using new [data] in its context.
  WidgetTemplateVariablesContext childContext(final data) {
    return WidgetTemplateVariablesContext(data, this);
  }

  @override
  String toString() {
    return data.toString();
  }
}

/// A constant that will not change for every variant of data used in a layout.
class LayoutLiteral<T> implements EvaluableArgument<T> {
  final T value;
  const LayoutLiteral(this.value);

  @override
  eval(data) {
    return value;
  }
  
  @override
  BracketArgument toBracketArgument() {
    return LiteralArg.from(value);
  }
  
  @override
  Type get evaluatedType => T;
}

/// A variable that depends on data used within a layout.
class LayoutVariableRef<T> implements EvaluableArgument<T> {
  final VariableSelector selector;

  /// TODO: Remove this or make private and use within a factory constructor.
  LayoutVariableRef(List<String> path) : selector = VariablePathSelector(path);

  LayoutVariableRef.currentContext() : selector = const CurrentContextSelector();

  @override
  eval(final WidgetTemplateVariablesContext context) {
    final data = selector.get(context);
    if(data is! T) {
      debugPrint('$LayoutVariableRef: $selector / $data / $context');
      throw Exception('`$runtimeType` selected by `$selector` is not type of `$T`');
    }
    return data;
  }

  @override
  BracketArgument toBracketArgument() {
    return IdentifierArg(selector.toString());
  }
  
  @override
  Type get evaluatedType => T;
}

abstract class VariableSelector {
  get(final WidgetTemplateVariablesContext context);
}

class CurrentContextSelector implements VariableSelector {
  const  CurrentContextSelector();
  @override
  get(WidgetTemplateVariablesContext context) {
    return context.data;
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

import 'package:flutter/foundation.dart';
import 'expressions/evaluable.dart';

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

/// A variable that depends on data used within a layout.
abstract class LayoutVariableRef<T> implements EvaluableArgument<T> {
  const LayoutVariableRef();

  VariableSelector get selector;

  @override
  eval(final WidgetTemplateVariablesContext context) {
    final data = selector.get(context);
    if(data is! T) {
      debugPrint('$LayoutVariableRef: $selector / $data / $context');
      throw Exception('`$runtimeType` selected by `$selector` is not type of `$T`');
    }
    return data;
  }

  LayoutVariableRef<U> cast<U>();
}

abstract class VariableSelector {
  get(final WidgetTemplateVariablesContext context);
}

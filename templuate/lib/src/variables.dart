import 'package:flutter/foundation.dart';
import 'expressions/evaluable.dart';

class WidgetTemplateVariablesContext {
  /// The variables context that this context is nested in.
  ///
  /// This variables context could be nested when inside a loop.
  final WidgetTemplateVariablesContext? parent;
  final ContextVariables variables;
  WidgetTemplateVariablesContext(dynamic data, [this.parent])
      : variables = DynamicVariablesContext(data);
  const WidgetTemplateVariablesContext.fromContextVariables(this.variables,
      [this.parent]);

  /// Create a new [WidgetTemplateVariablesContext] with this as the parent using new [data] in its context.
  WidgetTemplateVariablesContext childContext(final data) {
    return WidgetTemplateVariablesContext(data, this);
  }

  /// Create a new [WidgetTemplateVariablesContext] that wraps [variables] in a [StringifiedVariablesContext].
  WidgetTemplateVariablesContext stringifiedContext() {
    return WidgetTemplateVariablesContext.fromContextVariables(
        StringifiedVariablesContext(variables), parent);
  }

  @override
  String toString() {
    return variables.toString();
  }
}

mixin ContextVariables<T> {
  T select<U>(U Function(dynamic data) callback);
}

class DynamicVariablesContext with ContextVariables {
  final dynamic data;

  const DynamicVariablesContext(this.data);

  @override
  select<U>(U Function(dynamic data) callback) => callback(data);
}

/// Stringifies the variables in [variables] whenever they are selected from the callback provided to [select].
class StringifiedVariablesContext with ContextVariables<String> {
  final ContextVariables variables;

  const StringifiedVariablesContext(this.variables);

  @override
  String select<U>(U Function(dynamic data) callback) =>
      variables.select(callback).toString();
}

/// A variable that depends on data used within a layout.
abstract class LayoutVariableRef<T> implements EvaluableArgument<T> {
  const LayoutVariableRef();

  VariableSelector get selector;

  @override
  eval(final WidgetTemplateVariablesContext context) {
    final data = selector.get(context);
    if (data is! T) {
      debugPrint('$LayoutVariableRef: $selector / $data / $context');
      throw Exception(
          '`$runtimeType` selected by `$selector` is not type of `$T` (got `${data.runtimeType}`)\n'
          '$LayoutVariableRef: $selector / $data / $context');
    }
    return data;
  }

  LayoutVariableRef<U> cast<U>();
}

abstract class VariableSelector {
  get(final WidgetTemplateVariablesContext context);
}

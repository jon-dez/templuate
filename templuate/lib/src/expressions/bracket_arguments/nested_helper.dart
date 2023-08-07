import 'package:flutter/foundation.dart';
import 'package:templuate/templuate.dart';

import '../../nodes/conditional.dart';

typedef CustomNestedHelperFn<T> = EvaluableFn<T> Function(
    HelperParameters arguments);

/// TODO: Rename to [NestedHelper] to [CustomNestedHelper]
class NestedHelper<T> {
  final CustomNestedHelperFn<T> helper;
  NestedHelper(this.helper);

  Type get returnType => T;
}

class BoundNestedHelperFnArg<T> extends NestedHelperFnArg implements Evaluable<T> {
  final T Function(WidgetTemplateVariablesContext context) evaluableFn;

  const BoundNestedHelperFnArg._(super.function, this.evaluableFn);

  @override
  eval(WidgetTemplateVariablesContext context) => evaluableFn(context);
}

class NestedHelperFnArg implements BracketArgument {
  final HelperFunction function;

  const NestedHelperFnArg(this.function);

  @override
  String get argString => '($function)';

  /// Bind a [HelperFunction] (invocation) to a built-in nested helper, or a custom one if it exists in [TemplateLinker].
  Evaluable bind<T>(TemplateLinker linker) {
    return tryBind<T>(linker) ?? (throw Exception('The custom nested helper `${function.name}` was not found.'));
  }

  Evaluable? tryBind<T>(TemplateLinker linker) {
    final identifier = function.name;
    final parameters = HelperParameters(function, linker);

    switch(identifier) {
      case 'each':
        final eachIterable = parameters.positional(0).asList();
        final eachNestedHelper = parameters.positional(1).asBoundNestedHelperFnArg();
        return BoundNestedHelperFnArg<List>._(function, (context){
          final eachEvals = eachIterable.eval(context)
            .map((iterationElement) {
              final newContext = context.childContext(iterationElement);
              return eachNestedHelper.eval(newContext);
            });
          return eachEvals.toList();
        });
      case 'debugPrint':
        final printObject = parameters.positional(0).as();
        return BoundNestedHelperFnArg<void>._(function, (context) {
          final printedObject = printObject.eval(context);
          debugPrint('[Templating(debugPrint)]: $printedObject');
        });
      case 'hasElement':
        final varRef = parameters[0].asVariableRef();
        return LayoutConditionStatement.hasElement(varRef);
    }
    final customHelper = linker.findCustomNestedHelperOrNull<T>(identifier);
    if(customHelper == null) {
      return null;
    }
    return BoundNestedHelperFnArg<T>._(function, customHelper.helper(parameters));
  }
}

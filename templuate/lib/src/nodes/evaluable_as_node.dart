import '../expressions/evaluable.dart';
import '../variables.dart';

/// A node that renders the value of [evaluable] into the template.
class EvaluableAsNode<T> implements EvaluableNode<T> {
  final Evaluable<T> evaluable;

  const EvaluableAsNode(this.evaluable);

  @override
  T eval(WidgetTemplateVariablesContext context) => evaluable.eval(context);
}

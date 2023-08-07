import '../expressions/evaluable.dart';
import '../variables.dart';

/// Calls [Evaluable.toString] on [evaluable].
class EvaluableToString implements Evaluable<String> {
  final Evaluable evaluable;
  const EvaluableToString(this.evaluable);
  @override
  String eval(WidgetTemplateVariablesContext context) {
    return evaluable.eval(context).toString();
  }
}

/// TODO: Perhaps rename [FreeTextNode] to [FreeTextNode], and extend from [EvaluableNode]<[String]> instead in order to remove dependency from widgets.
class FreeTextNode implements EvaluableNode<String> {
  final Evaluable<String> text;
  const FreeTextNode(this.text);

  factory FreeTextNode.evaluableToString(Evaluable evaluable) {
    return FreeTextNode(EvaluableToString(evaluable));
  }
  
  @override
  String eval(WidgetTemplateVariablesContext context) => text.eval(context);
}

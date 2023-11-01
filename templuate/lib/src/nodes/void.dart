import '../expressions/evaluable.dart';
import '../variables.dart';
import 'helpers.dart';
import 'node.dart';

/// Evaluates everything, returns nothing.
class VoidNode implements EvaluableNode {
  final List<Evaluable> args;
  final List<TemplateNode> children;
  const VoidNode(this.args, this.children);
  
  @override
  List<TemplateNode> eval(WidgetTemplateVariablesContext context) {
    for (var element in args) {
      element.eval(context);
    }
    evaluateAll(children, context);
    return [];
  }
}

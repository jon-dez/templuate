import 'nodes/conditional.dart';
import 'nodes/evaluable.dart';
import 'nodes/node.dart';
import 'variables.dart';

LayoutConditionStatement hasElement(LayoutVariableRef varRef) => LayoutConditionStatement.hasElement(varRef);

LayoutLiteral<T> varLiteral<T>(value) => LayoutLiteral<T>(value);
LayoutVariableRef<T> varReference<T>(List<String> refPath) => LayoutVariableRef<T>(refPath);

Evaluable<List<WidgetTemplateNode>> makeNodeListEvaluable(List<WidgetTemplateNode> nodes) {
  return WidgetTemplateNodeListConstant(nodes);
}

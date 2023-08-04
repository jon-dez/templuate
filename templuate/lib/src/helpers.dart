import 'nodes/conditional.dart';
import 'nodes/evaluable.dart';
import 'variables.dart';

LayoutConditionStatement hasElement(LayoutVariableRef varRef) => LayoutConditionStatement.hasElement(varRef);

LayoutLiteral<T> varLiteral<T>(value) => LayoutLiteral<T>(value);
LayoutVariableRef<T> varReference<T>(List<String> refPath) => LayoutVariableRef<T>(refPath);

Evaluable<List<EvaluableNode>> makeNodeListEvaluable(List<EvaluableNode> nodes) {
  return EvaluableNodeListConstant(nodes);
}

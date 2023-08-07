import 'expressions/evaluable.dart';

Evaluable<List<EvaluableNode>> makeNodeListEvaluable(List<EvaluableNode> nodes) {
  return EvaluableNodeListConstant(nodes);
}

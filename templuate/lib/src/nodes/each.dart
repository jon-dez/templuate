import 'package:templuate/src/nodes/helpers.dart';

import '../variables.dart';
import 'context_change.dart';
import 'evaluable.dart';

class EachNode<Data> extends EvaluableNode {
  final LayoutVariableRef iterableRef;
  final Evaluable<List<EvaluableNode>> nodeList;
  
  const EachNode({
    required this.iterableRef,
    required this.nodeList,
  });

  @override
  List<EvaluableNode> eval(WidgetTemplateVariablesContext context) {
    final iterable = iterableRef.eval(context);
    return iterable is! Iterable
      ? throw Exception('There is no iterable at ${iterableRef.toString()}')
      : List.from(Iterable.castFrom(iterable).map<EvaluableNode>((e) {
          return EachIteration(
            data: e,
            nodeList: nodeList
          );
        }));
  }
}


class EachIteration<Index, Data> extends EvaluableNode {
  // final Index index;
  final Data data;
  final Evaluable<List<EvaluableNode>> nodeList;

  const EachIteration({
    // required this.index,
    required this.data,
    required this.nodeList
  });
  
  /// TODO: implement modifyContext by allowing [index] to be passed to the new context.
  @override
  List<EvaluableNode> eval(WidgetTemplateVariablesContext context) {
    return evaluateAll(nodeList.eval(context), context).map(
      (e) => ContextChangeNode(
        data: data,
        content: e
      )).toList();
  }
}

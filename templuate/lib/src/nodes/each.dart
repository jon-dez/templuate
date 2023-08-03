import '../variables.dart';
import 'context_change.dart';
import 'evaluable.dart';
import 'node.dart';

class EachNode<Data> extends EvaluableNode {
  final LayoutVariableRef iterableRef;
  @override
  final EvaluableNodeList nodeList;
  
  const EachNode({
    required this.iterableRef,
    required this.nodeList,
  });

  @override
  List<WidgetTemplateNode> eval(WidgetTemplateVariablesContext context) {
    final iterable = iterableRef.eval(context);
    return iterable is! Iterable
      ? throw Exception('There is no iterable at ${iterableRef.toString()}')
      : List.from(Iterable.castFrom(iterable).map<WidgetTemplateNode>((e) {
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
  @override
  final EvaluableNodeList nodeList;

  const EachIteration({
    // required this.index,
    required this.data,
    required this.nodeList
  });
  
  /// TODO: implement modifyContext by allowing [index] to be passed to the new context.
  @override
  List<WidgetTemplateNode> eval(WidgetTemplateVariablesContext context) {
    return evaluateNodeList(context).map(
      (e) => ContextChangeNode(
        data: data,
        content: e
      )).toList();
  }
}

import 'package:templuate/src/expressions/arguments/bracket_argument.dart';
import 'package:templuate/src/nodes/helpers.dart';

import '../variables.dart';
import 'node.dart';

/// An object that can be evaluated into [T] by using [WidgetTemplateVariablesContext].
abstract class Evaluable<T> {
  T eval(WidgetTemplateVariablesContext context);
}

typedef EvaluableNodeList = Evaluable<List<WidgetTemplateNode>>;

/// A node that can be evaluated to return a [List] of [WidgetTemplateNode]s
abstract class EvaluableNode extends WidgetTemplateNode<List<WidgetTemplateNode>>
  with ChildNodes
  implements EvaluableNodeList {
  const EvaluableNode();  
}

abstract class EvaluableArgument<T> implements Evaluable<T>, BracketArgumentConvertable { }

/// Layout a constant list of widget templates
class WidgetTemplateNodeListConstant implements EvaluableNodeList {
  final List<WidgetTemplateNode> templateNodes;
  const WidgetTemplateNodeListConstant(this.templateNodes);
  
  @override
  List<WidgetTemplateNode> eval(WidgetTemplateVariablesContext context) {
    return templateNodes;
  }

  @override
  String toString() {
    return templateNodes.map((e) => e.toString()).join();
  }
}

import 'package:templuate/src/expressions/bracket_argument.dart';
import 'package:templuate/src/nodes/node.dart';

import '../variables.dart';


/// An object that can be evaluated into [T] by using [WidgetTemplateVariablesContext].
abstract class Evaluable<T> {  
  T eval(WidgetTemplateVariablesContext context);
}

typedef EvaluableOfEvaluableNodeList = Evaluable<List<Evaluable>>;


/// A node in the template that is interpreted by the template compiler to have an [enclosedType] of [Evaluable]<[T]>.
/// 
/// Can be evaluated to return a [T] at template run time.
/// 
/// e.g. a block helper, inline helper, inline variable, free text, etc.
abstract class EvaluableNode<T> implements Evaluable<T>, TemplateNode {}

/// An [EvaluableNode] that evaluates to a list containing elements of [EvaluableNode]<[T]>.
typedef EvaluableNodeOfEvaluableNodeList<T> = EvaluableNode<List<EvaluableNode<T>>>;

abstract class EvaluableArgument<T> implements Evaluable<T>, BracketArgument {}

/// Layout a constant list of widget templates
class EvaluableNodeListConstant implements EvaluableNodeOfEvaluableNodeList {
  final List<EvaluableNode> templateNodes;
  const EvaluableNodeListConstant(this.templateNodes);
  
  @override
  List<EvaluableNode> eval(WidgetTemplateVariablesContext context) {
    return templateNodes;
  }

  @override
  String toString() {
    return templateNodes.map((e) => e.toString()).join();
  }
}

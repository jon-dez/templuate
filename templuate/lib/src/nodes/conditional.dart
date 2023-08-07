import 'package:templuate/src/nodes/helpers.dart';

import '../variables.dart';
import '../expressions/evaluable.dart';

class ConditionalNode implements EvaluableNodeOfEvaluableNodeList {
  final Evaluable<List<EvaluableNode>> truthyList;
  final Evaluable<List<EvaluableNode>> falseyList;

  final Evaluable<bool> statement;
  const ConditionalNode({
    required this.statement,
    this.truthyList = const EvaluableNodeListConstant([]),
    this.falseyList = const EvaluableNodeListConstant([]),
  });

  @override
  List<EvaluableNode> eval(WidgetTemplateVariablesContext context) {
    if(statement.eval(context)) {
      return evaluateAll(falseyList.eval(context), context);
    }
    return evaluateAll(truthyList.eval(context), context);
  }
}

enum LayoutCondition {
  hasElement
}

class LayoutConditionStatement implements EvaluableArgument<bool> {
  final LayoutCondition condition;
  final LayoutVariableRef varRef;
  const LayoutConditionStatement(this.varRef, this.condition);
  const LayoutConditionStatement.hasElement(this.varRef)
    : condition = LayoutCondition.hasElement;
    
  @override
  bool eval(WidgetTemplateVariablesContext context) {
    final data = varRef.eval(context);
    switch(condition) {
      case LayoutCondition.hasElement:
        return data is Iterable && data.isNotEmpty;
      default:
        throw UnimplementedError('$LayoutCondition type $condition not implemented.');
    }
  }
  
  @override
  String get argString => '$condition $varRef';
}

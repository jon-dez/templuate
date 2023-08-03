import 'package:templuate/src/nodes/helpers.dart';

import '../expressions/arguments/bracket_argument.dart';
import '../expressions/arguments/nested_helper.dart';
import '../expressions/common/helper_function.dart';
import '../variables.dart';
import 'evaluable.dart';
import 'node.dart';

class ConditionalNode extends EvaluableNode {
  final Evaluable<List<WidgetTemplateNode>> truthyList;
  final Evaluable<List<WidgetTemplateNode>> falseyList;

  /// TODO: This should be [Evaluable] of bool instead of [LayoutConditionStatement] to allow for custom nested helpers.
  final LayoutConditionStatement statement;
  const ConditionalNode({
    required this.statement,
    this.truthyList = const WidgetTemplateNodeListConstant([]),
    this.falseyList = const WidgetTemplateNodeListConstant([]),
  });

  @override
  EvaluableNodeList get nodeList => truthyList;

  @override
  List<WidgetTemplateNode> eval(WidgetTemplateVariablesContext context) {
    final data = statement.varRef.eval(context);
    switch (statement.condition) {
      case LayoutCondition.hasElement:
        // TODO: LayoutConditionStatement.eval(context) != true
        if(data is! Iterable || data.isEmpty) {
          return evaluateAll(falseyList.eval(context), context);
        }
        return evaluateNodeList(context);
      default:
        throw UnimplementedError('$LayoutCondition type $statement not implemented.');
    }
  }
}

enum LayoutCondition {
  hasElement
}

/// TODO: This should implement Evaluable<bool> 
class LayoutConditionStatement {
  final LayoutCondition condition;
  final LayoutVariableRef varRef;
  const LayoutConditionStatement(this.varRef, this.condition);
  const LayoutConditionStatement.hasElement(this.varRef)
    : condition = LayoutCondition.hasElement;

  BracketArgument toBracketArgument() {
    return NestedHelperFnArg(HelperFunction(
      condition.name,
      args: [varRef.toBracketArgument()]
    ));
  }
}

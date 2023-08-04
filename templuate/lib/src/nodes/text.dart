import 'package:flutter/widgets.dart';
import 'package:templuate/src/template/templated_widget.dart';
import '../expressions/expression.dart';
import '../nodes/evaluable.dart';
import '../variables.dart';

abstract class WidgetTemplateNodeExpression<T> {
  ValidatedExpression get validatedExpression;
  T get expressionData;
}

/// TODO: Perhaps rename [TextNode] to [FreeTextNode], and extend from [EvaluableNode]<[String]> instead in order to remove dependency from widgets.
class TextNode extends WidgetTemplateNode {
  final WidgetTemplateNodeExpression<Evaluable<String>> expression;
  const TextNode(this.expression);
  
  @override
  Widget eval(WidgetTemplateVariablesContext context) {
    final text = expression.expressionData;
    return Text(text.eval(context));
  }
}

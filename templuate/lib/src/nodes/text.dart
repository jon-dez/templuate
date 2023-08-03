import 'package:flutter/widgets.dart';
import '../expressions/expression.dart';
import '../nodes/evaluable.dart';
import '../variables.dart';
import 'helpers.dart';
import 'renderable.dart';

abstract class WidgetTemplateNodeExpression<T> {
  ValidatedExpression get validatedExpression;
  T get expressionData;
}

class TextNode extends RenderableNode
  with NoChildNodes {
  final WidgetTemplateNodeExpression<Evaluable<String>> expression;
  const TextNode(this.expression);
  
  @override
  Widget getWidget(WidgetTemplateVariablesContext variablesContext) {
    final text = expression.expressionData;
    return Text(text.eval(variablesContext));
  }
}

import 'package:flutter/widgets.dart';
import 'package:templuate/src/expressions/expression.dart';
import 'package:templuate/src/nodes/helpers.dart';
import 'package:templuate/src/variables.dart';

import 'nodes/node.dart';

typedef TemplatedWidgetBuilder = TemplatedWidget Function(Map<String, dynamic> layoutData);

class WidgetTemplateDefinition {
  final List<ValidatedExpression> validatedExpressions;
  const WidgetTemplateDefinition(this.validatedExpressions);

  @override
  String toString() {
    return validatedExpressions.map((e) => e.expression).join();
  }
}

class TemplatedWidget extends StatelessWidget {
  final Map<String, dynamic> layoutData;
  final List<WidgetTemplateNode> templateNodes;
  const TemplatedWidget({super.key,
    required this.layoutData,
    required this.templateNodes
  });

  @override
  Widget build(BuildContext context) {
    final widgets = renderAll(templateNodes, WidgetTemplateVariablesContext(layoutData));
    if(widgets.length == 1) {
      return widgets[0];
    } 
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}

class LinkedTemplate {
  final WidgetTemplateDefinition templateDefinition;
  final List<WidgetTemplateNode> templateNodes;
  LinkedTemplate(this.templateDefinition, this.templateNodes);

  @override
  String toString() {
    // TODO: Print out a tree representation of the flutter widget each WidgetTemplateNode will evaluate to.
    return super.toString();
  }

  Widget render(Map<String, dynamic> layoutData) {
    return TemplatedWidget(layoutData: layoutData, templateNodes: templateNodes);
  }
}

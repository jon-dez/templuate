import 'package:flutter/widgets.dart';
import 'package:templuate/src/nodes/helpers.dart';
import 'package:templuate/templuate.dart';


typedef TemplatedWidgetBuilder = TemplatedWidget Function(Map<String, dynamic> layoutData);

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


abstract class WidgetTemplateNode extends EvaluableNode<Widget> {
  const WidgetTemplateNode();
}

abstract class WidgetTemplateNodeList extends EvaluableNodeOfEvaluableNodeList<Widget> {
  const WidgetTemplateNodeList();
}

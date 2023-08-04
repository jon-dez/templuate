import 'package:flutter/widgets.dart';
import 'package:templuate/src/nodes/node.dart';
import 'package:templuate/src/template/templated_widget.dart';

import '../variables.dart';

// mixin NoChildNodes on WidgetTemplateNode {
//   @override
//   Null get content => null;
// }

// mixin OneChildNode on WidgetTemplateNode {
//   @override
//   WidgetTemplateNode get content;
// }


// mixin ChildNodes on WidgetTemplateNode<List<WidgetTemplateNode>> {
//   // EvaluableNodeList get nodeList;

//   // List<RenderableNode> evaluateNodeList(WidgetTemplateVariablesContext context) {
//   //   return evaluateAll(nodeList.eval(context), context);
//   // }
// }

List<WidgetTemplateNode> evaluateAll(List<TemplateNode> nodes, WidgetTemplateVariablesContext context) {
  final renderableNodes = <WidgetTemplateNode>[
    for(var child in nodes)
      if(child is WidgetTemplateNode)
        child
      else if (child is WidgetTemplateNodeList)
        ...evaluateAll(child.eval(context), context)
      // TODO: Double check to see if child ever ends up being any other type besides the two in the if statements above.
  ];
  return renderableNodes;
}

List<Widget> renderAll(List<TemplateNode> nodes, WidgetTemplateVariablesContext context) {
  final renderableNodes = evaluateAll(nodes, context);
  final widgets = <Widget>[
    for(var node in renderableNodes)
      node.eval(context)
  ];
  return widgets;
}

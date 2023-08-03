import '../variables.dart';
import 'evaluable.dart';
import 'renderable.dart';

mixin NoChildNodes on WidgetTemplateNode {
  @override
  Null get content => null;
}

mixin OneChildNode on WidgetTemplateNode {
  @override
  WidgetTemplateNode get content;
}


mixin ChildNodes on WidgetTemplateNode<List<WidgetTemplateNode>> {
  EvaluableNodeList get nodeList;

  List<RenderableNode> evaluateNodeList(WidgetTemplateVariablesContext context) {
    return evaluateAll(nodeList.eval(context), context);
  }
}

List<RenderableNode> evaluateAll(List<WidgetTemplateNode> nodes, WidgetTemplateVariablesContext context) {
  final renderableNodes = <RenderableNode>[
    for(var child in nodes)
      if(child is RenderableNode)
        child
      else if (child is EvaluableNode)
        ...evaluateAll(child.eval(context), context)
      // TODO: Double check to see if child ever ends up being any other type besides the two in the if statements above.
  ];
  return renderableNodes;
}

List<Widget> renderAll(List<WidgetTemplateNode> nodes, WidgetTemplateVariablesContext context) {
  final renderableNodes = evaluateAll(nodes, context);
  final widgets = <Widget>[
    for(var node in renderableNodes)
      node.getWidget(context)
  ];
  return widgets;
}

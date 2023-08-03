import 'package:flutter/material.dart';
import 'package:templuate/src/nodes/helpers.dart';
export 'package:flutter/material.dart' show Widget;

import 'node.dart';
export 'node.dart';

import '../variables.dart';

/// A node that can be rendered into a [Widget]
abstract class RenderableNode<T> extends WidgetTemplateNode<T> {
  const RenderableNode();

  Widget getWidget(WidgetTemplateVariablesContext variablesContext);
}

abstract class RenderableNodeList extends RenderableNode<List<WidgetTemplateNode>>
  with ChildNodes {
  const RenderableNodeList();

  List<Widget> renderNodeList(WidgetTemplateVariablesContext context) {
    return renderAll(nodeList.eval(context), context);
  }
}
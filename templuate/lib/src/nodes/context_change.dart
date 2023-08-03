import '../variables.dart';
import 'helpers.dart';
import 'renderable.dart';

/// Represents a node that modifies the scope of the current variables context.
/// 
/// Its purpose is to narrow the variables context to [data].
class ContextChangeNode extends RenderableNode
  with OneChildNode {
  /// The template to use with [data] as its context.
  @override
  final RenderableNode content;
  final dynamic data;

  const ContextChangeNode({
    required this.data,
    required this.content
  });
  
  @override
  Widget getWidget(WidgetTemplateVariablesContext variablesContext) {
    return content.getWidget(variablesContext.childContext(data));
  }
}

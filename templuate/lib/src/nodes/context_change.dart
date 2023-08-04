import '../../nodes.dart';
import '../variables.dart';

/// Represents a node that modifies the scope of the current variables context.
/// 
/// Its purpose is to narrow the variables context to [data].
class ContextChangeNode<T> extends EvaluableNode<T> {
  /// The template to use with [data] as its context.
  @override
  final EvaluableNode<T> content;
  final dynamic data;

  const ContextChangeNode({
    required this.data,
    required this.content
  });
  
  @override
  T eval(WidgetTemplateVariablesContext context) {
    return content.eval(context.childContext(data));
  }
}

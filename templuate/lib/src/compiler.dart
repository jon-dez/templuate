import 'package:flutter/material.dart';
import 'package:templuate/src/nodes/else.dart';
import 'package:templuate/src/nodes/evaluable_node.dart';
import 'package:templuate/src/template/templated_widget.dart';
import 'package:templuate/src/template/template_definition.dart';
import 'package:templuate/src/nodes/helpers.dart';

import 'expressions.dart';
import 'expressions/bracket_arguments/identifier_args/helper_function_or_variable.dart';
import 'expressions/common/helper_function.dart';
import 'expressions/common/helper_parameters.dart';
import 'expressions/expression.dart';
import 'expressions/text.dart';
import 'helpers.dart';
import 'expressions/evaluable.dart';
import 'nodes/node.dart';
import 'nodes/text.dart';
import 'variables.dart';

typedef CustomHelperFn<T> = EvaluableNode<T> Function(
    HelperParameters arguments, List<ValidatedExpression>? children);

typedef EvaluableFn<T> = T Function(WidgetTemplateVariablesContext variablesContext);

abstract class WidgetHelperNode<T> implements WidgetTemplateNode {
  const WidgetHelperNode();

  @override
  Widget eval(WidgetTemplateVariablesContext context) {
    return widgetBuilder(context);
  }

  WidgetBuilderHelperFn get widgetBuilder;
}

abstract class WidgetHelper<T extends WidgetHelperNode> {
  final String name;

  const WidgetHelper(this.name);

  T useArgs(HelperParameters arguments, NodeContentEvaluator contentEvaluator);
}

typedef X = WidgetBuilderHelperFn Function(
  NodeContentEvaluator nodeContentEvaluator
);

abstract class WidgetBlockHelper<T, U> extends WidgetHelper<WidgetBlockHelperFunction> {
  final Widget Function(
    T args,
    U content,
    WidgetTemplateVariablesContext context
  ) widgetBlockHelperFn;

  const WidgetBlockHelper(String name, this.widgetBlockHelperFn): super(name);

  Evaluable<T> create(HelperParameters arguments);
  U getContent(NodeContentEvaluator contentEvaluator);

  @override
  WidgetBlockHelperFunction useArgs(HelperParameters arguments, NodeContentEvaluator contentEvaluator) {
    assert(name == arguments.functionName);
    final evaluable = create(arguments);
    final content = getContent(contentEvaluator);
    return WidgetBlockHelperFunction(contentEvaluator, (variablesContext) {
      return widgetBlockHelperFn(evaluable.eval(variablesContext), content, variablesContext);
    });
  }
}

typedef RenderContentFn = List<Widget> Function(WidgetTemplateVariablesContext<dynamic> variablesContext);

abstract class WidgetBlockHelperWithChildren<T> extends WidgetBlockHelper<T, RenderContentFn> {
  const WidgetBlockHelperWithChildren(super.name, super.widgetBlockHelperFn);

  @override
  RenderContentFn getContent(NodeContentEvaluator contentEvaluator) {
    return contentEvaluator.renderContent;
  }
}

abstract class WidgetBlockHelperOneChildWidget<T> extends WidgetBlockHelper<T, WidgetTemplateNode> {
  const WidgetBlockHelperOneChildWidget(super.name, super.widgetBlockHelperFn);

  @override
  WidgetTemplateNode getContent(NodeContentEvaluator contentEvaluator) {
    return contentEvaluator.asOneWidget();
  }
}

abstract class WidgetInlineHelper<T> extends WidgetHelper<WidgetInlineHelperFunction> {
  final Widget Function(T args) widgetInlineHelperFn;

  const WidgetInlineHelper(String name, this.widgetInlineHelperFn): super(name);
  
  Evaluable<T> create(HelperParameters arguments);

  @override
  WidgetInlineHelperFunction useArgs(HelperParameters arguments, NodeContentEvaluator contentEvaluator) {
    assert(name == arguments.functionName);
    // contentEvaluator.hasNoChildren(); // TODO: Inline helpers should not have child content.
    final evaluable = create(arguments);
    return WidgetInlineHelperFunction((variablesContext) {
      return widgetInlineHelperFn(evaluable.eval(variablesContext));
    });
  }
}

@immutable
class NodeContentEvaluator {
  final List<TemplateNode> content;

  const NodeContentEvaluator(this.content);

  WidgetTemplateNode asOneWidget() {
    if(content.isEmpty || content.length > 1) {
      throw Exception('One node is expected here. It is expected to be a $WidgetTemplateNode.');
    }
    final single = content.first;
    if(single is! WidgetTemplateNode) {
      throw Exception('$single is not a $WidgetTemplateNode');
    }
    return single;
  }

  List<Widget> renderContent(WidgetTemplateVariablesContext variablesContext) {
    return renderAll(content, variablesContext);
  }

  Evaluable<List<EvaluableNode>> asEvaluableNodeList() {
    final evaluableNodeList = content.whereType<EvaluableNode>().toList();
    return makeNodeListEvaluable(evaluableNodeList);
  }
}

typedef WidgetBuilderHelperFn = Widget Function(WidgetTemplateVariablesContext variablesContext);
typedef WidgetHelperFn = WidgetBuilderHelperFn Function(HelperParameters arguments, NodeContentEvaluator contentEvaluator);

@immutable
class WidgetHelperBuilder {
  final HelperParameters arguments;
  final NodeContentEvaluator contentEvaluator;
  final WidgetBuilderHelperFn builderHelperFn;

  const WidgetHelperBuilder(this.arguments, this.contentEvaluator, this.builderHelperFn);

  Evaluable<List<EvaluableNode>> get evaluableNodeList => contentEvaluator.asEvaluableNodeList();
}

@immutable
class WidgetBlockHelperFunction extends WidgetHelperNode<List<WidgetTemplateNode>> {
  // final HelperParameters arguments;
  final NodeContentEvaluator contentEvaluator;
  @override
  final WidgetBuilderHelperFn widgetBuilder;

  const WidgetBlockHelperFunction(
    // this.arguments,
    this.contentEvaluator,
    this.widgetBuilder,
  );
}

class WidgetInlineHelperFunction extends WidgetHelperNode {
  // final HelperParameters arguments;
  @override
  final WidgetBuilderHelperFn widgetBuilder;

  const WidgetInlineHelperFunction(this.widgetBuilder);
}

class TemplateLinker {
  final _customHelpers = <String, CustomHelperFn>{};
  final _customNestedHelpers = <String, NestedHelper>{};

  void addHelper<T extends WidgetHelperNode>(
    WidgetHelper<T> widgetHelper
  ) {
    _customHelpers[widgetHelper.name] = (args, children) {
      return widgetHelper.useArgs(
        args,
        NodeContentEvaluator(link(children ?? []))
      );
    };
  }

  void addNestedHelper<T>(String name, CustomNestedHelperFn<T> nestedHelperFn) {
    _customNestedHelpers[name] = NestedHelper<T>(nestedHelperFn);
  }

  /// Filters out all linked [TemplateNode]s that do not have [TemplateNode.enclosedType] of [Widget].
  TemplatedWidgetBuilder linkTemplateDefinition(TemplateDefinition templateDefinition) {
    final linkedTemplate = link(templateDefinition.validatedExpressions);
    debugPrint('Linked template successfully: $templateDefinition');
    return (templateData) => TemplatedWidget(
      layoutData: templateData, templateNodes: linkedTemplate.whereType<WidgetTemplateNode>().toList()
    );
  }

  /// Links each [TemplateNode] to an appropriate [EvaluableNode].
  List<TemplateNode> link(
      List<ValidatedExpression> validatedExpressions) {
    var nodes = <TemplateNode>[];
    for (var expression in validatedExpressions) {
      if (expression is InlineBracket) {
        final content = expression.content;
        if (content is EvaluableArgumentExpressionContent) {
          final evaluable = content.evaluble;
          if (evaluable is LiteralArg) {
            nodes.add(FreeTextNode(evaluable.toEvaluableString()));
            continue;
          } else if (evaluable is LayoutVariableRef) {
            nodes.add(FreeTextNode.evaluableToString(evaluable));
            continue;
          }
        } else if (content is HelperFunction) {
          nodes.add(_bindHelperOrThrow(content, children: [], templateCompiler: this));
          continue;
        } else if (content is HelperFunctionOrVariable) {
          if(content.identifier == 'else') {
            nodes.add(ElseNode());
            continue;
          } else {
            nodes.add(_bindHelperFunctionOrFallbackToVariable(content));
            continue;
          }
        }
        throw UnimplementedError(
            '$InlineBracket.content ${content.runtimeType} is not supported.');
      } else if (expression is BlockExpression) {
        nodes.add(_bindHelperOrThrow(expression.function, children: expression.children, templateCompiler: this));
        continue;
      } else if (expression is TextExpression) {
        nodes.add(FreeTextNode(LiteralArg.from(expression.text)));
        continue;
      }
      throw UnimplementedError(
          '$ValidatedExpression type ${expression.runtimeType} is not supported.');
    }
    return nodes;
  }

  EvaluableNode _bindHelperFunctionOrFallbackToVariable(HelperFunctionOrVariable functionOrVariable) {
    return bindHelper(functionOrVariable.asFunction(), children: [], templateCompiler: this)
      ?? EvaluableToNode(functionOrVariable.asVariableRef())
    ;
  }

  EvaluableNode _bindHelperOrThrow(HelperFunction function, {
    required List<ValidatedExpression> children,
    required TemplateLinker templateCompiler
  }) {
    final helper = bindHelper(function, children: children, templateCompiler: templateCompiler);
    if (helper == null) {
      throw Exception('The custom helper `${function.name}` was not found.');
    }
    return helper;
  }

  CustomHelperFn? findCustomHelper(String identifier) => _customHelpers[identifier];

  NestedHelper<T>? findCustomNestedHelperOrNull<T>(String identifier) {
    final helper = _customNestedHelpers[identifier];
    if (helper == null) {
      return null;
    }
    if (helper is! NestedHelper<T>) {
      throw Exception(
          'A return type of $T was expected, but the custom nested helper ($identifier) has a return type of ${helper.returnType}');
    }
    return helper;
  }
}

/// Evaluates everything, returns nothing.
class VoidNode implements EvaluableNode {
  final List<Evaluable> args;
  final List<TemplateNode> children;
  const VoidNode(this.args, this.children);
  
  @override
  List<TemplateNode> eval(WidgetTemplateVariablesContext context) {
    for (var element in args) {
      element.eval(context);
    }
    evaluateAll(children, context);
    return [];
  }
}

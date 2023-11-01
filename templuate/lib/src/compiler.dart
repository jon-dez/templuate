import 'package:flutter/material.dart';
import 'package:templuate/src/nodes/else.dart';
import 'package:templuate/src/nodes/evaluable_as_node.dart';
import 'package:templuate/src/template/templated_widget.dart';
import 'package:templuate/src/template/template_definition.dart';
import 'package:templuate/src/nodes/helpers.dart';
import 'package:templuate/src/templated_text_linker.dart';

import 'expressions.dart';
import 'expressions/bracket_arguments/identifier_args/helper_function_or_variable.dart';
import 'expressions/common/helper_function.dart';
import 'expressions/common/helper_parameters.dart';
import 'expressions/expression.dart';
import 'expressions/text.dart';
import 'helpers.dart';
import 'expressions/evaluable.dart';
import 'nodes/conditional.dart';
import 'nodes/each.dart';
import 'nodes/node.dart';
import 'nodes/text.dart';
import 'nodes/void.dart';
import 'templated_widget_linker.dart';
import 'variables.dart';

typedef CustomHelperFn<T> = EvaluableNode<T> Function(
    HelperParameters arguments, List<ValidatedExpression>? children);

typedef EvaluableFn<T> = T Function(
    WidgetTemplateVariablesContext variablesContext);

abstract class WidgetHelperNode<T> implements WidgetTemplateNode {
  const WidgetHelperNode();

  @override
  Widget eval(WidgetTemplateVariablesContext context) {
    return widgetBuilder(context);
  }

  WidgetBuilderHelperFn get widgetBuilder;
}

abstract class TemplateHelper<T> {
  String get name;

  EvaluableNode<T> useArgs(
      HelperParameters arguments, NodeContentEvaluator contentEvaluator);
}

typedef TemplateBlockHelper<T> = TemplateHelper<List<EvaluableNode<T>>>;
typedef TemplateInlineHelper<T> = TemplateHelper<T>;

abstract class WidgetHelper<T extends WidgetHelperNode>
    implements TemplateHelper<Widget> {
  @override
  final String name;

  const WidgetHelper(this.name);

  @override
  useArgs(HelperParameters arguments, NodeContentEvaluator contentEvaluator);
}

typedef X = WidgetBuilderHelperFn Function(
    NodeContentEvaluator nodeContentEvaluator);

abstract class WidgetBlockHelper<T, U>
    extends WidgetHelper<WidgetBlockHelperFunction> {
  final Widget Function(
          T args, U content, WidgetTemplateVariablesContext context)
      widgetBlockHelperFn;

  const WidgetBlockHelper(String name, this.widgetBlockHelperFn) : super(name);

  Evaluable<T> create(HelperParameters arguments);
  U getContent(NodeContentEvaluator contentEvaluator);

  @override
  WidgetBlockHelperFunction useArgs(
      HelperParameters arguments, NodeContentEvaluator contentEvaluator) {
    assert(name == arguments.functionName);
    final evaluable = create(arguments);
    final content = getContent(contentEvaluator);
    return WidgetBlockHelperFunction(contentEvaluator, (variablesContext) {
      return widgetBlockHelperFn(
          evaluable.eval(variablesContext), content, variablesContext);
    });
  }
}

typedef RenderContentFn = List<Widget> Function(
    WidgetTemplateVariablesContext<dynamic> variablesContext);

abstract class WidgetBlockHelperWithChildren<T>
    extends WidgetBlockHelper<T, RenderContentFn> {
  const WidgetBlockHelperWithChildren(super.name, super.widgetBlockHelperFn);

  @override
  RenderContentFn getContent(NodeContentEvaluator contentEvaluator) {
    return contentEvaluator.renderContent;
  }
}

abstract class WidgetBlockHelperOneChildWidget<T>
    extends WidgetBlockHelper<T, WidgetTemplateNode> {
  const WidgetBlockHelperOneChildWidget(super.name, super.widgetBlockHelperFn);

  @override
  WidgetTemplateNode getContent(NodeContentEvaluator contentEvaluator) {
    return contentEvaluator.asOneWidget();
  }
}

abstract class WidgetInlineHelper<T>
    extends WidgetHelper<WidgetInlineHelperFunction> {
  final Widget Function(T args) widgetInlineHelperFn;

  const WidgetInlineHelper(String name, this.widgetInlineHelperFn)
      : super(name);

  Evaluable<T> create(HelperParameters arguments);

  @override
  WidgetInlineHelperFunction useArgs(
      HelperParameters arguments, NodeContentEvaluator contentEvaluator) {
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
    if (content.isEmpty || content.length > 1) {
      throw Exception(
          'One node is expected here. It is expected to be a $WidgetTemplateNode.');
    }
    final single = content.first;
    if (single is! WidgetTemplateNode) {
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

typedef WidgetBuilderHelperFn = Widget Function(
    WidgetTemplateVariablesContext variablesContext);
typedef WidgetHelperFn = WidgetBuilderHelperFn Function(
    HelperParameters arguments, NodeContentEvaluator contentEvaluator);

@immutable
class WidgetHelperBuilder {
  final HelperParameters arguments;
  final NodeContentEvaluator contentEvaluator;
  final WidgetBuilderHelperFn builderHelperFn;

  const WidgetHelperBuilder(
      this.arguments, this.contentEvaluator, this.builderHelperFn);

  Evaluable<List<EvaluableNode>> get evaluableNodeList =>
      contentEvaluator.asEvaluableNodeList();
}

@immutable
class WidgetBlockHelperFunction
    extends WidgetHelperNode<List<WidgetTemplateNode>> {
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

  void addHelper<T>(TemplateHelper<T> widgetHelper) {
    _customHelpers[widgetHelper.name] = (args, children) {
      return widgetHelper.useArgs(
          args, NodeContentEvaluator(link(children ?? [])));
    };
  }

  void addNestedHelper<T>(String name, CustomNestedHelperFn<T> nestedHelperFn) {
    _customNestedHelpers[name] = NestedHelper<T>(nestedHelperFn);
  }

  TemplatedStringBuilder linkTextBuilder(
      TemplateDefinition templateDefinition) {
    final linkedTemplate =
        link<String>(templateDefinition.validatedExpressions).map((e) {
      if (e is! EvaluableNode<String>) {
        throw Exception('$e is not an `${EvaluableNode<String>}`.');
      }
      return e;
    });
    return (context) => linkedTemplate
        .toList()
        .fold(
            StringBuffer(''),
            (previousValue, element) =>
                previousValue..write(element.eval(context)))
        .toString();
  }

  /// Filters out all linked [TemplateNode]s that do not have [TemplateNode.enclosedType] of [Widget].
  TemplatedWidgetBuilder linkWidgetBuilder(
      TemplateDefinition templateDefinition) {
    final linkedTemplate = link(templateDefinition.validatedExpressions);
    debugPrint('Linked template successfully: $templateDefinition');
    return (templateData) => TemplatedWidget(
        layoutData: templateData,
        templateNodes: linkedTemplate.whereType<WidgetTemplateNode>().toList());
  }

  /// Links each [ValidatedExpression] to an appropriate [TemplateNode].
  List<TemplateNode> link<T>(List<ValidatedExpression> validatedExpressions) {
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
          nodes.add(_bindHelperOrThrow<T>(content,
              children: [], templateCompiler: this));
          continue;
        } else if (content is HelperFunctionOrVariableRef) {
          if (content.identifier == 'else') {
            nodes.add(ElseNode());
            continue;
          } else {
            nodes.add(_bindHelperFunctionOrFallbackToVariableRef<T>(content));
            continue;
          }
        }
        throw UnimplementedError(
            '$InlineBracket.content ${content.runtimeType} is not supported.');
      } else if (expression is BlockExpression) {
        nodes.add(_bindHelperOrThrow<T>(expression.function,
            children: expression.children, templateCompiler: this));
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

  /// Bind to a built-in helper or a custom helper if one exists.
  EvaluableNode? _bindHelper<T>(HelperFunction function,
      {required List<ValidatedExpression> children}) {
    final identifier = function.name;
    final params = HelperParameters(function, this);
    // All before default are built in.
    switch (identifier) {
      case 'void':
        return VoidNode([
          for (var i = 0; i < params.positionalArgLength; i++)
            params.positional(i).as(),
          for (final namedArg in params.namedArgs) params.named(namedArg).as()
        ], link(children));
      case 'each':
        params.expectNotEmpty();
        final iterableIdentifier = params[0].asVariableRef();
        return EachNode(
            iterableRef: iterableIdentifier,
            nodeList: makeNodeListEvaluable(
                link(children).whereType<EvaluableNode>().toList()));
      // TODO: Replace 'conditional' with 'if'
      case 'conditional':
        params.expectNotEmpty();
        final truthyList = <EvaluableNode>[];
        final falseyList = <EvaluableNode>[];
        var elseDefined = false;
        final nodes = link(children);
        for (final node in nodes) {
          if (node is ElseNode) {
            if (elseDefined) {
              throw Exception('`else` block already defined in this scope.');
            }
            elseDefined = true;
            continue;
          } else if (node is! EvaluableNode) {
            throw Exception(
                'A $TemplateNode in `conditional` is not type of `$EvaluableNode`, its type is `${node.runtimeType}`.');
          }
          if (elseDefined) {
            falseyList.add(node);
          } else {
            truthyList.add(node);
          }
        }
        return ConditionalNode(
            statement: params[0].asBoundNestedHelperFnArg(),
            truthyList: makeNodeListEvaluable(truthyList),
            falseyList: makeNodeListEvaluable(falseyList));
      default:
        final helper = findCustomHelper(identifier);
        return helper == null ? null : helper(params, children);
    }
  }

  /// Binds [HelperFunctionOrVariableRef] to an [EvaluableNode], which can either be a helper function (with no parameters) or a reference to a variable.
  ///
  /// Tries to interpret [functionOrVariable] as [HelperFunction] first. If no helper function exists with the name, then it is inferred as [LayoutVariableRef].
  ///
  /// In order to be interpreted as [HelperFunction], a helper function with the given name must be provided to [TemplateLinker].
  ///
  /// If [functionOrVariable] is inferred as [LayoutVariableRef], then during layout a variable with the name must exist in the current variables context.
  EvaluableNode _bindHelperFunctionOrFallbackToVariableRef<T>(
      HelperFunctionOrVariableRef functionOrVariable) {
    return _bindHelper<T>(functionOrVariable.asFunction(), children: []) ??
        EvaluableAsNode<T>(functionOrVariable.asVariableRef());
  }

  EvaluableNode _bindHelperOrThrow<T>(HelperFunction function,
      {required List<ValidatedExpression> children,
      required TemplateLinker templateCompiler}) {
    final helper = _bindHelper<T>(function, children: children);
    if (helper == null) {
      throw Exception('The custom helper `${function.name}` was not found.');
    }
    return helper;
  }

  /// TODO: Check the helper type
  CustomHelperFn? findCustomHelper(String identifier) =>
      _customHelpers[identifier];

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

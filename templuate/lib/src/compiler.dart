import 'package:flutter/material.dart';
import 'package:templuate/src/nodes/else.dart';
import 'package:templuate/src/parser2.dart';
import 'package:templuate/src/template/templated_widget.dart';
import 'package:templuate/src/template/template_definition.dart';
import 'package:templuate/src/nodes/helpers.dart';

import 'expressions/arguments/bracket_argument.dart';
import 'expressions/arguments/identifier.dart';
import 'expressions/arguments/literal.dart';
import 'expressions/arguments/nested_helper.dart';
import 'expressions/block.dart';
import 'expressions/common/helper_function.dart';
import 'expressions/expression.dart';
import 'expressions/inlines.dart';
import 'expressions/text.dart';
import 'helpers.dart';
import 'nodes/conditional.dart';
import 'nodes/each.dart';
import 'nodes/evaluable.dart';
import 'nodes/node.dart';
import 'nodes/text.dart';
import 'variables.dart';

typedef CustomHelperFn = WidgetTemplateNode Function(
    HelperParameters arguments, List<ValidatedExpression>? children);

typedef CustomNestedHelperFn<T> = EvaluableFn<T> Function(
    HelperParameters arguments);

typedef EvaluableFn<T> = T Function(WidgetTemplateVariablesContext variablesContext);

LayoutVariableRef<T> _variableRefFromIdentifierArg<T>(IdentifierArg identifierArg) {
  return identifierArg is PathIdentifierArg
    ? identifierArg.identifiesCurrentPath
      ? LayoutVariableRef.currentContext()
      : LayoutVariableRef(identifierArg.fullPath)
    : LayoutVariableRef([identifierArg.identifier])
  ;
}

class HelperParameter {
  final WidgetTemplateCompiler _compiler;
  final BracketArgument _argument;
  const HelperParameter(
    this._argument,
    this._compiler,
  );

  EvaluableArgument<bool> asBool() {
    return _evaluableArgFromBracketArg<bool>(_argument);
  }

  EvaluableArgument<int> asInt() {
    return _evaluableArgFromBracketArg<int>(_argument);
  }

  EvaluableArgument<double> asDouble() {
    return _evaluableArgFromBracketArg<double>(_argument);
  }

  EvaluableArgument<List> asList() {
    return _evaluableArgFromBracketArg<List>(_argument);
  }

  EvaluableArgument<num> asNum() {
    return _evaluableArgFromBracketArg<num>(_argument);
  }

  EvaluableArgument<T> as<T>() {
    return _evaluableArgFromBracketArg<T>(_argument);
  }

  NestedHelperFnArg asNestedHelperFnArg() {
    final argument = _argument;
    if (argument is! NestedHelperFnArg) {
      throw Exception(
          'The `conditional` helper expects a `$NestedHelperFnArg` that evaluates to a boolean.');
    }
    return argument;
  }

  EvaluableArgument<String> asString() {
    return _evaluableArgFromBracketArg<String>(_argument);
  }

  LayoutVariableRef asVariableRef() {
    final argument = _argument;
    if (argument is! IdentifierArg) {
      throw Exception('`$_argument` is not a variable reference.');
    }
    return _variableRefFromIdentifierArg(argument);
  }

  EvaluableArgument<T> _evaluableArgFromBracketArg<T>(BracketArgument argument) {
    if (argument is LiteralArg<T>) {
      return varLiteral(argument.literal);
    } else if (argument is IdentifierArg) {
      return _variableRefFromIdentifierArg(argument);
    } else if (argument is NestedHelperFnArg) {
      return _compiler._getNestedHelper<T>(argument) as EvaluableArgument<T>;
    } else {
      throw Exception(
          '`${argument.runtimeType}` could not be converted to a $EvaluableArgument of type $T');
    }
  }
}

/// TODO: Rename [HelperParameters] to [HelperArguments]
class HelperParameters {
  final HelperFunction _function;
  final WidgetTemplateCompiler _compiler;
  const HelperParameters._(
    this._function,
    this._compiler,
  );

  static T _getTemplate<T>(param, T Function(int) positionalFn, T Function(String) namedFn) {
     switch (param.runtimeType) {
      case int:
        return positionalFn(param as int);
      case String:
        return namedFn(param as String);
      default:
        throw Exception('Cannot look up parameter.');
    }
  }

  HelperParameter _requiredArg(BracketArgument? arg, Exception exception) {
    if(arg == null) {
      throw exception;
    }
    return HelperParameter(arg, _compiler);
  }

  /// Convenience function to get parameter by its position or name.
  HelperParameter operator [](param) => _getTemplate(param, positional, named);

  void expectNotEmpty() {
    if (_function.args.isEmpty) {
      throw Exception('The `${_function.name}` helper expects argument(s).');
    }
  }

  HelperParameter? optional(param) {
    final arg = _get(param);
    if (arg == null) {
      return null;
    }
    return HelperParameter(arg, _compiler);
  }

  HelperParameter positional(int index) => _requiredArg(
    _positional(index),
    Exception(
          'Helper function `${_function.name}` expected a positional argument at `$index`.')
  );

  BracketArgument? _get(param) => _getTemplate(param, _positional, _named);

  BracketArgument? _positional(int index) => index >= _function.args.length
    ? null
    : _function.args[index];

  HelperParameter named(String name) => _requiredArg(
    _named(name),
    Exception(
          'Helper function `${_function.name}` expected a named argument `$name`.')
  );

  BracketArgument? _named(String name) => _function.namedArgs[name];

  int get positionalArgLength => _function.args.length;

  Iterable<String> get namedArgs => _function.namedArgs.keys;
}

class NestedHelper<T> {
  final CustomNestedHelperFn<T> helper;
  NestedHelper(this.helper);

  Type get returnType => T;
}

class NestedHelperFn<T> implements EvaluableArgument<T> {
  final NestedHelperFnArg bracketArgument;
  final T Function(WidgetTemplateVariablesContext context) evaluableFn;
  const NestedHelperFn({
    required this.bracketArgument,
    required this.evaluableFn,
  });

  @override
  T eval(WidgetTemplateVariablesContext context) {
    return evaluableFn(context);
  }
  
  @override
  NestedHelperFnArg toBracketArgument() {
    return bracketArgument;
  }
  
  @override
  Type get evaluatedType => T;
}

abstract class WidgetHelperNode<T> extends WidgetTemplateNode {
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
    assert(name == arguments._function.name);
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
    assert(name == arguments._function.name);
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

class TextNodeExpression implements WidgetTemplateNodeExpression<Evaluable<String>> {
  @override
  final Evaluable<String> expressionData;

  @override
  final ValidatedExpression validatedExpression;

  const TextNodeExpression(this.expressionData, this.validatedExpression);
}

/// TODO: Rename [WidgetTemplateCompiler] to [WidgetTemplateLinker] since it describes its responsibility more appropriately.
class WidgetTemplateCompiler {
  final _customHelpers = <String, CustomHelperFn>{};
  final _customNestedHelpers = <String, NestedHelper>{};

  void addHelper<T extends WidgetHelperNode>(
    WidgetHelper<T> widgetHelper
  ) {
    _customHelpers[widgetHelper.name] = (args, children) {
      return widgetHelper.useArgs(
        args,
        NodeContentEvaluator(_link(children ?? []))
      );
    };
  }

  void addNestedHelper<T>(String name, CustomNestedHelperFn<T> nestedHelperFn) {
    _customNestedHelpers[name] = NestedHelper<T>(nestedHelperFn);
  }

  /// Filters out all linked [TemplateNode]s that do not have [TemplateNode.enclosedType] of [Evaluable]<[Widget]>.
  TemplatedWidgetBuilder linkTemplateDefinition(TemplateDefinition templateDefinition) {
    final linkedTemplate = _link(templateDefinition.validatedExpressions);
    debugPrint('Linked template successfully: $templateDefinition');
    return (templateData) => TemplatedWidget(
      layoutData: templateData, templateNodes: linkedTemplate.whereType<WidgetTemplateNode>().toList()
    );
  }

  /// Links each [ValidatedExpression] to its matching [TemplateNode].
  List<TemplateNode> _link(
      List<ValidatedExpression> validatedExpressions) {
    var nodes = <TemplateNode>[];
    for (var expression in validatedExpressions) {
      if (expression is InlineBracket) {
        if (expression is InlineLiteral) {
          final string = expression.literal.toString();
          nodes.add(TextNode(TextNodeExpression(
            varLiteral(string),
            expression
          )));
        } else if (expression is InlineVariable) {
          nodes.add(TextNode(TextNodeExpression(
            _variableRefFromIdentifierArg(expression.identifierArg),
            expression
          )));
        } else if (expression is InlineHelper) {
          nodes.add(findHelper(expression.function));
        } else if (expression is InlineHelperOrVariable) {
          final helperFunctionOrVariable = expression.helperFunctionOrVariable;
          if(helperFunctionOrVariable.identifier == 'else') {
            nodes.add(ElseNode());
          } else {
            nodes.add(findHelper(helperFunctionOrVariable.asFunction()));
          }
        } else {
          throw UnimplementedError(
              '$InlineBracket type ${expression.runtimeType} is not supported.');
        }
      } else if (expression is BlockExpression) {
        nodes.add(findHelper(expression.function, expression.children));
      } else if (expression is TextExpression) {
        nodes.add(TextNode(TextNodeExpression(
          varLiteral(expression.text),
          expression
        )));
      } else {
        throw UnimplementedError(
            '$ValidatedExpression type ${expression.runtimeType} is not supported.');
      }
    }
    return nodes;
  }

  TemplateNode findHelper(HelperFunction helperFunction,
      [List<ValidatedExpression>? children]) {
    final identifier = helperFunction.name;
    final params = HelperParameters._(helperFunction, this);
    // All before default are built in.
    switch (identifier) {
      case 'void':
        return VoidNode([
            for(var i = 0; i < params.positionalArgLength; i++)
              params.positional(i).as(),
            for(final namedArg in params.namedArgs)
              params.named(namedArg).as()
          ],
          _link(children ?? [])
        );
      case 'each':
        params.expectNotEmpty();
        final iterableIdentifier = params[0].asVariableRef();
        return EachNode(
            iterableRef: iterableIdentifier,
            nodeList: makeNodeListEvaluable(_link(children ?? []).whereType<EvaluableNode>().toList()));
      // TODO: Replace 'conditional' with 'if'
      case 'conditional':
        params.expectNotEmpty();
        // TODO:
        // Evaluable<bool> getConditionStatement() {
        getConditionStatement() {
          final nestedHelper = params[0].asNestedHelperFnArg();
          final nestedIdentifier =
              nestedHelper.function.name;
          final nestedParams = HelperParameters._(nestedHelper.function, this);
          switch (nestedIdentifier) {
            case 'hasElement':
              final varRef = nestedParams[0].asVariableRef();
              return LayoutConditionStatement.hasElement(varRef);
            default:
              // TODO:
              // return _findCustomNestedHelper(identifier, nestedArgs);
              throw UnimplementedError(
                  'Custom nested helpers are not supported yet.');
          }
        }
        final truthyList = <EvaluableNode>[];
        final falseyList = <EvaluableNode>[];
        var afterElse = false;
        final nodes = _link(children ?? []);
        for(final node in nodes) {
          if(node is ElseNode) {
            if(afterElse) {
              throw Exception('`else` block already defined in this scope.');
            }
            afterElse = true;
            continue;
          } else if(node is! EvaluableNode) {
            throw Exception('A node in `conditional` is not type of `$EvaluableNode`, its enclosed type is `${node.enclosedType}`.');
          }
          if(afterElse) {
            falseyList.add(node);
          } else {
            truthyList.add(node);
          }
        }
        return ConditionalNode(
          statement: getConditionStatement(),
          truthyList: makeNodeListEvaluable(truthyList),
          falseyList: makeNodeListEvaluable(falseyList)
        );
            // nodeList: makeNodeListEvaluable(link(children ?? [])));
      default:
        return _findCustomHelper(identifier, params, children);
    }
  }

  WidgetTemplateNode _findCustomHelper(String identifier,
      HelperParameters parameters, List<ValidatedExpression>? children) {
    final helper = _customHelpers[identifier];
    if (helper == null) {
      throw Exception('The custom helper `$identifier` was not found.');
    }
    return helper(parameters, children);
  }

  EvaluableArgument _getNestedHelper<T>(NestedHelperFnArg nestedHelperFnArg) {
    final identifier = nestedHelperFnArg.function.name;
    final parameters = HelperParameters._(nestedHelperFnArg.function, this);

    switch(identifier) {
      case 'each':
        final eachIterable = parameters.positional(0).asList();
        final eachNestedHelper = _getNestedHelper(
          parameters.positional(1).asNestedHelperFnArg()
        );
        return NestedHelperFn<List>(
          bracketArgument: nestedHelperFnArg,
          evaluableFn: (context){
            final eachEvals = eachIterable.eval(context)
              .map((iterationElement) {
                final newContext = context.childContext(iterationElement);
                return eachNestedHelper.eval(newContext);
              });
            return eachEvals.toList();
          },
        );
      case 'debugPrint':
        final printObject = parameters.positional(0).asString();
        return NestedHelperFn<void>(
          bracketArgument: nestedHelperFnArg,
          evaluableFn: (context) {
            final printedObject = printObject.eval(context);
            debugPrint('[Templating(debugPrint)]: $printedObject');
          }
        );
    }

    final helper = _customNestedHelpers[identifier];
    if (helper == null) {
      throw Exception('The custom nested helper `$identifier` was not found.');
    }
    if (helper is! NestedHelper<T>) {
      throw Exception(
          'A return type of $T was expected, but the custom nested helper ($identifier) has a return type of ${helper.returnType}');
    }
    final evaluableFn = helper.helper(parameters);
    return NestedHelperFn<T>(
      bracketArgument: nestedHelperFnArg,
      evaluableFn: evaluableFn);
  }
}

/// Evaluates everything, returns nothing.
class VoidNode extends EvaluableNode {
  final List<EvaluableArgument> args;
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

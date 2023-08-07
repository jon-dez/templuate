import 'package:templuate/helper_function.dart';
import 'package:templuate/src/expressions/common/helper_parameters.dart';
import 'package:templuate/src/variables.dart';

import '../compiler.dart';
import '../expressions/evaluable.dart';
import '../expressions/common/helper_function.dart';
import '../expressions/expression.dart';
import '../helpers.dart';
import 'conditional.dart';
import 'each.dart';
import 'else.dart';
import 'node.dart';

/// Bind to a built-in helper or a custom helper if one exists.
EvaluableNode? bindHelper<T>(HelperFunction function, {
  required List<ValidatedExpression> children,
  required TemplateLinker templateCompiler
}) {
  final identifier = function.name;
  final params = HelperParameters(function, templateCompiler);
  // All before default are built in.
  switch (identifier) {
    case 'void':
      return VoidNode([
          for(var i = 0; i < params.positionalArgLength; i++)
            params.positional(i).as(),
          for(final namedArg in params.namedArgs)
            params.named(namedArg).as()
        ],
        templateCompiler.link(children)
      );
    case 'each':
      params.expectNotEmpty();
      final iterableIdentifier = params[0].asVariableRef();
      return EachNode(
          iterableRef: iterableIdentifier,
          nodeList: makeNodeListEvaluable(templateCompiler.link(children).whereType<EvaluableNode>().toList()));
    // TODO: Replace 'conditional' with 'if'
    case 'conditional':
      params.expectNotEmpty();
      final truthyList = <EvaluableNode>[];
      final falseyList = <EvaluableNode>[];
      var afterElse = false;
      final nodes = templateCompiler.link(children);
      for(final node in nodes) {
        if(node is ElseNode) {
          if(afterElse) {
            throw Exception('`else` block already defined in this scope.');
          }
          afterElse = true;
          continue;
        } else if(node is! EvaluableNode) {
          throw Exception('A $TemplateNode in `conditional` is not type of `$EvaluableNode`, its type is `${node.runtimeType}`.');
        }
        if(afterElse) {
          falseyList.add(node);
        } else {
          truthyList.add(node);
        }
      }
      return ConditionalNode(
        statement: params[0].asBoundNestedHelperFnArg(),
        truthyList: makeNodeListEvaluable(truthyList),
        falseyList: makeNodeListEvaluable(falseyList)
      );
          // nodeList: makeNodeListEvaluable(link(children ?? [])));
    default:
      final helper = templateCompiler.findCustomHelper(identifier);
      return helper == null ? null : helper(params, children);
  }
}

class EvaluableToNode<T> implements EvaluableNode<T> {
  final Evaluable<T> evaluable;

  const EvaluableToNode(this.evaluable);

  @override
  T eval(WidgetTemplateVariablesContext context) => evaluable.eval(context);
}

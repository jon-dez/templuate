import 'package:flutter/material.dart';
import 'package:templuate/src/expressions/bracket_arguments/identifier_args/helper_function_or_variable.dart';
import 'package:templuate/src/expressions/expression.dart';
import 'package:templuate/src/expressions/text.dart';
import 'package:petitparser/petitparser.dart';
import 'package:templuate/src/variables.dart';

import '../helper_function.dart';
import 'expressions/bracket_arguments/identifier.dart';
import 'expressions/bracket_arguments/identifier_args/path_identifier_arg.dart';
import 'expressions/bracket_arguments/literal.dart';
import 'expressions/block.dart';
import 'expressions/inlines.dart';
import 'grammer/mustache_grammer_definition.dart';
import 'template/template_definition.dart';

class MustacheGrammerEvaluatorDefinition extends MustacheGrammerDefinition {

  @override
  Parser<TemplateDefinition> start() {
    return super.start().map((value) => TemplateDefinition(value as List<ValidatedExpression>));
  }

  @override
  Parser<List<ValidatedExpression>> mustache() {
    return super.mustache().map((value) => List<ValidatedExpression>.from(value));
  }

  @override
  Parser text() {
    return super.text().map((value) => TextExpression(value));
  }

  @override
  Parser<InlineBracket> inline() {
    return super.inline().map((value) {
      final inlineContent = value[1];
      if(inlineContent is ExpressionContent) {
        return InlineBracket(inlineContent);
      } else if(inlineContent is LiteralArg) {
        return InlineBracket(inlineContent.toExpressionContent());
      }
      throw UnimplementedError('Inline content type `${inlineContent.runtimeType}` is not expected');
    });
  }

  @override
  Parser<BlockExpression> block() {
    return super.block().callCC((continuation, context) {
      final res = continuation(context);
      // We filter for failures and filter against an expected failure message.
      if(res.isFailure && res.message != '"{{#" expected') {
        debugPrint(
          'Parse Failure: $res\n'
          '${res.message}'
        );
        // Trigger the exception throwing mechanism by attempting to access `value`.
        res.value;
      }
      return res;
    }).map((value) {
      final helper = ((){
        final fn = value[1];
        if(fn is HelperFunction) {
          return fn;
        } else if (fn is HelperFunctionOrVariableRef) {
          /// This conversion is fine as long we have determined the identifier
          /// for `fn` at an earlier point to be ambigous as a helper function and
          /// a variable. At this point we are just narrowing down the type it is
          /// allowed to be within the context of the current template.
          return fn.asFunction();
        } else {
          throw Exception('`${fn.runtimeType}` could not be converted to a `$HelperFunction`');
        }
      })();
      final openingTag = helper.name;
      final closingTag = value[5];
      if(openingTag != closingTag) {
        throw Exception('Closing tag `$closingTag` does not match opening tag `$openingTag`.');
      }
      return BlockExpression.withChildren(
        function: helper,
        children: /**mustache (children) */ value[3]
      );
    });
  }

  @override
  Parser args() {
    return super.args()
    .map(
      (value) {
        isPositionalArg(arg) => arg[0][0] ==  'positionalArg';
        isNamedArg(arg) => arg[0][0] ==  'namedArg';
        var current = value;
        var positionalArgList = [];
        var namedArgList = [];
        dynamic next;
        while(current != null) {
          if(isPositionalArg(current)) {
            positionalArgList.add(current[0]);
            if(current.length > 1) {
              next = current[1];
            }
            current = next;
            continue;
          } else if(isNamedArg(current)) {
            namedArgList.addAll(current);
            break;
          } else {
            throw Exception('Arguments must be positional or named.');
          }
        }
        return ['args', {
          if(positionalArgList.isNotEmpty)
            'positional': positionalArgList.map((e) => e[1] as BracketArgument).toList(),
          if(namedArgList.isNotEmpty)
            'named': namedArgList.fold(<String, BracketArgument>{}, (previousValue, element) {
              final map = previousValue;
              final name = element[1];
              final value = element[2];
              if(map.containsKey(name)) {
                throw Exception('Named argument `$name` was already provided.');
              }
              map[name] = value;
              return map;
            }),
        }];
      }
    );
  }

  @override
  Parser positionalArg() {
    return super.positionalArg().map((value) => ['positionalArg', value]);
  }

  @override
  Parser namedArg() {
    return super.namedArg().map((value) => ['namedArg', value[0], value[2]]);
  }

  @override
  Parser<ExpressionContent> expressionArgs()
  {
    return super.expressionArgs().map((value) {
        final identifierArg = value[0] as IdentifierArg;
        final helperArgs = value[1][1] as Map;

        if(helperArgs.isEmpty) {
          if(identifierArg is PathIdentifierArg && !identifierArg.isAmbiguousIdentifier) {
            // TODO: If this part is reached when parsing a [BlockExpression], then it is invalid since a block cannot be a 
            return VariableRefExpressionContent(identifierArg);
          }
          /// The identifier arg could be for a variable or a helper function.
          /// We cannot know at this point since we do not know which helper
          /// functions are defined in the template linker. If no function
          /// is defined with the identifier, the template linker should assume
          /// it to be a variable type. 
          return HelperFunctionOrVariableRef(identifierArg.identifier);
        } else {
          if(identifierArg is PathIdentifierArg) {
            if(identifierArg.isAmbiguousIdentifier) {
              // Same as the same return statement above...
              return HelperFunctionOrVariableRef(identifierArg.identifier);
            }
            throw Exception(
              'A path identifier that references a context path cannot have arguments.\n'
              'Path identifier: $identifierArg'  
            );
          }
          return HelperFunction(
            identifierArg.identifier,
            /// helperArgs is not an empty map, but there is a chance it does not
            /// include both positional and named aruments.
            args: helperArgs['positional'] ?? [],
            namedArgs: helperArgs['named'] ?? {}
          );
        }
    });
  }

  @override
  Parser<NestedHelperFnArg> nestedHelper() {
    return super.nestedHelper().map((value) => NestedHelperFnArg(/**helper */ value));
  }

  @override
  Parser value() {
    return super.value().map(_returnValueOrExceptIfNotType<BracketArgument>);
  }

  @override
  Parser<LiteralArg> literalValue() {
    return super.literalValue().map(_returnValueOrExceptIfNotType<LiteralArg>);
  }

  @override
  Parser<BooleanArg> boolLiteral() {
    return super.boolLiteral().map((value) => BooleanArg(value == 'true'));
  }

  @override
  Parser<StringArg> stringLiteral() {
    return super.stringLiteral().map((value) => StringArg(value[1]));
  }

  @override
  Parser<NumberArg> numLiteral() {
    return super.numLiteral().map((value) => NumberArg.fromString(value));
  }

  @override
  Parser<IdentifierArg> identifier() {
    return super.identifier().map((value) {
      if(value == '.') {
        return const PathIdentifierArg.currentPath();
      }
      final fromParentPath = value[0] as bool;
      final paths = List<String>.from((value[1] as SeparatedList).elements);
      if(!fromParentPath && paths.length == 1) {
        return HelperFunctionOrVariableRef(paths[0]);
      }
      return PathIdentifierArg(paths, fromParentPath: fromParentPath);
    });
  }
}

typedef VariableRefExpressionContent = EvaluableArgumentExpressionContent<LayoutVariableRef>;

T _returnValueOrExceptIfNotType<T>(value) {
  if(value is! T) {
    throw Exception('`$value` is type of `${value.runtimeType}`, which is not type of `$T`.');
  }
  return value;
}

Parser<TemplateDefinition> getParser() {
  final definition = MustacheGrammerEvaluatorDefinition();
  return definition.build();
}

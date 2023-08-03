import 'package:flutter/material.dart';
import 'package:templuate/src/expressions/arguments/bracket_argument.dart';
import 'package:templuate/src/expressions/arguments/identifier.dart';
import 'package:templuate/src/expressions/arguments/literal.dart';
import 'package:templuate/src/expressions/arguments/nested_helper.dart';
import 'package:templuate/src/expressions/block.dart';
import 'package:templuate/src/expressions/common/helper_function.dart';
import 'package:templuate/src/expressions/expression.dart';
import 'package:templuate/src/expressions/inlines.dart';
import 'package:templuate/src/expressions/text.dart';
import 'package:petitparser/petitparser.dart';

import 'grammer/mustache_grammer_definition.dart';

class HelperFunctionOrVariable {
  final IdentifierArg identifierArg;
  const HelperFunctionOrVariable(this.identifierArg);

  HelperFunction asFunction() => HelperFunction(identifierArg.identifier, args: []);

  String get identifier => identifierArg.identifier;
}

class VariableIdentifier {
  final IdentifierArg identifierArg;
  const VariableIdentifier(this.identifierArg);
}

class InlineHelperOrVariable extends InlineBracket {
  final HelperFunctionOrVariable helperFunctionOrVariable;
  const InlineHelperOrVariable(this.helperFunctionOrVariable);
  
  @override
  // TODO: implement content
  String get content => helperFunctionOrVariable.identifierArg.value;
}

class MustacheGrammerEvaluatorDefinition extends MustacheGrammerDefinition {

  @override
  Parser<List<ValidatedExpression>> start() {
    return super.start().map((value) => value as List<ValidatedExpression>);
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
      if(inlineContent is HelperFunction) {
        return InlineHelper(inlineContent);
      }
      if(inlineContent is LiteralArg) {
        return InlineLiteral(inlineContent.literal);
      }
      if(inlineContent is VariableIdentifier) {
        return InlineVariable(inlineContent.identifierArg);
      }
      if(inlineContent is HelperFunctionOrVariable) {
        return InlineHelperOrVariable(inlineContent);
      }
      throw UnimplementedError('Inline expression of `${inlineContent.runtimeType}` is not expected');
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
        } else if (fn is HelperFunctionOrVariable) {
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
  Parser/*<BracketExpression>
    /*BracketExpression is an expression that can be used between `{{` and `}}`*/
  */
    bracketContent()
  {
    return super.bracketContent().map((value) {
        final identifier = value[0] as IdentifierArg;
        final helperArgs = value[1][1] as Map;

        if(helperArgs.isEmpty) {
          if(identifier is PathIdentifierArg && !identifier.isAmbiguousIdentifier) {
            // TODO: If this part is reached when parsing a [BlockExpression], then it is invalid since a block cannot be a 
            return VariableIdentifier(identifier);
          }
          /// The identifier arg could be for a variable or a helper function.
          /// We cannot know at this point since we do not know which helper
          /// functions are defined in the template linker. If no function
          /// is defined with the identifier, the template linker should assume
          /// it to be a variable type. 
          return HelperFunctionOrVariable(identifier);
        } else {
          if(identifier is PathIdentifierArg) {
            if(identifier.isAmbiguousIdentifier) {
              // Same as the same return statement above...
              return HelperFunctionOrVariable(identifier);
            }
            throw Exception(
              'A path identifier that references a context path cannot have arguments.\n'
              'Path identifier: $identifier'  
            );
          }
          return HelperFunction(
            identifier.identifier,
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
    return super.nestedHelper().map((value) => NestedHelperFnArg(/**helper */ value[1]));
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
        return IdentifierArg(paths[0]);
      }
      return PathIdentifierArg(paths, fromParentPath: fromParentPath);
    });
  }
}

T _returnValueOrExceptIfNotType<T>(value) {
  if(value is! T) {
    throw Exception('`$value` is type of `${value.runtimeType}`, which is not type of `$T`.');
  }
  return value;
}

Parser<List<ValidatedExpression>> getParser() {
  final definition = MustacheGrammerEvaluatorDefinition();
  return definition.build();
}

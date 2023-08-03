import 'dart:collection';

import 'expressions/arguments/bracket_argument.dart';
import 'expressions/arguments/identifier.dart';
import 'expressions/arguments/literal.dart';
import 'expressions/arguments/nested_helper.dart';
import 'expressions/common/helper_function.dart';
import 'expressions/block.dart';
import 'expressions/brackets.dart';
import 'expressions/expression.dart';
import 'expressions/inlines.dart';
import 'expressions/text.dart';

@Deprecated('Use the parser in parser2.dart')
List<ValidatedExpression> parseTemplate(String template) {
  return BracketsOrOtherParse(template).parse();
}

/// TODO: Whitespace control - ref: https://handlebarsjs.com/guide/expressions.html#whitespace-control
class Brackets {
  final String openBrackets;
  final String? tag;
  final String string;
  final String closeBrackets;
  const Brackets({
    required this.openBrackets,
    required this.tag,
    required this.string,
    required this.closeBrackets
  });
}

enum BracketArgumentType {
  any, // index = 0
  identifier, // index = 1
  string, // index = ...
  nestedHelperFn,
  boolean,
  int;
}

class Other {
  final String string;
  const Other(this.string);
}

class BracketsOrOtherParse {
  /// Seperates matches into 6 groups
  /// | Group | Description |
  /// | ----- | ----------- |
  /// | 1 | Open brackets `{` |
  /// | 1 -> 2 | bracket tag (`#`, `>`, `@`, `!`, or `/`) |
  /// | 1 -> 3 | whitespace trimmed string |
  /// | 1 -> 4 | Close brackets `}` |
  /// | 5 | Non-bracketted string |
  /// 
  /// 
  /// Modified from a chatgpt provided regex.
  /// 
  /// Regex from chat gpt.
  /// ```
  /// var regex = RegExp(r'{{.*?}}|[\s\S]+?(?={{|$)');
  /// ```
  static final regexBracketsOrElse = RegExp(r'({+)\s*([#>@!\/]?)\s*(.*?)\s*(}+)|([\s\S]+?(?={|$))');
  /// | Groups | Description |
  /// | ------ | ----------- |
  /// | 1 | indentifier, either a variable or helper function |
  /// | 2 | string literal |
  /// | 3 | nested helper function. Apply regex recursively to match params for helper function. |
  /// 
  static final regexBracketParams = RegExp(r'([a-zA-Z0-9_]+[.a-zA-Z0-9_]*)|"(.*?)"|\((.*)\)');
  final String template;
  const BracketsOrOtherParse(this.template);

  List<ValidatedExpression> parse() {
    final matches = [];
    for (var match in regexBracketsOrElse.allMatches(template)) {
      matches.add(match[1] != null
        ? bracket(match)
        : Other(match[5]!)
      );
    }

    var expressions = <Expression>[];
    
    for(var match in matches) {
      if (match is Brackets) {
        if(match.openBrackets != '{{') {
          throw Exception('Brackets must be a length of 2.');
        }

        final args = arguments(regexBracketParams.allMatches(match.string));
        
        switch (match.tag) {
          case '#':
            // Should be an identifer for a helper function.
            if (args.isEmpty) {
              throw Exception('Helper block is empty.');
            }
            expressions.add(OpenBracket(HelperFunction.fromBracketArgs(args)));
            break;
          case '/':
            // Should just expect an identifier that is not a variable type.
            if (args.isEmpty) {
              throw Exception('Close block is empty.');
            }
            if (args.length > 1) {
                throw Exception('Too many arguments in the close block; one argument is expected.');
            }
            expressions.add(CloseBracket(expectHelperIdentifier(args[0], 'close block').identifier));
            break;
          case null:
          case '':
            // This is an inline bracket.
            // Could be an identifier (either a helper function or variable), or a literal type.
            if(args.isEmpty) {
              // Empty brackets...
              continue;
            }
            expressions.add(InlineBracket.fromBracketArgs(args));
            break;
          default:
            throw Exception('Tag `${match.tag}` is not a valid supported tag.');
        }
      } else if(match is Other) {
        expressions.add(TextExpression(match.string));
      } else {
        throw Exception('${match.runtimeType} is not a proper matched type.');
      }
    }
    return validate(expressions);
  }

  /// TODO: [Match.input] can be to give debug information on the bracket if an error exists.
  static Brackets bracket(Match match) {
    final String openBrackets = match[1]!;
    final String? tag = match[2];
    final String? string = match[3];
    final String closeBrackets = match[4]!;
    if (openBrackets.length != closeBrackets.length) {
      throw Exception('The number of open `{` and close `}` brackets do not match.');
    }
    if (string == null) {
      throw Exception('The bracket does not contain a string.');
    }
    return Brackets(openBrackets: openBrackets, tag: tag, string: string, closeBrackets: closeBrackets);
  }

  static List<BracketArgument> arguments(Iterable<Match> matches) {
    var args = <BracketArgument>[];
    for (var match in matches) {
      // TODO: avoid copy and pasting... use helper function to return first valid BracketArgumentType based on the index, and use a switch block on BracketArgumentType
      final identifier = match.group(BracketArgumentType.identifier.index);
      if (identifier != null) {
        args.add(IdentifierArg(identifier));
      }
      final string = match.group(BracketArgumentType.string.index);
      if (string != null) {
        args.add(StringArg(string));
      }
      final nestedHelperFn = match.group(BracketArgumentType.nestedHelperFn.index);
      if (nestedHelperFn != null) {
        final nestedArgs = arguments(regexBracketParams.allMatches(nestedHelperFn));
        if (nestedArgs.isEmpty) {
          continue;
        }
        args.add(NestedHelperFnArg(HelperFunction.fromBracketArgs(nestedArgs)));
      }
    }
    return args;
  }

  /// Validate the structure of the parsed expressions by ensuring every [OpenBracket] has a matching [CloseBracket].
  ///
  /// Should throw an [Exception] if validation is unsuccessful.
  /// 
  /// Return a list with [OpenBracket] and [CloseBracket] pairs being merged into a [BlockExpression] alongside their enclosed list of [Expression]s.
  static List<ValidatedExpression> validate(List<Expression> expressions) {
    var blocks = Queue<BlockExpression>();
    var validatedExpressions = <ValidatedExpression>[];
    addExpression(ValidatedExpression expression) {
      if (blocks.isNotEmpty) {
        blocks.last.children.add(expression);
      } else {
        validatedExpressions.add(expression);
      }
    }
    for (var expression in expressions) {
      if (expression is OpenBracket) {
        blocks.addLast(BlockExpression(expression.function));
      } else if (expression is CloseBracket) {
        if (blocks.isEmpty) {
          throw Exception('There is no block for `${expression.name}` to close.');
        }
        final block = blocks.removeLast();
        final openIdentifier = block.function.name;
        final closeIdentifier = expression.name;
        if (closeIdentifier != openIdentifier) {
          throw Exception('Close expression `$closeIdentifier` can not close `$openIdentifier` block.');
        }
        // Block is closed.
        addExpression(block);
      } else if (expression is ValidatedExpression) {
        addExpression(expression);
      } else {
        throw Exception('${expression.runtimeType} can not be expressed as $ValidatedExpression');
      }
    }
    if (blocks.isNotEmpty) {
      throw Exception('There are open brackets that do not having a closing pair. Count = ${blocks.length}');
    }
    return validatedExpressions;
  }
}

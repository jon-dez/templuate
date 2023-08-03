import 'arguments/bracket_argument.dart';
import 'arguments/identifier.dart';
import 'arguments/literal.dart';
import 'common/helper_function.dart';
import 'brackets.dart';
import 'expression.dart';

abstract class InlineBracket extends BracketExpression implements ValidatedExpression {
  const InlineBracket();

  /// Expects [args] to not be empty.
  factory InlineBracket.fromBracketArgs(List<BracketArgument> args) {
    /// If first argument is nested helper function, throw error. 
    /// If first argument is a literal, expect no other arguments.
    ///
    /// If first argument is a identifier:
    /// 1. If it is a variable, expect no other arguments.
    /// 2. If it is a helper function, expect other arguments.
    final firstArg = args.first;
    if(firstArg is LiteralArg) {
      if (args.length > 1) {
        throw Exception('No arguments expected after inline literal');
      }
      return InlineLiteral(firstArg.literal);
    } else if(firstArg is IdentifierArg) {
      if (args.length > 1) {
        return InlineHelper(HelperFunction.fromBracketArgs(args));
      }
      return InlineVariable(firstArg);
    } else {
      throw UnimplementedError('Inline block of ${firstArg.runtimeType} is not expected');
    }
  }
}

class InlineHelper extends InlineBracket {
  final HelperFunction function;
  const InlineHelper(this.function);
  
  @override
  String get content => '$function';
}

class InlineLiteral extends InlineBracket {
  final dynamic literal;
  const InlineLiteral(this.literal);
  
  @override
  String get content {
    switch(literal) {
      case String:
        return '"$literal"';
      default:
        throw UnimplementedError('$InlineLiteral does not support `${literal.runtimeType}`.');
    }
  }
}

class InlineVariable extends InlineBracket {
  final IdentifierArg identifierArg;
  const InlineVariable(this.identifierArg);
  
  @override
  String get content => identifierArg.identifier;
}

InlineHelper inlineHelperExpression({
  required String identifier,
  List<BracketArgument> args = const [],
}) {
  return InlineHelper(HelperFunction(identifier, args: args));
}

InlineVariable inlineVariable(String identifier) => InlineVariable(IdentifierArg(identifier));

import 'package:templuate/src/variables.dart';

import '../evaluable.dart';
import '../inlines.dart';

typedef LiteralExpressionContent<T> = EvaluableArgumentExpressionContent<LiteralArg<T>>;

abstract class LiteralArg<T> implements EvaluableArgument<T> {
  final T literal;

  const LiteralArg(this.literal);

  static LiteralArg<T> from<T>(T value) {
    getLiteralArg() {
      switch (value.runtimeType) {
        case String:
          return StringArg(value as String);
        case bool:
        case double:
        case int:
        default:
          throw UnimplementedError('Type `${value.runtimeType}` was not meant to be a literal for templates.');
      }
    }
    return getLiteralArg() as LiteralArg<T>;
  }

  @override
  T eval(WidgetTemplateVariablesContext context) => literal;

  Evaluable<String> toEvaluableString() => StringArg(literal.toString());
  LiteralExpressionContent<T> toExpressionContent() => LiteralExpressionContent<T>(this);
}

class StringArg extends LiteralArg<String> {
  const StringArg(super.literal);

  @override
  String get argString => '"$literal"';
}

class BooleanArg extends LiteralArg<bool> {
  const BooleanArg(super.literal);

  @override
  String get argString => '$literal';
}

class NumberArg<T extends num> extends LiteralArg<T> {
  const NumberArg(super.literal);

  static NumberArg fromString(String numberString) {
    final number = num.parse(numberString);
    if(number is int) {
      return IntArg(number);
    }
    if(number is double) {
      return DoubleArg(number);
    }
    // Unlikley exception to be thrown.
    throw Exception('`${number.runtimeType}` is not a type of `$num`');
  }

  @override
  String get argString => '$literal';
}

typedef IntArg = NumberArg<int>;
typedef DoubleArg = NumberArg<double>;

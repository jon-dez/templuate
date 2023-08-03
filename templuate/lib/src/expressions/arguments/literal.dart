import 'bracket_argument.dart';

abstract class LiteralArg<T> extends BracketArgument {
  T get literal;
  const LiteralArg();

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
}

class StringArg extends LiteralArg<String> {
  final String string;
  const StringArg(this.string);

  @override
  String get value => '"$string"';
  
  @override
  String get literal => string;
}

class BooleanArg extends LiteralArg<bool> {
  final bool boolean;
  const BooleanArg(this.boolean);

  @override
  String get value => '$boolean';

  @override
  bool get literal => boolean;
}

abstract class NumberArg<T extends num> extends LiteralArg<T> {
  T get number;

  const NumberArg();

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
  String get value => '$number';

  @override
  T get literal => number;
}

class IntArg extends NumberArg<int> {
  @override
  final int number;

  const IntArg(this.number);
}

class DoubleArg extends NumberArg<double> {
  @override
  final double number;

  const DoubleArg(this.number);
}

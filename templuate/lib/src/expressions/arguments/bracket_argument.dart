abstract class BracketArgument {
  String get value;

  const BracketArgument();

  @override
  String toString() {
    return '$BracketArgument(type: $runtimeType, value: $value)';
  }
}

abstract class BracketArgumentConvertable {
  BracketArgument toBracketArgument();
}
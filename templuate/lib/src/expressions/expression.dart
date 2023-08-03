abstract class Expression {
  String get expression;
}

/// Result from validating a parsed template expression.
abstract class ValidatedExpression implements Expression {}

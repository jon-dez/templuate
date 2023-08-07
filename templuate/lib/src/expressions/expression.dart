abstract class Expression {
  String get expression;
}

/// Result from validating a parsed template expression.
abstract class ValidatedExpression implements Expression {}

/// The expression arguments within `{{...}}` or `(...)`
/// TODO: Use `sealed` class modifier for exhaustive-switching (https://dart.dev/language/class-modifiers#sealed)
// sealed class ExpressionContent {
abstract class ExpressionContent {
  String get content;
}

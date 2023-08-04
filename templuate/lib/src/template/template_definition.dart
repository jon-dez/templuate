import '../expressions/expression.dart';

/// The template as defined by the parser.
class TemplateDefinition {
  final List<ValidatedExpression> validatedExpressions;
  const TemplateDefinition(this.validatedExpressions);

  @override
  String toString() {
    return validatedExpressions.map((e) => e.expression).join();
  }
}

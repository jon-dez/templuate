import 'expressions/evaluable.dart';
import 'template/template_definition.dart';
import 'variables.dart';
import 'compiler.dart';

typedef TemplatedStringBuilder = String Function(WidgetTemplateVariablesContext context);

extension TemplatedTextLinker on TemplateLinker {
  TemplatedStringBuilder linkTextBuilder(TemplateDefinition templateDefinition) {
    final linkedTemplate = link<String>(templateDefinition.validatedExpressions).map((e) {
      if(e is! EvaluableNode<String>) {
        throw Exception('$e is not an `${EvaluableNode<String>}`.');
      }
      return e;
    });
    return (context) => linkedTemplate.toList().fold(StringBuffer(''),
      (previousValue, element) => previousValue..write(element.eval(context))
    ).toString();
  }
}

import 'package:flutter/widgets.dart';

import '../templuate.dart';

extension TemplatedWidgetLinker on TemplateLinker {
  /// Filters out all linked [TemplateNode]s that do not have [TemplateNode.enclosedType] of [Widget].
  TemplatedWidgetBuilder linkWidgetBuilder(TemplateDefinition templateDefinition) {
    final linkedTemplate = link(templateDefinition.validatedExpressions);
    debugPrint('Linked template successfully: $templateDefinition');
    return (templateData) => TemplatedWidget(
      layoutData: templateData, templateNodes: linkedTemplate.whereType<WidgetTemplateNode>().toList()
    );
  }
}
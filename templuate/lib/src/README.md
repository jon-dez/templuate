# Widget Templating

## Documentation

### Design

#### Compiling

1. String representation of template
<!-- TODO: Change the output of List<ValidatedExpression> to be WidgetTemplateDefinition -->
2. Parse string representation with `petitparser` into `List<ValidatedExpression>`, which is the template defined by the string.
3. Link each `ValidatedExpression` to a `WidgetTemplateNode`.

#### Rendering

1. For each `WidgetTemplateNode` 

## API
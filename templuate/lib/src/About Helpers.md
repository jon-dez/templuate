# About Helpers

- [Block Helpers](#block-helpers)
- [Inline Helpers](#inline-helpers)
- [Nested Helpers](#nested-helpers)

A helper is an **identifier** followed by **arguments**. At least one argument is used to define a helper, but can be any number of positional and named arguments. All positional arguments must precede all named arguments. The data type of an argument is defined within the opening and closing arrow brackets (`<` and `>`). For example `<int>` denotes a positional argument of integer and `foo=<int?>` denotes a named argument of the same type, but is optional since a `?` follows the type. An argument can be a literal type, a variable identifier, or a [nested helper](#nested-helpers). A literal type can either be a string literal (surrounded by double quotes), a boolean literal (`true` or `false`), or an integer literal. A variable identifier references data within the data context of a template. A nested helper is a special helper function that can be evaluated to provide an argument for its parent helper function.

The following helper definition will be used for the rest of the document to provide an example for each helper type. 

Definition:
```
foo <int> bar=<bool>
```

- `0`: Positional argument with an integer type.
- `bar`: Named argument with a boolean type.

The following arguments will be used in the examples:
```
16 bar=false
```

## Block Helpers

Structure:
```
{{#<identifier> <arguments>}}
    ...
{{/<identifier>}}
```

Structure with example definition and arguments:
```
{{#foo 16 bar=false}}
    ...
{{/foo}}
```

## Inline Helpers

Structure:
```
{{<identifier> <arguments>}}
```

Structure with example definition and arguments:
```
{{foo 16 bar=false}}
```

## Nested Helpers

Structure:
```
(<identifier> <arguments>)
```

Structure with example definition and arguments:
```
(foo 16 bar=false)
```

A nested helper is an argument type that can evaluate to any value, but it must be a value that a helper can accept as an argument.

# Helpers Documentation

- [Helpers](#helpers)
    - [Block Helpers](#block-helpers)
        - [each](#each)
        - [conditional](#conditional)
            - [Using else](#using-else)
        - [void](#void)
    - [Inline Helpers](#inline-helpers)
        - [void](#void-1)
    - [Nested Helpers](#nested-helpers)
        - [hasElement](#haselement)
        - [each](#each-1)

## Helpers

Read about helpers at [About Helpers](./About%20Helpers.md)

## Block Helpers

#### each

##### Definition
```
each <any[]>
```

Repeat what is inside the block helper for each element in the list.

#### conditional
##### Definition
```
conditional <bool>
```

Display what is inside the block helper if the boolean evaluate to true.

##### Using [else](./Inlines.md#else)

```
{{#conditional true}}
    This will be displayed.
{{else}}
    This will not be displayed.
{{/conditional}}
```


#### void

Accepts and evaluates any arguments and any children into a void of nothingness.

### Inline Helpers

#### void

Accepts and evaluates any argument into a void of nothingness.

### Nested Helpers

#### each

#### Definition

```
each <any[]> <NestedHelper>
```

Positional Args:

0. An iterable value.
1. A nested helper.

Executes a nested helper for every element in the iterable value, and returns a list of values returned from the execution of the nested helper.

The nested helper is scoped within a new context, which is the element of the current iteration. If the element is a map-like object, then it is possible to use [identifiers](./Identifiers.md) to select values within the map-like object. The element of the current iteration can be accessed by using `.` as the variable identifier, AKA the [current context identifier](./Identifiers.md#current-context-identifier).

#### debugPrint

##### Definition

```
debugPrint <string>
```

Prints a string using flutter's debugPrint.

Returns into a void.

#### hasElement

##### Definition

```
hasElement <any[]>
```

Evaluate to `true` if the list has at least one element.

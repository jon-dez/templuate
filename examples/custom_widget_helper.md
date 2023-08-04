# Custom widget helper

## Create a custom helper, e.g. TextHelper

`build_runner` input: `text.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:templuate/templuate.dart';
import 'package:templuate_annotations/templuate_annotations.dart';

part 'text.g.dart';

class TextHelper extends WidgetInlineHelper<TextHelperArgs> {
  TextHelper() : super('text',
    (args) {
      alignment() {
        switch (args.alignment) {
          case 'center':
            return TextAlign.center;
          case 'left':
            return TextAlign.left;
          case 'right':
            return TextAlign.right;
          case null:
            return null;
          default:
            throw Exception('$TextAlign `${args.alignment}` is not valid.');
        }
      }

      overflow() {
        switch(args.overflow) {
          case 'clip': return TextOverflow.clip;
          case 'ellipsis': return TextOverflow.ellipsis;
          case 'fade': return TextOverflow.fade;
          case 'visible': return TextOverflow.visible;
          case null: return null;
          default: throw Exception('$TextOverflow `${args.overflow}` is not valid.');
        }
      }

      return Text(args.text, textAlign: alignment(), maxLines: args.maxLines, overflow: overflow(),);
    }
  );

  @override
  Evaluable<TextHelperArgs> create(HelperParameters arguments) {
    arguments.expectNotEmpty();
    return TextHelperArgsEvaluable.fromArguments(arguments);
  }
}

@inlineHelper
class TextHelperArgs {
  final String text;
  final String? alignment;
  final int? maxLines;
  final String? overflow;
  const TextHelperArgs(this.text, {this.alignment, this.maxLines, this.overflow});
}
```

`build_runner` output: `text.g.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text.dart';

// **************************************************************************
// HelperParametersGenerator
// **************************************************************************

class TextHelperArgsEvaluable implements Evaluable<TextHelperArgs> {
  final Evaluable<String> pos0;
  final Evaluable<String>? alignment;
  final Evaluable<int>? maxLines;
  final Evaluable<String>? overflow;
  const TextHelperArgsEvaluable(this.pos0,
      {required this.alignment,
      required this.maxLines,
      required this.overflow});
  factory TextHelperArgsEvaluable.fromArguments(HelperParameters arguments) {
    return TextHelperArgsEvaluable(arguments.positional(0).asString(),
        alignment: arguments.optional('alignment')?.asString(),
        maxLines: arguments.optional('maxLines')?.asInt(),
        overflow: arguments.optional('overflow')?.asString());
  }
  @override
  TextHelperArgs eval(WidgetTemplateVariablesContext variablesContext) {
    return TextHelperArgs(pos0.eval(variablesContext),
        alignment: alignment?.eval(variablesContext),
        maxLines: maxLines?.eval(variablesContext),
        overflow: overflow?.eval(variablesContext));
  }
}
```

## Create custom compiler

```dart
import 'package:templuate/templuate.dart';

import './text.dart';

WidgetTemplateCompiler getCustomCompiler() {
    return WidgetTemplateCompiler()
        ..addHelper(TextHelper());
}
```

## Compile and link template

TODO: Write more documentation

```dart

```

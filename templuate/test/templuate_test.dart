// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:templuate/src/expressions/bracket_arguments/identifier_args/helper_function_or_variable.dart';
import 'package:templuate/src/expressions/bracket_expression.dart';
import 'package:templuate/src/expressions/expression.dart';

import 'package:templuate/templuate.dart';

import 'package:petitparser/debug.dart';

TypeMatcher<B> isBracketExpression<B extends BracketExpression>() {
  return isA<B>();
}

TypeMatcher<B> isBracketExpressionWithContent<B extends BracketExpression, E extends ExpressionContent>(
  [TypeMatcher<E> Function(TypeMatcher<E> contentMatcher)? contentMatcher]
) {
  return isA<B>().having((p0) => p0.content,
    'content', contentMatcher == null ? isA<E>() : contentMatcher(isA())
  );
}

void main() {
  group('Parse', () {
    final parser = getParser();
    parseTemplate(String template) => parser.parse(template).value;
    test('Open and close pairs.', () {
      const goods = [
        '{{#test}}{{/test}}',
        '{{#test}}{{/test}}{{#test1}}{{/test1}}',
        '{{#test}}{{#test1}}{{/test1}}{{/test}}',
      ];
      const bads = [
        '{{#test}}', // no close
        '{{#test}}{{#test1}}', // no close 2
        '{{/test}}', // no open
        '{{/test}}{{/test1}}', // no open 2
        '{{#test}}{{#test1}}{{/test}}{{/test1}}', // mismatched
      ];

      for (var good in goods) {
        parseTemplate(good);
      }

      for (var bad in bads) {
        expect(() => parseTemplate(bad), throwsException);
      }
    });
    test('Nested parsing', () {
      final parsed = parseTemplate('{{#test}}{{#test1}}{{inline}}{{/test1}}{{/test}}');
      final expressions = parsed.validatedExpressions;
      final first = expressions[0] as BlockExpression;
      assert(first.function.name == 'test');
      final second = first.children[0] as BlockExpression;
      assert(second.function.name == 'test1');
    });
    test('Multiple children', () {
      final parser = getParser();
      // final parser = trace(getParser());
      final parsed = parser.parse('{{#test}}{{#test1}}{{/test1}}fadfa{{else}}{{inline}}{{/test}}').value;
      final expressions = parsed.validatedExpressions;
      final parent = expressions[0] as BlockExpression;
      final first = parent.children[0] as BlockExpression;
      assert(first.function.name == 'test1');
      final second = parent.children[1] as dynamic;
      assert(second.text == 'fadfa');
    });
    group('Identifiers', () {
      // final parser = trace(getParser());
      final parser = getParser();
      final isAnInlineVariable = isBracketExpressionWithContent<InlineBracket, VariableRefExpressionContent>();
      final isAnInlineHelper = isBracketExpressionWithContent<InlineBracket, HelperFunction>();
      const isAnInlineHelperMatching = isBracketExpressionWithContent<InlineBracket, HelperFunction>;
      final isAnInlineHelperOrVariable = isBracketExpressionWithContent<InlineBracket, HelperFunctionOrVariable>();
      test('Inline parent variable', () {
        //
        final parsed = parser.parse('{{ ../foo}}').value;
        final expressions = parsed.validatedExpressions;
        final expression0 = expressions[0];
        print(expression0.expression);
        expect(expression0, isAnInlineVariable);
      });

      test('Inline current context variable', () {
        //
        final parsed = parser.parse('{{.}}').value;
        final expressions = parsed.validatedExpressions;
        final expression0 = expressions[0];
        print(expression0.expression);
        expect(expression0, isAnInlineVariable);
      });

      test('Nested helper current context variable', () {
        //
        final parsed = parser.parse('{{t (each . (print .))}}').value;
        final expressions = parsed.validatedExpressions;
        final expression0 = expressions[0];
        print(expression0.expression);
        expect(expression0, isAnInlineHelperMatching((contentMatcher) => contentMatcher.having(
          (p0) => p0.args.firstOrNull, 'arg[0]', isA<NestedHelperFnArg>()
        ),));
      });

      test('Inline variable', () {
        //
        final parsed = parser.parse('{{ ../foo}}{{ ../foo.bar }}').value;
        final expressions = parsed.validatedExpressions;
        final expression0 = expressions[0];
        final expression1 = expressions[1];
        print(expression0.expression);
        print(expression1.expression);
        expect(expression0, isAnInlineVariable);
        expect(expression1, isAnInlineVariable);
      });
      test('Inline helper', () {
        // Contains an argument `bar`, so it must be an inline helper.
        final parsed = parser.parse('{{ foo bar }}').value;
        final expressions = parsed.validatedExpressions;
        final expression = expressions[0];
        expect(expression, isAnInlineHelper);
      });
      test('Inline helper or variable', () {
        /// The identifiers infer an ambiguous bracket expression;
        /// cannot tell if `foo` or `foo.bar` refers to a helper or a variable.
        final parsed = parser.parse('{{ foo }}{{ foo.bar }}').value;
        final expressions = parsed.validatedExpressions;
        final expression0 = expressions[0];
        final expression1 = expressions[1];
        print(expression0.expression);
        expect(expression0, isAnInlineHelperOrVariable);
        print(expression1.expression);
        expect(expression1, isAnInlineHelperOrVariable);
      });
      group('Inline literals', () {
        // TODO
      }, skip: 'TODO');
    });

    group('Helper functions', () {
      group('Nested helper functions', () {
        test('each', () {
          final parser = getParser();
          final template = parser.parse('{{void (each test (debugPrint .))}}').value;
          final compiled = TemplateLinker().linkTemplateDefinition(template);
          compiled({
            'test': ['test0', 'test1', 'test2']
          });
        });
      });
    });
  });

  group('link', () {
    final linker = TemplateLinker();
    linker.addHelper(TestHelper());
    linker.addNestedHelper('testNested', (args) {
      return (ctx) {
        return 'test1234';
      };
    });

    final parser = getParser();
    group('literals', () { });

    group('variables', () { });

    group('helpers', () {
      test('nested helper', () {
        final res = parser.parse('{{test (testNested "hello")}}').value;
        linker.linkTemplateDefinition(res);
      });
    });
  });
}

class TestHelper extends WidgetInlineHelper<String> {
  TestHelper(): super('test',
    (x) => Text(x)
  );

  @override
  Evaluable<String> create(HelperParameters arguments) {
    return arguments.positional(0).asBoundNestedHelperFnArg<String>();
  }
}

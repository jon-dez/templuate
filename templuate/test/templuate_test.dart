// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:templuate/templuate.dart';

import 'package:petitparser/debug.dart';


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
      test('Inline parent variable', () {
        //
        final parsed = parser.parse('{{ ../foo}}').value;
        final expressions = parsed.validatedExpressions;
        final expression0 = expressions[0];
        print(expression0.expression);
        expect(expression0, isA<InlineVariable>());
      });

      test('Inline current context variable', () {
        //
        final parsed = parser.parse('{{.}}').value;
        final expressions = parsed.validatedExpressions;
        final expression0 = expressions[0];
        print(expression0.expression);
        expect(expression0, isA<InlineVariable>());
      });

      test('Nested helper current context variable', () {
        //
        final parsed = parser.parse('{{t (each . (print .))}}').value;
        final expressions = parsed.validatedExpressions;
        final expression0 = expressions[0];
        print(expression0.expression);
        expect(expression0, isA<InlineHelper>());
        expression0 as InlineHelper;
        expression0.function.args.first as NestedHelperFnArg;
      });

      test('Inline variable', () {
        //
        final parsed = parser.parse('{{ ../foo}}{{ ../foo.bar }}').value;
        final expressions = parsed.validatedExpressions;
        final expression0 = expressions[0];
        final expression1 = expressions[1];
        print(expression0.expression);
        print(expression1.expression);
        expect(expression0, isA<InlineVariable>());
        expect(expression1, isA<InlineVariable>());
      });
      test('Inline helper', () {
        // Contains an argument `bar`, so it must be an inline helper.
        final parsed = parser.parse('{{ foo bar }}').value;
        final expressions = parsed.validatedExpressions;
        final expression = expressions[0];
        expect(expression, isA<InlineHelper>());
      });
      test('Inline helper or variable', () {
        /// The identifiers infer an ambiguous bracket expression;
        /// cannot tell if `foo` or `foo.bar` refers to a helper or a variable.
        final parsed = parser.parse('{{ foo }}{{ foo.bar }}').value;
        final expressions = parsed.validatedExpressions;
        final expression0 = expressions[0];
        final expression1 = expressions[1];
        print(expression0.expression);
        expect(expression0, isA<InlineHelperOrVariable>());
        print(expression1.expression);
        expect(expression1, isA<InlineHelperOrVariable>());
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
          final compiled = WidgetTemplateCompiler().linkTemplateDefinition(template);
          compiled({
            'test': ['test0', 'test1', 'test2']
          });
        });
      });
    });
  });
}

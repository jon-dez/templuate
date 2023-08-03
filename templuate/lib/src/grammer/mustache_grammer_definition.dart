import 'package:petitparser/petitparser.dart';

/// TODO: To track where parsing errors occur, perhaps do `parser | any().callCC((continuation, context) {... throw error; })`
class MustacheGrammerDefinition extends GrammarDefinition {
  final namingValidStartPattern = pattern('a-zA-Z');
  final namingValidEndPattern = pattern('a-zA-Z0-9_');

  Parser _namePattern() =>
      namingValidStartPattern.seq(namingValidEndPattern.star());

  @override
  Parser start() => ref0(mustache).end();

  Parser mustache() => (ref0(text) | ref0(inline) | ref0(block)
      // | (ref0(inverted));
      )
      .star();
  Parser open() => string('{{');
  Parser close() => string('}}');
  Parser text() =>
      (ref0(open).not() & ref0(close).not() & any()).plus().flatten();

  Parser inline() =>
      (ref0(open) & (ref0(bracketContent) | ref0(value)).trim() & ref0(close));

  /// Parse the positional and named arguments.
  ///
  /// Check if the input is a named argument. If it is, then there are
  /// no more positional arguments (since they must appear first) and continue
  /// checking for more named arguments. If it is not a named argument
  /// it must be a positional argument, so parse the positional argument
  /// and continue by recursively applying this parsing step.s
  Parser _args() =>
      ref0(namedArg).plus() | (ref0(positionalArg) & ref0(_args)).optional().trim();

  Parser args() => _args();

  Parser positionalArg() => ref0(value) | ref0(nestedHelper);

  Parser bracketContent() => (ref0(identifier).trim() & ref0(args).optional());
  Parser nestedHelper() => (char('(') & ref0(bracketContent) & char(')'));

  Parser value() => ref0(literalValue) | ref0(identifier);
  Parser name() => ref0(_namePattern).flatten();
  Parser literalValue() =>
      ref0(stringLiteral) | ref0(boolLiteral) | ref0(numLiteral);
  Parser namedArg() => ref0(name).trim() & char('=') & ref0(value).trim();

  Parser stringLiteral() =>
      (char('"') & any().starLazy(char('"')).flatten() & char('"'));

  Parser boolLiteral() => string('true') | string('false');

  Parser numLiteral() => digit().plus().flatten();

  Parser block() => (string('{{#') &
      ref0(bracketContent) &
      ref0(close) &
      ref0(mustache) &
      string('{{/') &
      ref0(name).trim() &
      ref0(close));
  // Parser inverted() => (string('{{^') & ref0(tag) & string('}}') & ref0(mustache).star() & string('{{/}}')).map((values) => ['inverted', values[1], values[2]]);
  /// TODO: `(string('../') | string('./')).optional()...`
  Parser identifier() => (
      string('../').optional().map((value) => value != null)
      &
      ref0(name).plusSeparated(char('.'))
    ).or(char('.'))
  ;
}

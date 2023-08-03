import 'package:petitparser/petitparser.dart';

mixin MathExpressionDefinition on GrammarDefinition {
  Parser term() => ref0(add) | ref0(prod);
  Parser add() => ref0(prod) & char('+').trim() & ref0(term);

  Parser prod() => ref0(mul) | ref0(prim);
  Parser mul() => ref0(prim) & char('*').trim() & ref0(prod);

  Parser prim() => ref0(parens) | ref0(number);
  Parser parens() => char('(').trim() & ref0(term) & char(')').trim();

  Parser number() => digit().plus().flatten().trim();
}

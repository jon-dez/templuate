/// A type which means something to the template compiler.
/// 
/// [enclosedType] - The compiled type of the node.
abstract class TemplateNode {
  Type get enclosedType;
}

class Reserved {}

/// Used to denote a compiler keyword
class KeywordNode extends TemplateNode {
  @override
  Type get enclosedType => Reserved;
}

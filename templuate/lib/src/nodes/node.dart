/// A type which means something to the template compiler.
/// 
/// [enclosedType] - The compiled type of the node.
abstract class TemplateNode {}

/// Used to denote something reserved for the compiler.
abstract class Reserved {}

/// Used to denote a compiler keyword.
abstract class KeywordNode implements TemplateNode, Reserved {}

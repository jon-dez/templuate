enum HelperType {
  inline,
  block,
  nested
}

class HelperArgs {
  final HelperType helperType;
  const HelperArgs(this.helperType);
}

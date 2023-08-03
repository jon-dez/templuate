import 'bracket_argument.dart';
import '../common/helper_function.dart';

class NestedHelperFnArg extends BracketArgument {
  final HelperFunction function;

  const NestedHelperFnArg(this.function);

  @override
  String get value => '($function)';
}

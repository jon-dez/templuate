library templuate_annotations;

import 'src/helper_args.dart';
export 'src/helper_args.dart' show HelperArgs;

const inlineHelper = HelperArgs(HelperType.inline);
const blockHelper = HelperArgs(HelperType.block);
const nestedHelper = HelperArgs(HelperType.nested);

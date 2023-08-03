library templuate_generator;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import './src/helper_parameters_generator.dart';

Builder helperParametersGenerator(BuilderOptions options) => SharedPartBuilder(
  [HelperParametersGenerator()], 'helper_parameters_generator'
);

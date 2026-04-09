
import 'package:flutter/material.dart';

import 'app_constants.dart';
import 'dimensions.dart';

TextStyle robotoRegular(BuildContext context) =>  TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontWeight: FontWeight.w400,
  fontSize: Dimensions.fontSizeDefault(context),
);

TextStyle robotoMedium(BuildContext context) => TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontWeight: FontWeight.w500,
  fontSize: Dimensions.fontSizeDefault(context),
);

TextStyle robotoBold(BuildContext context) =>  TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontWeight: FontWeight.w700,
  fontSize: Dimensions.fontSizeDefault(context),
);

TextStyle robotoBlack(BuildContext context) => TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w900,
  fontSize: Dimensions.fontSizeDefault(context),
);
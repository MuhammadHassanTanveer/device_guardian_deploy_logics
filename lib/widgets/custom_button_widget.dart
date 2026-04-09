import 'package:flutter/material.dart';
import '../util/dimensions.dart';
import '../util/styles.dart';

class CustomButtonWidget extends StatelessWidget {
  final String buttonText;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final double? radius;
  final bool isBold;
  final double? fontSize;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final IconData? icon;
  final String? urduText;

  const CustomButtonWidget({
    super.key,
    required this.buttonText,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.radius,
    this.isBold = true,
    this.fontSize,
    this.margin,
    this.width,
    this.height,
    this.icon,
    this.urduText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 56,
      margin: margin ?? const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius ?? Dimensions.radiusDefault),
          ),
          elevation: 4,
          disabledBackgroundColor: (color ?? Theme.of(context).primaryColor).withValues(alpha: 0.7),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                  ],
                  if (urduText != null)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonText,
                          style: isBold
                              ? robotoBold(context).copyWith(
                                  fontSize: fontSize ?? Dimensions.fontSizeDefault(context),
                                  color: textColor ?? Colors.white,
                                )
                              : robotoRegular(context).copyWith(
                                  fontSize: fontSize ?? Dimensions.fontSizeDefault(context),
                                  color: textColor ?? Colors.white,
                                ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          urduText!,
                          style: robotoRegular(context).copyWith(
                            fontSize: Dimensions.fontSizeSmall(context),
                            color: textColor ?? Colors.white,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      buttonText,
                      style: isBold
                          ? robotoBold(context).copyWith(
                              fontSize: fontSize ?? Dimensions.fontSizeDefault(context),
                              color: textColor ?? Colors.white,
                            )
                          : robotoRegular(context).copyWith(
                              fontSize: fontSize ?? Dimensions.fontSizeDefault(context),
                              color: textColor ?? Colors.white,
                            ),
                    ),
                ],
              ),
      ),
    );
  }
}


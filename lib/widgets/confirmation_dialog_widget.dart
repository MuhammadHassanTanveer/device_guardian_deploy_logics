import 'package:flutter/material.dart';
import '../util/dimensions.dart';
import '../util/styles.dart';

class ConfirmationDialogWidget extends StatelessWidget {
  final String title;
  final String description;
  final String? icon;
  final VoidCallback? onYesPressed;
  final VoidCallback? onNoPressed;
  final String? yesButtonText;
  final String? noButtonText;

  const ConfirmationDialogWidget({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.onYesPressed,
    this.onNoPressed,
    this.yesButtonText,
    this.noButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Image.asset(
                icon!,
                width: 60,
                height: 60,
              ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              title,
              style: robotoBold(context).copyWith(
                fontSize: Dimensions.fontSizeLarge(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              description,
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onNoPressed ?? () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeSmall,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                    child: Text(
                      noButtonText ?? 'No',
                      style: robotoMedium(context).copyWith(
                        fontSize: Dimensions.fontSizeDefault(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onYesPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeSmall,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                    child: Text(
                      yesButtonText ?? 'Yes',
                      style: robotoMedium(context).copyWith(
                        fontSize: Dimensions.fontSizeDefault(context),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


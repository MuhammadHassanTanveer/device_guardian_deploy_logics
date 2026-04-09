import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../util/dimensions.dart';
import '../util/styles.dart';
import 'snack_bar_widget.dart';

class AppUpdateDialog extends StatelessWidget {
  final String downloadUrl;
  final String currentVersion;
  final String newVersion;

  const AppUpdateDialog({
    super.key,
    required this.downloadUrl,
    required this.currentVersion,
    required this.newVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false, // Prevent back button from closing
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Update Icon
              Container(
                padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.system_update,
                  size: 60,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(height: Dimensions.paddingSizeLarge),
              
              // Title
              Text(
                'Update Required',
                style: robotoBold(context).copyWith(
                  fontSize: Dimensions.fontSizeExtraLarge(context),
                  color: colorScheme.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'اپ ڈیٹ ضروری ہے',
                style: robotoBold(context).copyWith(
                  fontSize: Dimensions.fontSizeLarge(context),
                  color: colorScheme.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.paddingSizeSmall),
              
              // Message
              Text(
                'Your app is outdated. Please update to the latest version to continue using Device Guardian.',
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeDefault(context),
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(
                'آپ کی ایپ پرانی ہو چکی ہے۔ براہ کرم ڈیوائس گارڈین استعمال کرنے کے لیے تازہ ترین ورژن میں اپ ڈیٹ کریں۔',
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeSmall(context),
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.paddingSizeDefault),
              
              // Version Info
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Current: $currentVersion',
                      style: robotoRegular(context).copyWith(
                        fontSize: Dimensions.fontSizeSmall(context),
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(width: Dimensions.paddingSizeDefault),
                    Icon(Icons.arrow_forward, size: 16, color: colorScheme.primary),
                    SizedBox(width: Dimensions.paddingSizeDefault),
                    Text(
                      'Latest: $newVersion',
                      style: robotoMedium(context).copyWith(
                        fontSize: Dimensions.fontSizeSmall(context),
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Dimensions.paddingSizeLarge),
              
              // Download Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchDownloadUrl(context),
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: Column(
                    children: [
                      Text(
                        'Download Update',
                        style: robotoBold(context).copyWith(
                          color: Colors.white,
                          fontSize: Dimensions.fontSizeDefault(context),
                        ),
                      ),
                      Text(
                        'اپ ڈیٹ ڈاؤن لوڈ کریں',
                        style: robotoRegular(context).copyWith(
                          color: Colors.white,
                          fontSize: Dimensions.fontSizeSmall(context),
                        ),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSizeDefault,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                  ),
                ),
              ),
              SizedBox(height: Dimensions.paddingSizeSmall),
              
              // Note
              Text(
                'You cannot use this app until you update.',
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall(context),
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'آپ اپ ڈیٹ کیے بغیر یہ ایپ استعمال نہیں کر سکتے۔',
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall(context),
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchDownloadUrl(BuildContext context) async {
    final Uri uri = Uri.parse(downloadUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          showCustomSnackBar(context, 'Could not open download link', isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCustomSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }
}

/// Show the app update dialog - this is a non-dismissible dialog
void showAppUpdateDialog(BuildContext context, {
  required String downloadUrl,
  required String currentVersion,
  required String newVersion,
}) {
  showDialog(
    context: context,
    barrierDismissible: false, // Cannot dismiss by tapping outside
    builder: (context) => AppUpdateDialog(
      downloadUrl: downloadUrl,
      currentVersion: currentVersion,
      newVersion: newVersion,
    ),
  );
}




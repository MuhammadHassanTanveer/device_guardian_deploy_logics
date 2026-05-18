import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/snack_bar_widget.dart';

import '../models/app_version_model.dart';
import '../providers/home_provider.dart';
import '../util/dimensions.dart';
import '../util/styles.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.tertiaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // App Bar Card
              Card(
                elevation: 5,
                margin: EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "Help & Support",
                          style: robotoBold(context).copyWith(
                            fontSize: Dimensions.fontSizeOverLarge(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Consumer<HomeProvider>(
                    builder: (context, homeProvider, child) {
                      final appVersionData = homeProvider.appVersionData;
                      final createdByUser = homeProvider.createdByUser;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.support_agent,
                                size: 60,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          Center(
                            child: Text(
                              "We're here to help!",
                              style: robotoBold(context).copyWith(
                                fontSize: Dimensions.fontSizeExtraLarge(context),
                                color: colorScheme.tertiary,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Center(
                            child: Text(
                              "ہم آپ کی مدد کے لیے حاضر ہیں",
                              style: robotoRegular(context).copyWith(
                                fontSize: Dimensions.fontSizeDefault(context),
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          
                          // Contact Cards
                          _buildContactCard(
                            context,
                            icon: Icons.phone,
                            title: "Sales Phone",
                            urduTitle: "سیلز فون",
                            value: appVersionData?.salePhone ?? 'N/A',
                            onTap: () => _makePhoneCall(context, appVersionData?.salePhone ?? ''),
                            onCopy: () => _copyToClipboard(context, appVersionData?.salePhone ?? ''),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          
                          _buildContactCard(
                            context,
                            icon: Icons.support_agent,
                            title: "Support Phone",
                            urduTitle: "سپورٹ فون",
                            value: appVersionData?.supportPhone ?? 'N/A',
                            onTap: () => _makePhoneCall(context, appVersionData?.supportPhone ?? ''),
                            onCopy: () => _copyToClipboard(context, appVersionData?.supportPhone ?? ''),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          
                          _buildContactCard(
                            context,
                            icon: Icons.email,
                            title: "Email",
                            urduTitle: "ای میل",
                            value: appVersionData?.email ?? 'N/A',
                            onTap: () => _sendEmail(context, appVersionData?.email ?? ''),
                            onCopy: () => _copyToClipboard(context, appVersionData?.email ?? ''),
                          ),

                          if (createdByUser != null) ...[
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                            _buildCreatedByUserCard(context, createdByUser),
                          ],

                          const SizedBox(height: Dimensions.paddingSizeLarge),

                          // Quick Actions
                          Text(
                            "Quick Actions",
                            style: robotoBold(context).copyWith(
                              fontSize: Dimensions.fontSizeLarge(context),
                              color: colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  context,
                                  icon: Icons.call,
                                  label: "Call Sales",
                                  urduLabel: "سیلز کال",
                                  onTap: () => _showContactDialog(
                                    context,
                                    title: "Contact Sales",
                                    urduTitle: "سیلز سے رابطہ",
                                    phoneNumber: appVersionData?.salePhone ?? '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeSmall),
                              Expanded(
                                child: _buildActionButton(
                                  context,
                                  icon: Icons.headset_mic,
                                  label: "Call Support",
                                  urduLabel: "سپورٹ کال",
                                  onTap: () => _showContactDialog(
                                    context,
                                    title: "Contact Support",
                                    urduTitle: "سپورٹ سے رابطہ",
                                    phoneNumber: appVersionData?.supportPhone ?? '',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatedByUserCard(
    BuildContext context,
    CreatedByUserModel createdByUser,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final phoneNumber = createdByUser.contactNumber;
    final companyNameUrdu = createdByUser.companyNameUrdu?.trim() ?? '';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: Icon(
                    Icons.business,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Created By",
                        style: robotoBold(context).copyWith(
                          fontSize: Dimensions.fontSizeDefault(context),
                          color: colorScheme.tertiary,
                        ),
                      ),
                      Text(
                        "(تخلیق کنندہ)",
                        style: robotoRegular(context).copyWith(
                          fontSize: Dimensions.fontSizeSmall(context),
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _buildCreatedByInfoRow(
              context,
              label: "Company Name",
              urduLabel: "کمپنی کا نام",
              value: createdByUser.companyName,
            ),
            if (companyNameUrdu.isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _buildCreatedByInfoRow(
                context,
                label: "Company Name (Urdu)",
                urduLabel: "کمپنی کا نام (اردو)",
                value: companyNameUrdu,
              ),
            ],
            const SizedBox(height: Dimensions.paddingSizeSmall),
            InkWell(
              onTap: () => _makePhoneCall(context, phoneNumber),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCreatedByInfoRow(
                        context,
                        label: "Phone Number",
                        urduLabel: "فون نمبر",
                        value: phoneNumber.isNotEmpty ? phoneNumber : 'N/A',
                      ),
                    ),
                    if (phoneNumber.isNotEmpty)
                      IconButton(
                        onPressed: () =>
                            _copyToClipboard(context, phoneNumber),
                        icon: Icon(
                          Icons.copy,
                          size: 20,
                          color: theme.hintColor,
                        ),
                        tooltip: 'Copy',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatedByInfoRow(
    BuildContext context, {
    required String label,
    required String urduLabel,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: robotoBold(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "($urduLabel)",
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeExtraSmall(context),
                color: theme.hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : 'N/A',
          style: robotoRegular(context).copyWith(
            fontSize: Dimensions.fontSizeDefault(context),
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String urduTitle,
    required String value,
    required VoidCallback onTap,
    required VoidCallback onCopy,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: robotoBold(context).copyWith(
                            fontSize: Dimensions.fontSizeDefault(context),
                            color: colorScheme.tertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "($urduTitle)",
                          style: robotoRegular(context).copyWith(
                            fontSize: Dimensions.fontSizeSmall(context),
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: robotoRegular(context).copyWith(
                        fontSize: Dimensions.fontSizeLarge(context),
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: Icon(
                  Icons.copy,
                  size: 20,
                  color: theme.hintColor,
                ),
                tooltip: 'Copy',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String urduLabel,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
            vertical: Dimensions.paddingSizeDefault,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: colorScheme.primary,
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(
                label,
                style: robotoBold(context).copyWith(
                  fontSize: Dimensions.fontSizeSmall(context),
                  color: colorScheme.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                urduLabel,
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall(context),
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDialog(
    BuildContext context, {
    required String title,
    required String urduTitle,
    required String phoneNumber,
  }) {
    if (phoneNumber.isEmpty || phoneNumber == 'N/A') {
      showCustomSnackBar(context, "Phone number not available", isError: true);
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outerContext = context;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.contact_phone,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: robotoBold(dialogContext).copyWith(
                  fontSize: Dimensions.fontSizeLarge(dialogContext),
                  color: colorScheme.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                urduTitle,
                style: robotoRegular(dialogContext).copyWith(
                  fontSize: Dimensions.fontSizeSmall(dialogContext),
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Phone number display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      phoneNumber,
                      style: robotoBold(dialogContext).copyWith(
                        fontSize: Dimensions.fontSizeDefault(dialogContext),
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  // Phone Call Button
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _makePhoneCall(outerContext, phoneNumber);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Phone",
                              style: robotoBold(dialogContext).copyWith(
                                fontSize: Dimensions.fontSizeDefault(dialogContext),
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "فون",
                              style: robotoRegular(dialogContext).copyWith(
                                fontSize: Dimensions.fontSizeSmall(dialogContext),
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // WhatsApp Button
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _openWhatsApp(outerContext, phoneNumber);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366), // WhatsApp green
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.message,
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "WhatsApp",
                              style: robotoBold(dialogContext).copyWith(
                                fontSize: Dimensions.fontSizeDefault(dialogContext),
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "واٹس ایپ",
                              style: robotoRegular(dialogContext).copyWith(
                                fontSize: Dimensions.fontSizeSmall(dialogContext),
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        );
      },
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isEmpty || text == 'N/A') {
      showCustomSnackBar(context, "Nothing to copy", isError: true);
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    showCustomSnackBar(context, "Copied to clipboard", isError: false);
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == 'N/A') {
      showCustomSnackBar(context, "Phone number not available", isError: true);
      return;
    }
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri phoneUri = Uri.parse('tel:$cleanNumber');
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      showCustomSnackBar(context, "Could not launch phone dialer", isError: true);
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    if (email.isEmpty || email == 'N/A') {
      showCustomSnackBar(context, "Email not available", isError: true);
      return;
    }
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': 'Support Request - Device Guardian',
        },
      );
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      showCustomSnackBar(context, "Could not launch email app", isError: true);
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == 'N/A') {
      showCustomSnackBar(context, "Phone number not available", isError: true);
      return;
    }
    try {
      // Remove spaces and special characters, keep only digits and +
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      showCustomSnackBar(context, "Could not open WhatsApp", isError: true);
    }
  }
}






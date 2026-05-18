import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/snack_bar_widget.dart';

import '../models/customer_emi_model.dart';
import '../providers/customer_provider.dart';
import '../util/app_constants.dart';
import '../util/dimensions.dart';
import '../util/styles.dart';
import '../widgets/custom_text_field_widget.dart';

// Social App Model
class SocialApp {
  final String name;
  final String commandName;
  final IconData icon;
  final Color color;

  const SocialApp({
    required this.name,
    required this.commandName,
    required this.icon,
    required this.color,
  });
}

// Info Grid Item Model for details tab
class _InfoGridItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoGridItem(this.icon, this.label, this.value);
}

// List of all supported social apps
const List<SocialApp> allSocialApps = [
  SocialApp(
    name: 'Facebook',
    commandName: 'facebook',
    icon: Icons.facebook,
    color: Color(0xFF1877F2),
  ),
  SocialApp(
    name: 'Messenger',
    commandName: 'messenger',
    icon: Icons.message,
    color: Color(0xFF00B2FF),
  ),
  SocialApp(
    name: 'WhatsApp',
    commandName: 'whatsapp',
    icon: Icons.chat,
    color: Color(0xFF25D366),
  ),
  SocialApp(
    name: 'WhatsApp Business',
    commandName: 'whatsappbusiness',
    icon: Icons.business,
    color: Color(0xFF128C7E),
  ),
  SocialApp(
    name: 'TikTok',
    commandName: 'tiktok',
    icon: Icons.music_note,
    color: Color(0xFF000000),
  ),
  SocialApp(
    name: 'Instagram',
    commandName: 'instagram',
    icon: Icons.camera_alt,
    color: Color(0xFFE4405F),
  ),
  SocialApp(
    name: 'Snapchat',
    commandName: 'snapchat',
    icon: Icons.camera,
    color: Color(0xFFFFFC00),
  ),
  SocialApp(
    name: 'LinkedIn',
    commandName: 'linkedin',
    icon: Icons.work,
    color: Color(0xFF0A66C2),
  ),
  SocialApp(
    name: 'YouTube',
    commandName: 'youtube',
    icon: Icons.play_circle_filled,
    color: Color(0xFFFF0000),
  ),
  SocialApp(
    name: 'Threads',
    commandName: 'threads',
    icon: Icons.alternate_email,
    color: Color(0xFF000000),
  ),
  SocialApp(
    name: 'X (Twitter)',
    commandName: 'twitter',
    icon: Icons.tag,
    color: Color(0xFF000000),
  ),
  SocialApp(
    name: 'Discord',
    commandName: 'discord',
    icon: Icons.headset_mic,
    color: Color(0xFF5865F2),
  ),
];

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key, required this.customerId});

  final int customerId;

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  late TabController _tabController;

  // Screenshot controller for capturing screen
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturingScreenshot = false;

  // SharedPreferences key for hidden apps
  static const String _hiddenAppsKey = 'hidden_social_apps';

  // Stored PIN code from SharedPreferences
  String? _storedPinCode;

  // State to control SIM details card visibility in Commands tab
  bool _showSimDetailsCardInCommands = false;

  // State to control unlock code visibility in Customer Information section
  bool _isUnlockCodeVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add listener to check PIN when Commands tab is selected
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomerData();
    });
  }

  // Load all customer data in parallel for faster loading
  Future<void> _loadCustomerData() async {
    final provider = context.read<CustomerProvider>();

    // Clear old customer data first to avoid showing stale data
    provider.clearCustomerManagementData();

    // Run all API calls in parallel for faster loading
    await Future.wait([
      provider.getSingleCustomer(context, widget.customerId),
      provider.fetchSingleUserDevicesForCustomer(widget.customerId),
      provider.fetchCustomerEmi(widget.customerId),
      provider.fetchSimDetails(
        widget.customerId,
      ), // Fetch SIM details on screen open
    ]);

    // Fetch location data (country, state, city names) after customer is loaded
    final customer = provider.singleCustomer;
    if (customer != null) {
      await provider.fetchLocationDataForCustomer(
        customer.country,
        customer.state,
      );
    }

    // Check PIN after data is loaded
    _checkAndPrintStoredPin();
  }

  // Method to check PIN when tab changes
  void _onTabChanged() {
    if (_tabController.index == 2) {
      // Commands tab (index 2)
      _checkAndPrintStoredPin();
    }
  }

  // Method to check and print stored PIN from SharedPreferences
  Future<void> _checkAndPrintStoredPin() async {
    final prefs = await SharedPreferences.getInstance();
    _storedPinCode = prefs.getString('pin_code');

    debugPrint('================================================');
    debugPrint('CHECKING PIN CODE FROM SHARED PREFERENCES');
    debugPrint('================================================');

    if (_storedPinCode == null || _storedPinCode!.isEmpty) {
      debugPrint('⚠️ WARNING: PIN CODE IS EMPTY OR NOT SET!');
      debugPrint('Stored PIN: null or empty');
    } else {
      debugPrint('✅ PIN CODE EXISTS IN SHARED PREFERENCES');
      debugPrint('Stored PIN: $_storedPinCode');
    }
    debugPrint('================================================');
  }

  @override
  void dispose() {
    _pinController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // Get list of hidden apps from SharedPreferences
  Future<List<String>> _getHiddenApps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_hiddenAppsKey) ?? [];
  }

  // Add apps to hidden list in SharedPreferences
  Future<void> _addToHiddenApps(List<String> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHidden = prefs.getStringList(_hiddenAppsKey) ?? [];
    final updatedHidden = {...currentHidden, ...apps}.toList();
    await prefs.setStringList(_hiddenAppsKey, updatedHidden);
  }

  // Remove apps from hidden list in SharedPreferences
  Future<void> _removeFromHiddenApps(List<String> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHidden = prefs.getStringList(_hiddenAppsKey) ?? [];
    currentHidden.removeWhere((app) => apps.contains(app));
    await prefs.setStringList(_hiddenAppsKey, currentHidden);
  }

  /// Reusable method to show PIN verification dialog
  /// Returns true if PIN is verified, false otherwise
  Future<bool> _verifyPinWithDialog(String actionName) async {
    _pinController.clear();

    // First, refresh the stored PIN from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('pin_code')?.trim() ?? '';

    debugPrint('================================================');
    debugPrint('PIN VERIFICATION FOR: $actionName');
    debugPrint('Stored PIN in SharedPreferences: "$storedPin"');
    debugPrint('================================================');

    // Check if PIN is set
    if (storedPin.isEmpty) {
      if (!mounted) return false;
      showCustomSnackBar(
        context,
        'PIN is not set. Please set a PIN first.',
        isError: true,
      );
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool isVerifying = false;

        return StatefulBuilder(
          builder: (context, setState) {
            // Helper function to verify PIN
            Future<void> verifyPin() async {
              if (isVerifying) return;

              final enteredPin = _pinController.text.trim();
              debugPrint(
                'Entered PIN: "$enteredPin" | Stored PIN: "$storedPin"',
              );

              if (enteredPin.isEmpty) {
                // Show snackbar using ScaffoldMessenger
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter PIN'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              setState(() => isVerifying = true);

              // Direct comparison with stored PIN
              final bool isMatch = enteredPin == storedPin;

              debugPrint('PIN Match Result: $isMatch');

              if (isMatch) {
                debugPrint('✅ PIN MATCHED!');
                Navigator.of(dialogContext).pop(true);
              } else {
                debugPrint('❌ PIN DOES NOT MATCH!');
                setState(() => isVerifying = false);
                _pinController.clear(); // Clear the wrong PIN

                // Show snackbar using ScaffoldMessenger to ensure it displays
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('PIN does not match. Please try again.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Enter PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please enter your PIN to confirm this action'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => verifyPin(),
                    decoration: const InputDecoration(
                      labelText: 'PIN Code',
                      hintText: 'Enter 4-digit PIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : () => verifyPin(),
                  child: isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );

    return result == true;
  }

  Future<void> _showPinDialog(
    String command,
    String successMessage, {
    bool refreshCustomerAfterSuccess = false,
  }) async {
    final verified = await _verifyPinWithDialog(command);
    if (verified) {
      debugPrint('✅ PIN verified, executing command: $command');
      await _sendCommand(
        command,
        successMessage,
        refreshCustomerAfterSuccess: refreshCustomerAfterSuccess,
      );
    } else {
      debugPrint(
        '❌ PIN not verified or dialog cancelled, command NOT executed',
      );
    }
  }

  Future<void> _sendCommand(
    String status,
    String successMessage, {
    bool refreshCustomerAfterSuccess = false,
    String? loadingCommandKey,
  }) async {
    debugPrint('========================================');
    debugPrint('Sending Command: $status');
    debugPrint('Customer ID: ${widget.customerId}');
    debugPrint('Using API: /mobile/notifications/send');
    if (refreshCustomerAfterSuccess) {
      debugPrint('Will refresh: GET /mobile/customers/${widget.customerId}');
    }
    debugPrint('========================================');

    final provider = context.read<CustomerProvider>();
    final loadingKey = loadingCommandKey ?? status;
    provider.setCommandLoading(loadingKey, true);

    bool ok = false;
    try {
      ok = refreshCustomerAfterSuccess
          ? await provider.sendMobileNotificationAndRefreshCustomer(
              context: context,
              customerId: widget.customerId,
              status: status,
            )
          : await provider.sendMobileNotification(
              customerId: widget.customerId,
              status: status,
            );
    } finally {
      provider.setCommandLoading(loadingKey, false);
    }

    if (!mounted) return;
    showCustomSnackBar(
      context,
      ok ? successMessage : 'Failed to send command',
      isError: !ok,
    );
  }

  // Method to handle Get Location with 2-second delay API call
  Future<void> _handleGetLocation() async {
    final provider = context.read<CustomerProvider>();
    provider.setCommandLoading('get_current_location', true);

    try {
      final ok = await provider.sendMobileNotification(
        customerId: widget.customerId,
        status: 'get_current_location',
      );

      if (!mounted) return;

      if (ok) {
        showCustomSnackBar(
          context,
          'Location request sent. Fetching location...',
          isError: false,
        );

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        final locationFetched = await provider.fetchCustomerLocation(
          widget.customerId,
        );

        if (!mounted) return;

        if (!locationFetched) {
          showCustomSnackBar(
            context,
            provider.locationError ?? 'Failed to fetch location',
            isError: true,
          );
        }
      } else {
        showCustomSnackBar(
          context,
          'Failed to send location command',
          isError: true,
        );
      }
    } finally {
      provider.setCommandLoading('get_current_location', false);
    }
  }

  // Show PIN dialog specifically for Get Location
  Future<void> _showPinDialogForLocation() async {
    final verified = await _verifyPinWithDialog('Get Location');
    if (verified) {
      await _handleGetLocation();
    }
  }

  // Method to handle Get SIM Details with 2-second delay API call
  Future<void> _handleGetSimDetails() async {
    final provider = context.read<CustomerProvider>();
    provider.setCommandLoading('get_sim_details', true);

    try {
      final ok = await provider.sendMobileNotification(
        customerId: widget.customerId,
        status: 'get_sim_details',
      );

      if (!mounted) return;

      if (ok) {
        showCustomSnackBar(
          context,
          'SIM details request sent. Fetching details...',
          isError: false,
        );

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        final simDetailsFetched = await provider.fetchSimDetails(
          widget.customerId,
        );

        if (!mounted) return;

        if (simDetailsFetched) {
          setState(() {
            _showSimDetailsCardInCommands = true;
          });
        } else {
          showCustomSnackBar(
            context,
            provider.simDetailsError ?? 'Failed to fetch SIM details',
            isError: true,
          );
        }
      } else {
        showCustomSnackBar(
          context,
          'Failed to send SIM details command',
          isError: true,
        );
      }
    } finally {
      provider.setCommandLoading('get_sim_details', false);
    }
  }

  // Show PIN dialog specifically for SIM Details
  Future<void> _showPinDialogForSimDetails() async {
    final verified = await _verifyPinWithDialog('Get SIM Details');
    if (verified) {
      await _handleGetSimDetails();
    }
  }

  // Show Add EMI Details Dialog
  Future<void> _showUpdateEmiDetailsDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    final customerId = widget.customerId;

    // Show the dialog and wait for result
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _EmiDetailsDialog(
          colorScheme: colorScheme,
          customerId: customerId,
          customerProvider: customerProvider,
        );
      },
    );

    // Handle result after dialog is fully closed
    if (result != null && mounted) {
      if (result['success'] == true) {
        // Refresh EMI data after successful addition
        await customerProvider.fetchCustomerEmi(customerId);

        showCustomSnackBar(
          context,
          result['message'] ?? 'EMI Details added successfully',
          isError: result['isWarning'] == true,
        );
      } else if (result['error'] != null) {
        showCustomSnackBar(context, result['error'], isError: true);
      }
    }
  }

  // Show Delete EMI Confirmation Dialog
  Future<void> _showDeleteEmiDialog(
    BuildContext context, {
    required String emiId,
  }) async {
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    final customerId = widget.customerId;
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Delete EMI Record',
                  style: robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeLarge(context),
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'قسط کا ریکارڈ حذف کریں',
                  style: robotoRegular(context).copyWith(
                    fontSize: Dimensions.fontSizeDefault(context),
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this EMI record?',
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeDefault(context),
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'کیا آپ واقعی اس قسط کا ریکارڈ حذف کرنا چاہتے ہیں؟',
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeSmall(context),
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This action cannot be undone!',
                            style: robotoBold(context).copyWith(
                              fontSize: Dimensions.fontSizeSmall(context),
                              color: Colors.orange.shade700,
                            ),
                          ),
                          Text(
                            'یہ عمل واپس نہیں ہو سکتا!',
                            style: robotoRegular(context).copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall(context),
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cancel',
                          style: robotoBold(context).copyWith(
                            fontSize: Dimensions.fontSizeDefault(context),
                          ),
                        ),
                        Text(
                          'منسوخ کریں',
                          style: robotoRegular(context).copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall(context),
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Yes, Delete',
                          style: robotoBold(context).copyWith(
                            fontSize: Dimensions.fontSizeDefault(context),
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'ہاں، حذف کریں',
                          style: robotoRegular(context).copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall(context),
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (emiId.isEmpty) {
        showCustomSnackBar(
          context,
          'Unable to delete EMI: EMI ID not found',
          isError: true,
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Call delete API
      final result = await customerProvider.deleteCustomerEmi(emiId: emiId);

      // Hide loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      if (result['success'] == true) {
        // Refresh EMI data after successful deletion
        await customerProvider.fetchCustomerEmi(customerId);

        showCustomSnackBar(
          context,
          result['message'] ?? 'EMI deleted successfully',
          isError: false,
        );
      } else {
        showCustomSnackBar(
          context,
          result['error'] ?? 'Failed to delete EMI',
          isError: true,
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    // First verify admin PIN
    final pinVerified = await _verifyPinWithDialog('Change Screen Password');

    if (!pinVerified) return;

    // Now show the new password dialog
    final newPasswordController = TextEditingController();

    final newPassword = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Enter New Screen Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter 4-digit password for device screen'),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter 4-digit password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.password),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final password = newPasswordController.text;
                if (password.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (password.length != 4) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be 4 digits'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(password);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (newPassword != null && newPassword.isNotEmpty) {
      await _sendCommand(
        'change_password_$newPassword',
        'Screen password changed successfully',
        loadingCommandKey: 'change_screen_password',
      );
    }
  }

  Future<void> _showMessageDialog() async {
    // First verify admin PIN
    final pinVerified = await _verifyPinWithDialog('Send Message');

    if (!pinVerified) return;

    // Now show the message input dialog
    final messageController = TextEditingController();

    final message = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Send Message to Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your message for the customer'),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                keyboardType: TextInputType.multiline,
                maxLines: 8,
                minLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Enter your message here...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final messageText = messageController.text.trim();
                if (messageText.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a message'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(messageText);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (message != null && message.isNotEmpty) {
      final formattedMessage = message.replaceAll(' ', '_');
      await _sendCommand(
        'message_customer_$formattedMessage',
        'Message sent to customer successfully',
        loadingCommandKey: 'send_customer_message',
      );
    }
  }

  Future<void> _showHideAppsDialog() async {
    // First verify admin PIN
    final pinVerified = await _verifyPinWithDialog('Hide Social Apps');

    if (!pinVerified) return;

    // Get already hidden apps
    final hiddenApps = await _getHiddenApps();

    // Filter available apps (exclude already hidden ones)
    final availableApps = allSocialApps
        .where((app) => !hiddenApps.contains(app.commandName))
        .toList();

    if (availableApps.isEmpty) {
      if (!mounted) return;
      showCustomSnackBar(
        context,
        'All apps are already hidden',
        isError: false,
      );
      return;
    }

    // Show app selection dialog
    final selectedApps = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _SocialAppsSelectionDialog(
          title: 'Hide Social Apps',
          urduTitle: 'سوشل ایپس چھپائیں',
          apps: availableApps,
          isHideMode: true,
        );
      },
    );

    if (selectedApps != null && selectedApps.isNotEmpty) {
      // Check if "all" was selected
      final bool isSelectAll = selectedApps.contains('all');

      String command;
      if (isSelectAll) {
        command = 'hide_apps_all';
        // Add all available apps to hidden list
        await _addToHiddenApps(
          availableApps.map((e) => e.commandName).toList(),
        );
      } else {
        command = 'hide_apps_${selectedApps.join('_')}';
        await _addToHiddenApps(selectedApps);
      }

      await _sendCommand(
        command,
        'Hide apps command sent successfully',
        loadingCommandKey: 'hide_social_apps',
      );
    }
  }

  Future<void> _showShowAppsDialog() async {
    // First verify admin PIN
    final pinVerified = await _verifyPinWithDialog('Show Social Apps');

    if (!pinVerified) return;

    // Get hidden apps
    final hiddenApps = await _getHiddenApps();

    // Filter to show only hidden apps
    final hiddenAppsList = allSocialApps
        .where((app) => hiddenApps.contains(app.commandName))
        .toList();

    if (hiddenAppsList.isEmpty) {
      if (!mounted) return;
      showCustomSnackBar(context, 'No hidden apps to show', isError: false);
      return;
    }

    // Show app selection dialog
    final selectedApps = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _SocialAppsSelectionDialog(
          title: 'Show Social Apps',
          urduTitle: 'سوشل ایپس دکھائیں',
          apps: hiddenAppsList,
          isHideMode: false,
        );
      },
    );

    if (selectedApps != null && selectedApps.isNotEmpty) {
      // Check if "all" was selected
      final bool isSelectAll = selectedApps.contains('all');

      String command;
      if (isSelectAll) {
        command = 'show_apps_all';
        // Remove all hidden apps from the list
        await _removeFromHiddenApps(
          hiddenAppsList.map((e) => e.commandName).toList(),
        );
      } else {
        command = 'show_apps_${selectedApps.join('_')}';
        await _removeFromHiddenApps(selectedApps);
      }

      await _sendCommand(
        command,
        'Show apps command sent successfully',
        loadingCommandKey: 'show_social_apps',
      );
    }
  }

  Future<void> _handleReactivateCustomer(CustomerProvider provider) async {
    final customer = provider.singleCustomer;
    if (customer == null || customer.imei1.isEmpty) {
      if (!mounted) return;
      showCustomSnackBar(
        context,
        'Customer IMEI is not available',
        isError: true,
      );
      return;
    }

    final success = await provider.updateCustomerIsActiveStatus(
      imei1: customer.imei1,
      imei2: customer.imei2,
      isActive: 0,
    );

    if (!mounted) return;

    if (success) {
      await provider.fetchCustomers(context, isRefresh: true);

      if (!mounted) return;

      showCustomSnackBar(
        context,
        'Customer re-activated successfully',
        isError: false,
      );

      Navigator.of(context).pop();
    } else {
      showCustomSnackBar(
        context,
        'Failed to re-activate customer',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final customer = provider.singleCustomer;
    final isLoading = customer == null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          isLoading
              ? Container(
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
                  child: const Center(child: CircularProgressIndicator()),
                )
              : Screenshot(
                  controller: _screenshotController,
                  child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 200,
                      floating: false,
                      pinned: true,
                      elevation: 2,
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      leading: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: colorScheme.primary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      title: Text(
                        customer.customerCode.isNotEmpty
                            ? customer.customerCode.toUpperCase()
                            : 'CUST-${customer.id}',
                        style: robotoBold(context).copyWith(
                          color: colorScheme.primary,
                          fontSize: Dimensions.fontSizeLarge(context),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: _isCapturingScreenshot
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : Icon(Icons.share, color: colorScheme.primary),
                          onPressed: _isCapturingScreenshot
                              ? null
                              : () => _captureAndShareScreenshot(customer),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(color: Colors.white),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 56,
                                left: 16,
                                right: 16,
                                bottom: 16,
                              ),
                              child: Row(
                                children: [
                                  // Customer Profile Image
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorScheme.primary,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: customer.profileImage.isNotEmpty
                                          ? Image.network(
                                              '${AppConstants.imageUrl}${customer.profileImage}',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color: colorScheme.primary
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 50,
                                                        color:
                                                            colorScheme.primary,
                                                      ),
                                                    );
                                                  },
                                              loadingBuilder:
                                                  (
                                                    context,
                                                    child,
                                                    loadingProgress,
                                                  ) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Container(
                                                      color: Colors.grey[100],
                                                      child: Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: colorScheme
                                                                  .primary,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                            )
                                          : Container(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.1),
                                              child: Icon(
                                                Icons.person,
                                                size: 50,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // Customer Info
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Customer Name
                                        Text(
                                          customer.customerName,
                                          style: robotoBold(context).copyWith(
                                            color: Colors.grey.shade800,
                                            fontSize:
                                                Dimensions.fontSizeExtraLarge(
                                                  context,
                                                ),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              color: Colors.grey.shade600,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              customer.customerMobileNo,
                                              style: robotoRegular(context)
                                                  .copyWith(
                                                    color: Colors.grey.shade600,
                                                    fontSize:
                                                        Dimensions.fontSizeDefault(
                                                          context,
                                                        ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Status Badges (lock_status and actual_lock_status)
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            // Lock Status Badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: customer.lockStatus
                                                    ? Colors.red
                                                    : Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    customer.lockStatus
                                                        ? Icons.lock
                                                        : Icons.lock_open,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    customer.lockStatus
                                                        ? 'LOCK'
                                                        : 'UNLOCK',
                                                    style: robotoBold(context)
                                                        .copyWith(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Actual Lock Status Badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: customer.actualLockStatus
                                                    ? Colors.deepOrange
                                                    : Colors.lightGreen,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    customer.actualLockStatus
                                                        ? Icons.shield_outlined
                                                        : Icons.shield,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    customer.actualLockStatus
                                                        ? 'ACTUAL LOCK'
                                                        : 'ACTUAL UNLOCK',
                                                    style: robotoBold(context)
                                                        .copyWith(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      bottom: TabBar(
                        controller: _tabController,
                        indicatorColor: colorScheme.primary,
                        indicatorWeight: 3,
                        labelColor: colorScheme.primary,
                        unselectedLabelColor: Colors.grey.shade500,
                        tabs: const [
                          Tab(text: 'Details'),
                          Tab(text: 'Commands'),
                          Tab(text: 'EMI Details'),
                        ],
                      ),
                    ),
                  ];
                },
                body: Container(
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
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDetailsTab(context, provider),
                      _buildCommandsTab(context, provider),
                      _buildEmiDetailsTab(context, provider),
                    ],
                  ),
                ),
              ),
            ),
          if (provider.isRefreshingSingleCustomer)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  /// Wraps off-screen capture tree with MediaQuery for Dimensions and layout.
  Widget _wrapForOffscreenCapture({
    required BuildContext context,
    required double screenWidth,
    required Widget child,
  }) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(size: Size(screenWidth, mediaQuery.size.height)),
      child: Material(
        color: Colors.white,
        child: child,
      ),
    );
  }

  Widget _buildCustomerInitialsCircle(String name, {double radius = 28}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: const Color(0xFF667eea).withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'C',
        style: robotoBold(context).copyWith(
          fontSize: 22,
          color: const Color(0xFF667eea),
        ),
      ),
    );
  }

  // Build header + Details tab only for long screenshot (full scroll height).
  Widget _buildLongScreenshotContent(
    dynamic customer,
    CustomerProvider provider, {
    required double screenWidth,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return _wrapForOffscreenCapture(
      context: context,
      screenWidth: screenWidth,
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: screenWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== APP BAR SECTION ==========
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.arrow_back, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: screenWidth - 16 - 24 - 16 - 24 - 24,
                    child: Text(
                      customer.customerCode.isNotEmpty
                          ? customer.customerCode.toUpperCase()
                          : 'CUST-${customer.id}',
                      style: robotoBold(
                        context,
                      ).copyWith(color: colorScheme.primary, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.share, color: colorScheme.primary, size: 24),
                ],
              ),
            ),

            // ========== CUSTOMER HEADER SECTION ==========
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(color: colorScheme.primary, width: 3),
                    ),
                    child: ClipOval(
                      child: customer.profileImage.isNotEmpty
                          ? Image.network(
                              '${AppConstants.imageUrl}${customer.profileImage}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.person,
                                    size: 45,
                                    color: colorScheme.primary,
                                  ),
                            )
                          : Icon(
                              Icons.person,
                              size: 45,
                              color: colorScheme.primary,
                            ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: screenWidth - 32 - 90 - 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.customerName,
                          style: robotoBold(
                            context,
                          ).copyWith(color: Colors.grey.shade800, fontSize: 20),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              color: Colors.grey.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                customer.customerMobileNo,
                                style: robotoRegular(context).copyWith(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Status Badges
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Lock Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: customer.lockStatus
                                    ? Colors.red
                                    : Colors.green,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    customer.lockStatus
                                        ? Icons.lock
                                        : Icons.lock_open,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    customer.lockStatus ? 'LOCK' : 'UNLOCK',
                                    style: robotoBold(context).copyWith(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Actual Lock Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: customer.actualLockStatus
                                    ? Colors.deepOrange
                                    : Colors.lightGreen,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    customer.actualLockStatus
                                        ? Icons.shield_outlined
                                        : Icons.shield,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    customer.actualLockStatus
                                        ? 'ACTUAL LOCK'
                                        : 'ACTUAL UNLOCK',
                                    style: robotoBold(context).copyWith(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ========== TAB BAR (Details selected) ==========
            _buildScreenshotTabBar(screenWidth, colorScheme.primary),

            // ========== DETAILS TAB (same widgets as on screen) ==========
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colorScheme.surface, colorScheme.tertiaryContainer],
                ),
              ),
              child: _buildDetailsTabContent(
                context,
                provider,
                contentWidth: screenWidth,
                forScreenshot: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Details tab body — shared by scroll view and long screenshot.
  Widget _buildDetailsTabContent(
    BuildContext context,
    CustomerProvider provider, {
    double? contentWidth,
    bool forScreenshot = false,
  }) {
    final customer = provider.singleCustomer!;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer Information Section
        _buildModernCard(
          context: context,
          title: 'Customer Information',
          icon: Icons.person_outline,
          gradientColors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667eea).withValues(alpha: 0.1),
                      const Color(0xFF764ba2).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildCustomerInitialsCircle(customer.customerName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'CUST ID: ',
                                style: robotoBold(context).copyWith(
                                  fontSize: Dimensions.fontSizeSmall(context),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  customer.customerCode.isNotEmpty
                                      ? customer.customerCode.toUpperCase()
                                      : 'N/A',
                                  style: robotoBold(context).copyWith(
                                    fontSize: Dimensions.fontSizeDefault(
                                      context,
                                    ),
                                    color: Colors.grey.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer.customerName,
                            style: robotoBold(context).copyWith(
                              fontSize: Dimensions.fontSizeLarge(context),
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customer.customerMobileNo,
                                style: robotoRegular(context).copyWith(
                                  fontSize: Dimensions.fontSizeSmall(context),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildUnlockCodeInfoItem(
                context,
                customer.unlockCode != null && customer.unlockCode!.isNotEmpty
                    ? customer.unlockCode!
                    : 'N/A',
                const Color(0xFF667eea),
                forScreenshot: forScreenshot,
              ),
              const SizedBox(height: 10),
              _buildInfoGrid(context, [
                _InfoGridItem(
                  Icons.email_outlined,
                  'Email',
                  customer.email.isNotEmpty ? customer.email : 'N/A',
                ),
                _InfoGridItem(
                  Icons.badge_outlined,
                  'CNIC',
                  customer.cnic.isNotEmpty ? customer.cnic : 'N/A',
                ),
              ]),
              const SizedBox(height: 10),
              _buildFullWidthInfoItem(
                context,
                Icons.home_outlined,
                'Address',
                customer.address.isNotEmpty ? customer.address : 'N/A',
                const Color(0xFF667eea),
              ),
              const SizedBox(height: 10),
              _buildInfoGrid(context, [
                _InfoGridItem(
                  Icons.location_city_outlined,
                  'State',
                  provider.getStateNameById(customer.state),
                ),
                _InfoGridItem(
                  Icons.apartment_outlined,
                  'City',
                  provider.getCityNameById(customer.city),
                ),
              ]),
              const SizedBox(height: 10),
              _buildFullWidthInfoItem(
                context,
                Icons.flag_outlined,
                'Country',
                provider.getCountryNameById(customer.country),
                const Color(0xFF667eea),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildModernCard(
          context: context,
          title: 'Device Information',
          icon: Icons.smartphone,
          gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
          child: Column(
            children: [
              _buildInfoGrid(context, [
                _InfoGridItem(
                  customer.mobileType.toLowerCase() == 'android'
                      ? Icons.android
                      : customer.mobileType.toLowerCase() == 'iphone'
                      ? Icons.apple
                      : Icons.phone_android,
                  'Mobile Type',
                  customer.mobileType.isNotEmpty ? customer.mobileType : 'N/A',
                ),
                _InfoGridItem(
                  Icons.phone_android,
                  'Mobile Model',
                  customer.mobileModel != null &&
                          customer.mobileModel!.isNotEmpty
                      ? customer.mobileModel!
                      : 'N/A',
                ),
              ], accentColor: const Color(0xFF11998e)),
              const SizedBox(height: 10),
              _buildFullWidthInfoItem(
                context,
                Icons.tag,
                'Serial',
                customer.serialNo.isNotEmpty ? customer.serialNo : 'N/A',
                const Color(0xFF11998e),
              ),
              const SizedBox(height: 8),
              _buildFullWidthInfoItem(
                context,
                Icons.fingerprint,
                'IMEI 1',
                customer.imei1.isNotEmpty ? customer.imei1 : 'N/A',
                const Color(0xFF11998e),
              ),
              if (customer.imei2 != null && customer.imei2!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildFullWidthInfoItem(
                  context,
                  Icons.fingerprint,
                  'IMEI 2',
                  customer.imei2!,
                  const Color(0xFF11998e),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSimDetailsCard(
          context,
          provider,
          forScreenshot: true,
        ),
      ],
    );

    if (contentWidth != null) {
      content = SizedBox(width: contentWidth, child: content);
    }
    return content;
  }

  Widget _buildScreenshotTabBar(double screenWidth, Color primaryColor) {
    final tabWidth = screenWidth / 3;
    return ColoredBox(
      color: Colors.white,
      child: Row(
        children: [
          _buildScreenshotTab('Details', true, primaryColor, tabWidth),
          _buildScreenshotTab('Commands', false, primaryColor, tabWidth),
          _buildScreenshotTab('EMI Details', false, primaryColor, tabWidth),
        ],
      ),
    );
  }

  Widget _buildScreenshotTab(
    String title,
    bool isSelected,
    Color primaryColor,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryColor : Colors.grey.shade300,
              width: isSelected ? 3 : 1,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: robotoBold(context).copyWith(
            color: isSelected ? primaryColor : Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }


  // Capture screenshot and share
  Future<void> _captureAndShareScreenshot(dynamic customer) async {
    if (_isCapturingScreenshot) return;

    setState(() {
      _isCapturingScreenshot = true;
    });

    try {
      final provider = context.read<CustomerProvider>();

      showCustomSnackBar(
        context,
        'Capturing screenshot...',
        isError: false,
      );

      // Always capture Details tab (header + full scrollable details content).
      if (_tabController.index != 0) {
        _tabController.animateTo(0);
        await Future.delayed(const Duration(milliseconds: 350));
      }

      if (customer.profileImage.isNotEmpty) {
        try {
          await precacheImage(
            NetworkImage(
              '${AppConstants.imageUrl}${customer.profileImage}',
            ),
            context,
          );
        } catch (_) {}
      }

      final mediaQuery = MediaQuery.of(context);
      final screenWidth = mediaQuery.size.width;
      final pixelRatio = mediaQuery.devicePixelRatio;

      // Required: bounded width so Expanded/Flexible children layout correctly.
      final captureConstraints = BoxConstraints(
        minWidth: screenWidth,
        maxWidth: screenWidth,
        maxHeight: double.infinity,
      );

      final Uint8List imageBytes = await _screenshotController
          .captureFromLongWidget(
            _buildLongScreenshotContent(
              customer,
              provider,
              screenWidth: screenWidth,
            ),
            delay: const Duration(milliseconds: 800),
            pixelRatio: pixelRatio,
            context: context,
            constraints: captureConstraints,
          );

      // Get temp directory and save the image
      final directory = await getTemporaryDirectory();
      final customerCode = customer.customerCode.isNotEmpty
          ? customer.customerCode.toUpperCase()
          : 'CUST_${customer.id}';
      final fileName =
          'customer_${customerCode}_${DateTime.now().millisecondsSinceEpoch}.png';
      final imagePath = '${directory.path}/$fileName';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Share the image with text
      final String shareText =
          '''
Customer Details:
Name: ${customer.customerName}
Phone: ${customer.customerMobileNo}
Customer Code: ${customer.customerCode.isNotEmpty ? customer.customerCode.toUpperCase() : 'N/A'}
IMEI: ${customer.imei1}
''';

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: shareText,
        subject: 'Customer Details - ${customer.customerName}',
      );
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showCustomSnackBar(context, 'Error sharing: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingScreenshot = false;
        });
      }
    }
  }

  Widget _buildDetailsTab(BuildContext context, CustomerProvider provider) {
    final customer = provider.singleCustomer;
    final colorScheme = Theme.of(context).colorScheme;

    if (customer == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No customer data available',
              style: robotoRegular(
                context,
              ).copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: _buildDetailsTabContent(context, provider),
    );
  }

  // Modern Card with gradient header
  Widget _buildModernCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeDefault(context),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  // Info Grid - 2 columns using Row with Expanded for equal width
  Widget _buildInfoGrid(
    BuildContext context,
    List<_InfoGridItem> items, {
    Color accentColor = const Color(0xFF667eea),
  }) {
    List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _buildGridInfoItem(context, items[i], accentColor)),
            const SizedBox(width: 10),
            if (i + 1 < items.length)
              Expanded(
                child: _buildGridInfoItem(context, items[i + 1], accentColor),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: 10));
      }
    }
    return Column(children: rows);
  }

  Widget _buildGridInfoItem(
    BuildContext context,
    _InfoGridItem item,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.label,
                  style: robotoMedium(context).copyWith(
                    fontSize: 11,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: robotoMedium(context).copyWith(
              fontSize: Dimensions.fontSizeSmall(context),
              color: Colors.grey.shade800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Full width info item
  Widget _buildFullWidthInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: robotoMedium(context).copyWith(
                    fontSize: 11,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: robotoMedium(context).copyWith(
                    fontSize: Dimensions.fontSizeSmall(context),
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Unlock Code Info Item with toggle visibility
  Widget _buildUnlockCodeInfoItem(
    BuildContext context,
    String unlockCode,
    Color accentColor, {
    bool forScreenshot = false,
  }) {
    // Only mask if unlock code exists and is not 'N/A'
    final shouldMask = unlockCode.isNotEmpty && unlockCode != 'N/A';
    final displayCode = shouldMask && !_isUnlockCodeVisible
        ? '*' * unlockCode.length
        : unlockCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lock_outline, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock Code',
                  style: robotoMedium(context).copyWith(
                    fontSize: 11,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayCode,
                  style: robotoMedium(context).copyWith(
                    fontSize: forScreenshot
                        ? 12
                        : Dimensions.fontSizeSmall(context),
                    color: Colors.grey.shade800,
                    letterSpacing: shouldMask && !_isUnlockCodeVisible ? 1 : 0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (shouldMask && !forScreenshot)
            IconButton(
              icon: Icon(
                _isUnlockCodeVisible ? Icons.visibility : Icons.visibility_off,
                size: 20,
                color: accentColor,
              ),
              onPressed: () {
                setState(() {
                  _isUnlockCodeVisible = !_isUnlockCodeVisible;
                });
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              tooltip: _isUnlockCodeVisible
                  ? 'Hide unlock code'
                  : 'Show unlock code',
            )
          else if (shouldMask && forScreenshot)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _isUnlockCodeVisible ? Icons.visibility : Icons.visibility_off,
                size: 20,
                color: accentColor,
              ),
            ),
        ],
      ),
    );
  }

  // SIM Details Card
  Widget _buildSimDetailsCard(
    BuildContext context,
    CustomerProvider provider, {
    bool forScreenshot = false,
  }) {
    const gradientColors = [Color(0xFF4776E6), Color(0xFF8E54E9)];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sim_card,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SIM Details',
                    style: robotoBold(context).copyWith(
                      fontSize: Dimensions.fontSizeDefault(context),
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!forScreenshot)
                  InkWell(
                    onTap: provider.isSimDetailsLoading
                        ? null
                        : () =>
                            provider.fetchSimDetails(widget.customerId),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.refresh,
                        size: 18,
                        color: provider.isSimDetailsLoading
                            ? Colors.white60
                            : Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: _buildSimCardContent(context, provider),
          ),
        ],
      ),
    );
  }

  // SIM Card Content
  Widget _buildSimCardContent(BuildContext context, CustomerProvider provider) {
    const accentColor = Color(0xFF4776E6);

    if (provider.isSimDetailsLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: accentColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading SIM details...',
              style: robotoRegular(context).copyWith(
                color: Colors.grey.shade500,
                fontSize: Dimensions.fontSizeSmall(context),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.simDetailsError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.simDetailsError!,
                style: robotoRegular(context).copyWith(
                  color: Colors.orange.shade800,
                  fontSize: Dimensions.fontSizeSmall(context),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.simDetailsData == null || provider.simDetailsData!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.sim_card_outlined,
              size: 40,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            Text(
              'No SIM details available',
              style: robotoRegular(context).copyWith(
                color: Colors.grey.shade500,
                fontSize: Dimensions.fontSizeSmall(context),
              ),
            ),
          ],
        ),
      );
    }

    // Display SIM data in grid - only show specific fields
    final allowedFields = [
      'sim_count',
      'sim1_network_name',
      'sim1_number',
      'sim1_country_iso',
      'sim2_network_name',
      'sim2_number',
      'sim2_country_iso',
    ];

    final simEntries = provider.simDetailsData!.entries
        .where((e) => allowedFields.contains(e.key))
        .toList();

    final gridItems = simEntries
        .map(
          (e) => _InfoGridItem(
            _getSimDetailIcon(e.key),
            _formatSimDetailKey(e.key),
            e.value?.toString() ?? 'N/A',
          ),
        )
        .toList();

    return _buildInfoGrid(context, gridItems, accentColor: accentColor);
  }

  // SIM Details Card for Commands Tab with close button
  Widget _buildSimDetailsCardForCommandsTab(
    BuildContext context,
    CustomerProvider provider,
  ) {
    // Only show if the flag is set
    if (!_showSimDetailsCardInCommands) {
      return const SizedBox.shrink();
    }

    const gradientColors = [Color(0xFF4776E6), Color(0xFF8E54E9)];

    return Container(
      margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient Header with close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sim_card,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SIM Details',
                    style: robotoBold(context).copyWith(
                      fontSize: Dimensions.fontSizeDefault(context),
                      color: Colors.white,
                    ),
                  ),
                ),
                // Refresh button
                InkWell(
                  onTap: provider.isSimDetailsLoading
                      ? null
                      : () => provider.fetchSimDetails(widget.customerId),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.refresh,
                      size: 18,
                      color: provider.isSimDetailsLoading
                          ? Colors.white60
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Close button
                InkWell(
                  onTap: () {
                    setState(() {
                      _showSimDetailsCardInCommands = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: _buildSimCardContent(context, provider),
          ),
        ],
      ),
    );
  }

  // Keep old methods for backward compatibility
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeDefault(context),
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: robotoMedium(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: Colors.grey.shade900,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Removed old SIM section methods - using new design

  Widget _buildCommandsTab(BuildContext context, CustomerProvider provider) {
    final customer = provider.singleCustomer;
    final colorScheme = Theme.of(context).colorScheme;

    // If customer isActive is 2, show only re-activate button
    if (customer != null && customer.isActive == 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.app_blocking,
                size: 80,
                color: Colors.red.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 24),
              Text(
                'App Uninstalled',
                style: robotoBold(context).copyWith(
                  fontSize: Dimensions.fontSizeOverLarge(context),
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ایپ ان انسٹال ہو گئی ہے',
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeLarge(context),
                  color: Colors.red.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: provider.isReactivatingCustomer
                      ? null
                      : () => _handleReactivateCustomer(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  icon: provider.isReactivatingCustomer
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 24),
                  label: Text(
                    provider.isReactivatingCustomer
                        ? 'Re-activating...'
                        : 'Re-activate',
                    style: robotoBold(context).copyWith(
                      fontSize: Dimensions.fontSizeLarge(context),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'دوبارہ فعال کریں',
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeDefault(context),
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build your commands tab content here
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Lock Section
          _buildSectionTitle(context, 'Device Control', 'ڈیوائس کنٹرول'),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  context: context,
                  provider: provider,
                  label: 'Lock Device',
                  urdulabel: 'ڈیوائس کو لاک کریں',
                  icon: Icons.lock,
                  color: Colors.deepOrange,
                  command: 'lock',
                  successMessage: 'Lock command sent successfully',
                  refreshCustomerAfterSuccess: true,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: _buildControlButton(
                  context: context,
                  provider: provider,
                  label: 'Unlock Device',
                  urdulabel: 'ڈیوائس کو انلاک کریں',
                  icon: Icons.lock_open,
                  color: Colors.green,
                  command: 'unlock',
                  successMessage: 'Unlock command sent successfully',
                  refreshCustomerAfterSuccess: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  context: context,
                  provider: provider,
                  label: 'Enable Camera',
                  urdulabel: 'کیمرہ فعال کریں',
                  icon: Icons.camera_alt,
                  color: Colors.green,
                  command: 'enable_camera',
                  successMessage: 'Camera enabled successfully',
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: _buildControlButton(
                  context: context,
                  provider: provider,
                  label: 'Disable Camera',
                  urdulabel: 'کیمرہ غیر فعال کریں',
                  icon: Icons.no_photography,
                  color: Colors.orange,
                  command: 'disable_camera',
                  successMessage: 'Camera disabled successfully',
                ),
              ),
            ],
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),
          Row(
            children: [
              Expanded(
                child: _buildSocialAppsButton(
                  context: context,
                  provider: provider,
                  label: 'Show Social Apps',
                  urdulabel: 'سوشل ایپس دکھائیں',
                  icon: Icons.visibility,
                  color: Colors.green,
                  isHideMode: false,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: _buildSocialAppsButton(
                  context: context,
                  provider: provider,
                  label: 'Hide Social Apps',
                  urdulabel: 'سوشل ایپس چھپائیں',
                  icon: Icons.visibility_off,
                  color: Colors.grey,
                  isHideMode: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Row(
            children: [
              Expanded(
                child: _buildChangePasswordButton(
                  context: context,
                  provider: provider,
                  label: 'Change Screen Password',
                  urdulabel: 'اسکرین کا پاس ورڈ تبدیل کریں',
                  icon: Icons.password,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: _buildControlButton(
                  context: context,
                  provider: provider,
                  label: 'Remove Screen Password',
                  urdulabel: 'اسکرین کا پاس ورڈ ہٹائیں',
                  icon: Icons.password,
                  color: Colors.red,
                  command: 'remove_password',
                  successMessage: 'Remove password successfully',
                ),
              ),
            ],
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  context: context,
                  provider: provider,
                  label: 'Reboot Device',
                  urdulabel: 'ڈیوائس کو ریبوٹ کریں',
                  icon: Icons.restart_alt,
                  color: Colors.blue,
                  command: 'reboot_device',
                  successMessage: 'Reboot device successfully',
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: _buildMessageButton(
                  context: context,
                  provider: provider,
                  label: 'Send message to customer',
                  urdulabel: 'کسٹمر کو پیغام بھیجیں',
                  icon: Icons.message,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          // const SizedBox(height: Dimensions.paddingSizeSmall),
          // Row(
          //   children: [
          //     Expanded(
          //       child: _buildControlButton(
          //         context: context,
          //         provider: provider,
          //         label: 'Change Wallpaper',
          //         urdulabel: 'وال پیپر تبدیل کریں',
          //         icon: Icons.wallpaper,
          //         color: Colors.green,
          //         command: 'change_wallpaper',
          //         successMessage: 'Change Wallpaper request sent successfully',
          //       ),
          //     ),
          //     const SizedBox(width: Dimensions.paddingSizeSmall),
          //     Expanded(
          //       child: _buildControlButton(
          //         context: context,
          //         provider: provider,
          //         label: 'Remove Change Wallpaper',
          //         urdulabel: 'وال پیپر تبدیل کریں',
          //         icon: Icons.wallpaper,
          //         color: Colors.orange,
          //         command: 'remove_wallpaper',
          //         successMessage: 'Remove wallpaper request sent successfully',
          //       ),
          //     ),
          //   ],
          // ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // SIM Detail Button with custom handler
          _buildGetSimDetailsButton(context, provider),

          // SIM Details Card - shows when user clicks on SIM Detail button (with close button)
          _buildSimDetailsCardForCommandsTab(context, provider),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Location Control Section
          _buildSectionTitle(context, 'Location Control', 'لوکیشن کنٹرول'),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  context: context,
                  provider: provider,
                  label: 'Enable Location',
                  urdulabel: ' لوکیشن فعال کریں',
                  icon: Icons.location_on,
                  color: Colors.green,
                  command: 'enable_location',
                  successMessage: 'Location enabled successfully',
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: _buildControlButton(
                  context: context,
                  provider: provider,
                  label: 'Disable Location',
                  urdulabel: ' لوکیشن غیر فعال کریں',
                  icon: Icons.location_off,
                  color: Colors.orange,
                  command: 'disable_location',
                  successMessage: 'Location disabled successfully',
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  context: context,
                  provider: provider,
                  label: 'Turn On (Lock)',
                  urdulabel: ' لوکیشن آن کریں (لاک)',
                  icon: Icons.location_on,
                  color: Colors.blue,
                  command: 'turn_on_location_lock',
                  successMessage: 'Location turned on and locked',
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: _buildControlButton(
                  context: context,
                  provider: provider,
                  label: 'Turn Off (Lock)',
                  urdulabel: 'لوکیشن آف کریں (لاک)',
                  icon: Icons.location_off,
                  color: Colors.purple,
                  command: 'turn_off_location_lock',
                  successMessage: 'Location turned off and locked',
                ),
              ),
            ],
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Get Location Button with custom handler
          _buildGetLocationButton(context, provider),

          // Location Card - shows when location is available
          _buildLocationCard(context, provider),

          // const SizedBox(height: Dimensions.paddingSizeLarge),
          //
          // // Factory Reset Control Section
          // _buildSectionTitle(
          //   context,
          //   'Factory Reset Control',
          //   'فیکٹری ری سیٹ کنٹرول',
          // ),
          // const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          // Row(
          //   children: [
          //     Expanded(
          //       child: _buildControlButton(
          //         context: context,
          //         provider: provider,
          //         label: 'Enable Factory Reset',
          //         urdulabel: 'فیکٹری ری سیٹ فعال کریں',
          //         icon: Icons.restore,
          //         color: Colors.green,
          //         command: 'enable_factory_reset',
          //         successMessage: 'Factory reset enabled successfully',
          //       ),
          //     ),
          //     const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          //     Expanded(
          //       child: _buildControlButton(
          //         context: context,
          //         provider: provider,
          //         label: 'Disable Factory Reset',
          //         urdulabel: 'فیکٹری ری سیٹ غیر فعال کریں',
          //         icon: Icons.block,
          //         color: Colors.red,
          //         command: 'disable_factory_reset',
          //         successMessage: 'Factory reset disabled successfully',
          //       ),
          //     ),
          //   ],
          // ),
          //
          // const SizedBox(height: Dimensions.paddingSizeLarge),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          _buildUninstallButton(context, provider),
        ],
      ),
    );
  }

  Widget _buildEmiDetailsTab(BuildContext context, CustomerProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    // Get EMI data from provider
    final emiModel = provider.customerEmiModel;
    final customerEmi = emiModel?.data?.customerEmi;
    final emiDetails = emiModel?.data?.customerEmiDetails ?? [];

    // Calculate EMI statistics
    final totalAmount = customerEmi?.totalAmountParsed ?? 0;
    final advanceAmount = customerEmi?.advanceAmountParsed ?? 0;
    final monthlyAmount = customerEmi?.monthlyAmountParsed ?? 0;
    final totalMonths = customerEmi?.totalMonthsParsed ?? 0;
    final paidEmis = emiDetails.where((e) => e.isPaidStatus).length;
    final remainingEmis = emiDetails.where((e) => !e.isPaidStatus).length;
    final hasEmiRecord = customerEmi != null || emiDetails.isNotEmpty;
    final canDeleteEmi = hasEmiRecord && paidEmis == 0;

    // Check if loading
    if (provider.isEmiLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Check for errors
    if (provider.emiError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              provider.emiError!,
              style: robotoRegular(context).copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchCustomerEmi(widget.customerId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          // EMI Details Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          size: 32,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EMI Details',
                              style: robotoBold(context).copyWith(
                                fontSize: Dimensions.fontSizeLarge(context),
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'قسط کی تفصیلات',
                              style: robotoRegular(context).copyWith(
                                fontSize: Dimensions.fontSizeSmall(context),
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Add only when there is no EMI. Delete only before any payment.
                      if (canDeleteEmi) ...[
                        IconButton(
                          onPressed: () => _showDeleteEmiDialog(
                            context,
                            emiId:
                                customerEmi?.emiId ??
                                (emiDetails.isNotEmpty
                                    ? emiDetails.first.emiId
                                    : ''),
                          ),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete EMI',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ] else if (!hasEmiRecord) ...[
                        ElevatedButton.icon(
                          onPressed: () => _showUpdateEmiDetailsDialog(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Divider(height: 32),
                  // EMI Summary Info
                  _buildEmiInfoRow(
                    context: context,
                    label: 'Total Amount',
                    urduLabel: 'کل رقم',
                    value: 'Rs. ${totalAmount.toStringAsFixed(0)}',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildEmiInfoRow(
                    context: context,
                    label: 'Advance Amount',
                    urduLabel: 'پیشگی رقم',
                    value: 'Rs. ${advanceAmount.toStringAsFixed(0)}',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildEmiInfoRow(
                    context: context,
                    label: 'EMI Amount',
                    urduLabel: 'قسط کی رقم',
                    value: 'Rs. ${monthlyAmount.toStringAsFixed(0)}',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildEmiInfoRow(
                    context: context,
                    label: 'Total EMIs',
                    urduLabel: 'کل اقساط',
                    value: '$totalMonths',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildEmiInfoRow(
                    context: context,
                    label: 'Paid EMIs',
                    urduLabel: 'ادا شدہ اقساط',
                    value: '$paidEmis',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildEmiInfoRow(
                    context: context,
                    label: 'Remaining EMIs',
                    urduLabel: 'باقی اقساط',
                    value: '$remainingEmis',
                    colorScheme: colorScheme,
                  ),
                  if (customerEmi?.purchaseDate != null &&
                      customerEmi!.purchaseDate.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildEmiInfoRow(
                      context: context,
                      label: 'Purchase Date',
                      urduLabel: 'خریداری کی تاریخ',
                      value: _formatDate(customerEmi.purchaseDate),
                      colorScheme: colorScheme,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          // EMI Payment History Table Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            ),
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeLarge,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusDefault,
                            ),
                          ),
                          child: Icon(
                            Icons.table_chart,
                            size: 32,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment History',
                                style: robotoBold(context).copyWith(
                                  fontSize: Dimensions.fontSizeLarge(context),
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'ادائیگی کی تاریخ',
                                style: robotoRegular(context).copyWith(
                                  fontSize: Dimensions.fontSizeSmall(context),
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  // Table Header with blur effect
                  _buildPaymentHistoryTitle(context),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  // Payment History List
                  if (emiDetails.isEmpty)
                    _buildEmptyTableRow(context, colorScheme)
                  else
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final emiDetail = emiDetails[index];
                        return _buildPaymentHistoryCard(
                          context,
                          colorScheme,
                          index,
                          emiDetail,
                          provider,
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(
                        height: Dimensions.paddingSizeExtraSmall,
                      ),
                      itemCount: emiDetails.length,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format date
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildEmiInfoRow({
    required BuildContext context,
    required String label,
    required String urduLabel,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeDefault(context),
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              urduLabel,
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: robotoBold(context).copyWith(
            fontSize: Dimensions.fontSizeDefault(context),
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(
    BuildContext context,
    String text,
    String urduText,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              text,
              style: robotoBold(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              urduText,
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeExtraSmall(context),
                color: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTableRow(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No EMI records found',
              style: robotoRegular(
                context,
              ).copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            Text(
              'کوئی قسط کا ریکارڈ نہیں ملا',
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryTitle(BuildContext context) {
    return ClipRRect(
      // borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'EMI Date',
                  style: robotoBold(
                    context,
                  ).copyWith(fontSize: Dimensions.fontSizeDefault(context)),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Pay Date',
                  style: robotoBold(
                    context,
                  ).copyWith(fontSize: Dimensions.fontSizeDefault(context)),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Mode',
                  style: robotoBold(
                    context,
                  ).copyWith(fontSize: Dimensions.fontSizeDefault(context)),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Status',
                    style: robotoBold(
                      context,
                    ).copyWith(fontSize: Dimensions.fontSizeDefault(context)),
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryCard(
    BuildContext context,
    ColorScheme colorScheme,
    int index,
    CustomerEmiDetail emiDetail,
    CustomerProvider provider,
  ) {
    final bool isPaid = emiDetail.isPaidStatus;
    final Color statusColor = isPaid ? Colors.green : Colors.orange;

    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  _formatDate(emiDetail.emiDate),
                  style: robotoRegular(context).copyWith(
                    fontSize: Dimensions.fontSizeSmall(context),
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  emiDetail.hasValidPaymentDate
                      ? _formatDate(emiDetail.paymentDate)
                      : '-',
                  style: robotoRegular(context).copyWith(
                    fontSize: Dimensions.fontSizeSmall(context),
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  emiDetail.paymentMethod.isNotEmpty
                      ? emiDetail.paymentMethod
                      : '-',
                  style: robotoRegular(context).copyWith(
                    fontSize: Dimensions.fontSizeSmall(context),
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: isPaid
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusSmall,
                            ),
                          ),
                          child: Text(
                            'Paid',
                            style: robotoBold(context).copyWith(
                              fontSize: Dimensions.fontSizeSmall(context),
                              color: statusColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : InkWell(
                          onTap: provider.isUpdatingEmiPayment
                              ? null
                              : () => _showMarkAsPaidDialog(
                                  context,
                                  emiDetail,
                                  provider,
                                ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusSmall,
                              ),
                              border: Border.all(
                                color: Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Unpaid',
                              style: robotoBold(context).copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall(
                                  context,
                                ),
                                color: Colors.orange,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  // Show dialog to mark EMI as paid
  Future<void> _showMarkAsPaidDialog(
    BuildContext context,
    CustomerEmiDetail emiDetail,
    CustomerProvider provider,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    String selectedPaymentMethod = 'Cash';
    String selectedPaymentDate = DateTime.now().toString().split(' ')[0];
    final TextEditingController paymentDateController = TextEditingController(
      text: selectedPaymentDate,
    );
    final TextEditingController transactionIdController =
        TextEditingController();
    File? receiptImage;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> selectPaymentDate() async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  selectedPaymentDate = picked.toString().split(' ')[0];
                  paymentDateController.text = selectedPaymentDate;
                });
              }
            }

            Future<void> pickReceiptImage() async {
              final picker = ImagePicker();
              final pickedImage = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
                maxWidth: 1200,
                maxHeight: 1200,
              );

              if (pickedImage != null) {
                setState(() {
                  receiptImage = File(pickedImage.path);
                });
              }
            }

            return AlertDialog(
              title: Text(
                'Select Payment Method',
                style: robotoBold(
                  context,
                ).copyWith(fontSize: Dimensions.fontSizeLarge(context)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cash Option
                    ListTile(
                      leading: Icon(
                        Icons.money,
                        color: selectedPaymentMethod == 'Cash'
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      title: Text(
                        'Cash',
                        style: robotoRegular(context).copyWith(
                          fontSize: Dimensions.fontSizeDefault(context),
                          fontWeight: selectedPaymentMethod == 'Cash'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: selectedPaymentMethod == 'Cash'
                          ? Icon(Icons.check_circle, color: colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedPaymentMethod = 'Cash';
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: selectedPaymentMethod == 'Cash'
                              ? colorScheme.primary
                              : Colors.grey.shade300,
                          width: selectedPaymentMethod == 'Cash' ? 2 : 1,
                        ),
                      ),
                      tileColor: selectedPaymentMethod == 'Cash'
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // Online Option
                    ListTile(
                      leading: Icon(
                        Icons.phone_android,
                        color: selectedPaymentMethod == 'Online'
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      title: Text(
                        'Online',
                        style: robotoRegular(context).copyWith(
                          fontSize: Dimensions.fontSizeDefault(context),
                          fontWeight: selectedPaymentMethod == 'Online'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: selectedPaymentMethod == 'Online'
                          ? Icon(Icons.check_circle, color: colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedPaymentMethod = 'Online';
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: selectedPaymentMethod == 'Online'
                              ? colorScheme.primary
                              : Colors.grey.shade300,
                          width: selectedPaymentMethod == 'Online' ? 2 : 1,
                        ),
                      ),
                      tileColor: selectedPaymentMethod == 'Online'
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : null,
                    ),
                    if (selectedPaymentMethod == 'Online') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: transactionIdController,
                        decoration: InputDecoration(
                          labelText: 'Transaction ID',
                          hintText: 'Enter transaction ID',
                          prefixIcon: const Icon(Icons.receipt_long),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: pickReceiptImage,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          receiptImage == null
                              ? 'Upload Receipt Image (Optional)'
                              : 'Change Receipt Image',
                        ),
                      ),
                      if (receiptImage != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.image, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                receiptImage!.path.split('/').last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: robotoRegular(context).copyWith(
                                  fontSize: Dimensions.fontSizeSmall(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    // Payment Date Field
                    TextField(
                      controller: paymentDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Payment Date',
                        hintText: 'Select payment date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.edit_calendar),
                          onPressed: selectPaymentDate,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      onTap: selectPaymentDate,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedPaymentMethod == 'Online') {
                      if (transactionIdController.text.trim().isEmpty) {
                        showCustomSnackBar(
                          context,
                          'Please enter transaction ID',
                          isError: true,
                        );
                        return;
                      }
                    }

                    Navigator.of(dialogContext).pop({
                      'paymentMethod': selectedPaymentMethod,
                      'paymentDate': selectedPaymentDate,
                      'transactionId': transactionIdController.text.trim(),
                      'receiptImage': receiptImage,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Call API to mark EMI detail as paid
    final updateResult = await provider.updateEmiPaymentStatus(
      emiDtlId: emiDetail.emiDtlId,
      paymentMethod: result['paymentMethod'] as String,
      paymentDate: result['paymentDate'] as String,
      transactionId: result['transactionId'] as String?,
      receiptImage: result['receiptImage'] as File?,
    );

    // Hide loading indicator
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (!context.mounted) return;

    if (updateResult['success'] == true) {
      showCustomSnackBar(
        context,
        updateResult['message'] ?? 'Payment status updated successfully',
        isError: false,
      );

      // Refresh EMI data
      await provider.fetchCustomerEmi(widget.customerId);
    } else {
      showCustomSnackBar(
        context,
        updateResult['error'] ?? 'Failed to update payment status',
        isError: true,
      );
    }
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String urduTitle,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: robotoBold(context).copyWith(
            fontSize: Dimensions.fontSizeLarge(context),
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          urduTitle,
          style: robotoBold(context).copyWith(
            fontSize: Dimensions.fontSizeLarge(context),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required CustomerProvider provider,
    required String label,
    required String urdulabel,
    required IconData icon,
    required Color color,
    required String command,
    required String successMessage,
    bool refreshCustomerAfterSuccess = false,
  }) {
    final isLoading = provider.isCommandLoading(command);

    return SizedBox(
      height: 100,
      width: MediaQuery.of(context).size.width * 0.45,
      child: Card(
        child: Column(
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: isLoading
                    ? null
                    : () => _showPinDialog(
                          command,
                          successMessage,
                          refreshCustomerAfterSuccess:
                              refreshCustomerAfterSuccess,
                        ),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 20, color: Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                label,
                                style: robotoBold(context).copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeSmall(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                urdulabel,
                                style: robotoBold(context).copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeSmall(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // ElevatedButton(
      //   onPressed: isLoading ? null : () => _showPinDialog(command, successMessage),
      //   style: ElevatedButton.styleFrom(
      //     backgroundColor: color,
      //     foregroundColor: Colors.white,
      //     disabledBackgroundColor: color.withValues(alpha: 0.6),
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      //     ),
      //     padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      //   ),
      //   child: isLoading
      //       ? const SizedBox(
      //           width: 20,
      //           height: 20,
      //           child: CircularProgressIndicator(
      //             strokeWidth: 2,
      //             color: Colors.white,
      //           ),
      //         )
      //       : Row(
      //           mainAxisAlignment: MainAxisAlignment.center,
      //           children: [
      //             Icon(icon, size: 20),
      //             const SizedBox(width: 6),
      //             Flexible(
      //               child: Text(
      //                 label,
      //                 style: robotoBold(context).copyWith(
      //                   color: Colors.white,
      //                   fontSize: Dimensions.fontSizeSmall(context),
      //                 ),
      //                 overflow: TextOverflow.ellipsis,
      //               ),
      //             ),
      //           ],
      //         ),
      // ),
    );
  }

  Widget _buildChangePasswordButton({
    required BuildContext context,
    required CustomerProvider provider,
    required String label,
    required String urdulabel,
    required IconData icon,
    required Color color,
  }) {
    const loadingKey = 'change_screen_password';
    final isLoading = provider.isCommandLoading(loadingKey);

    return SizedBox(
      height: 100,
      width: MediaQuery.of(context).size.width * 0.45,
      child: Card(
        child: Column(
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: isLoading ? null : () => _showChangePasswordDialog(),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 20, color: Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                label,
                                style: robotoBold(context).copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeSmall(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                urdulabel,
                                style: robotoBold(context).copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeSmall(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageButton({
    required BuildContext context,
    required CustomerProvider provider,
    required String label,
    required String urdulabel,
    required IconData icon,
    required Color color,
  }) {
    const loadingKey = 'send_customer_message';
    final isLoading = provider.isCommandLoading(loadingKey);

    return SizedBox(
      height: 100,
      width: MediaQuery.of(context).size.width * 0.45,
      child: Card(
        child: Column(
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: isLoading ? null : () => _showMessageDialog(),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 20, color: Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                label,
                                style: robotoBold(context).copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeSmall(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                urdulabel,
                                style: robotoBold(context).copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeSmall(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialAppsButton({
    required BuildContext context,
    required CustomerProvider provider,
    required String label,
    required String urdulabel,
    required IconData icon,
    required Color color,
    required bool isHideMode,
  }) {
    final loadingKey = isHideMode ? 'hide_social_apps' : 'show_social_apps';
    final isLoading = provider.isCommandLoading(loadingKey);

    return SizedBox(
      height: 100,
      width: MediaQuery.of(context).size.width * 0.45,
      child: Card(
        child: Column(
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: isLoading
                    ? null
                    : () => isHideMode
                    ? _showHideAppsDialog()
                    : _showShowAppsDialog(),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 20, color: Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                label,
                                style: robotoBold(context).copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeSmall(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                urdulabel,
                                style: robotoBold(context).copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeSmall(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom Uninstall Button with special handling
  Widget _buildUninstallButton(
    BuildContext context,
    CustomerProvider provider,
  ) {
    final isLoading = provider.isCommandLoading('uninstall');

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _showPinDialogForUninstall(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.teal.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_forever_sharp, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'UnInstall',
                    style: robotoBold(context).copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ان انسٹال کریں',
                    style: robotoBold(context).copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Show PIN dialog for Uninstall
  Future<void> _showPinDialogForUninstall() async {
    final verified = await _verifyPinWithDialog('Uninstall');
    if (verified) {
      await _handleUninstall();
    }
  }

  // Handle Uninstall command with special behavior
  Future<void> _handleUninstall() async {
    final provider = context.read<CustomerProvider>();
    provider.setCommandLoading('uninstall', true);

    bool ok = false;
    try {
      ok = await provider.sendMobileNotification(
        customerId: widget.customerId,
        status: 'uninstall',
      );

      if (!mounted) return;

      if (ok) {
        await provider.fetchCustomers(context, isRefresh: true);

        if (!mounted) return;

        showCustomSnackBar(
          context,
          'UnInstall request sent successfully',
          isError: false,
        );

        Navigator.of(context).pop();
      } else {
        showCustomSnackBar(
          context,
          'Failed to send uninstall command',
          isError: true,
        );
      }
    } finally {
      provider.setCommandLoading('uninstall', false);
    }
  }

  Widget _buildFullWidthButton({
    required BuildContext context,
    required CustomerProvider provider,
    required String label,
    required String urdulabel,
    required IconData icon,
    required Color color,
    required String command,
    required String successMessage,
  }) {
    final isLoading = provider.isCommandLoading(command);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () => _showPinDialog(command, successMessage),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: robotoBold(context).copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    urdulabel,
                    style: robotoBold(context).copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Custom Get Location Button that handles 2-second delay API call
  Widget _buildGetLocationButton(
    BuildContext context,
    CustomerProvider provider,
  ) {
    final isLoading =
        provider.isCommandLoading('get_current_location') ||
        provider.isLocationLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _showPinDialogForLocation(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.teal.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        ),
        child: isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Fetching Location...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.my_location, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Get Location',
                    style: robotoBold(context).copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ' لوکیشن حاصل کریں',
                    style: robotoBold(context).copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Location Card to display latitude and longitude
  Widget _buildLocationCard(BuildContext context, CustomerProvider provider) {
    // Only show if we have location data
    if (!provider.hasLocationResponse && provider.locationError == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: provider.locationError != null
                  ? [Colors.red.shade50, Colors.red.shade100]
                  : [Colors.teal.shade50, Colors.teal.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    provider.locationError != null
                        ? Icons.error_outline
                        : Icons.location_on,
                    color: provider.locationError != null
                        ? Colors.red
                        : Colors.teal,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    provider.locationError != null
                        ? 'Location Error'
                        : 'Device Location',
                    style: robotoBold(context).copyWith(
                      fontSize: Dimensions.fontSizeLarge(context),
                      color: provider.locationError != null
                          ? Colors.red.shade700
                          : Colors.teal.shade700,
                    ),
                  ),
                  const Spacer(),
                  // Close button to clear location data
                  IconButton(
                    onPressed: () {
                      provider.clearLocationData();
                    },
                    icon: Icon(
                      Icons.close,
                      color: provider.locationError != null
                          ? Colors.red.shade700
                          : Colors.teal.shade700,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (provider.locationError != null) ...[
                Text(
                  provider.locationError!,
                  style: robotoRegular(context).copyWith(
                    color: Colors.red.shade700,
                    fontSize: Dimensions.fontSizeDefault(context),
                  ),
                ),
              ] else ...[
                // Latitude
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.north,
                        color: Colors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latitude',
                          style: robotoRegular(context).copyWith(
                            color: Colors.grey.shade600,
                            fontSize: Dimensions.fontSizeSmall(context),
                          ),
                        ),
                        Text(
                          provider.currentLatitude?.toStringAsFixed(6) ?? '',
                          style: robotoBold(context).copyWith(
                            fontSize: Dimensions.fontSizeDefault(context),
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Longitude
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.east,
                        color: Colors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Longitude',
                          style: robotoRegular(context).copyWith(
                            color: Colors.grey.shade600,
                            fontSize: Dimensions.fontSizeSmall(context),
                          ),
                        ),
                        Text(
                          provider.currentLongitude?.toStringAsFixed(6) ?? '',
                          style: robotoBold(context).copyWith(
                            fontSize: Dimensions.fontSizeDefault(context),
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Custom Get SIM Details Button that handles 2-second delay API call
  Widget _buildGetSimDetailsButton(
    BuildContext context,
    CustomerProvider provider,
  ) {
    final isLoading =
        provider.isCommandLoading('get_sim_details') ||
        provider.isSimDetailsLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _showPinDialogForSimDetails(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.teal.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        ),
        child: isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Fetching SIM Details...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sim_card, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Sim Detail',
                    style: robotoBold(context).copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'سم کی تفصیلات',
                    style: robotoBold(context).copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Helper to get appropriate icon for SIM detail field
  IconData _getSimDetailIcon(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('phone') ||
        lowerKey.contains('number') ||
        lowerKey.contains('mobile')) {
      return Icons.phone;
    } else if (lowerKey.contains('carrier') ||
        lowerKey.contains('operator') ||
        lowerKey.contains('network')) {
      return Icons.cell_tower;
    } else if (lowerKey.contains('imei')) {
      return Icons.smartphone;
    } else if (lowerKey.contains('imsi') || lowerKey.contains('subscriber')) {
      return Icons.badge;
    } else if (lowerKey.contains('country')) {
      return Icons.flag;
    } else if (lowerKey.contains('sim') || lowerKey.contains('slot')) {
      return Icons.sim_card;
    } else if (lowerKey.contains('state') || lowerKey.contains('status')) {
      return Icons.info;
    } else {
      return Icons.label;
    }
  }

  // Helper to format SIM detail key to readable label
  String _formatSimDetailKey(String key) {
    // Convert snake_case or camelCase to Title Case
    return key
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  Widget _buildErrorWidget(
    BuildContext context,
    CustomerProvider provider,
    String error,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 12),
                Text(
                  'Couldn\'t load status',
                  style: robotoBold(
                    context,
                  ).copyWith(fontSize: Dimensions.fontSizeLarge(context)),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: robotoRegular(context).copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => context
                        .read<CustomerProvider>()
                        .fetchSingleUserDevicesForCustomer(widget.customerId),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// EMI Details Dialog Widget
class _EmiDetailsDialog extends StatefulWidget {
  final ColorScheme colorScheme;
  final int customerId;
  final CustomerProvider customerProvider;

  const _EmiDetailsDialog({
    required this.colorScheme,
    required this.customerId,
    required this.customerProvider,
  });

  @override
  State<_EmiDetailsDialog> createState() => _EmiDetailsDialogState();
}

class _EmiDetailsDialogState extends State<_EmiDetailsDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _purchaseDateController;
  late final TextEditingController _totalAmountController;
  late final TextEditingController _advanceAmountController;
  late final TextEditingController _totalMonthsController;

  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _purchaseDateController = TextEditingController();
    _totalAmountController = TextEditingController();
    _advanceAmountController = TextEditingController();
    _totalMonthsController = TextEditingController();

    // Set default purchase date to today
    _purchaseDateController.text = DateTime.now().toString().split(' ')[0];
  }

  @override
  void dispose() {
    _isDisposed = true;
    _purchaseDateController.dispose();
    _totalAmountController.dispose();
    _advanceAmountController.dispose();
    _totalMonthsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && !_isDisposed && mounted) {
      setState(() {
        _purchaseDateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    if (_isDisposed || !mounted) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await widget.customerProvider.insertCustomerEmi(
        customerId: widget.customerId,
        purchaseDate: _purchaseDateController.text,
        totalAmount: _totalAmountController.text,
        advanceAmount: _advanceAmountController.text,
        totalMonths: _totalMonthsController.text,
      );

      if (_isDisposed || !mounted) return;

      if (result['success'] == true) {
        Navigator.of(context).pop({
          'success': true,
          'message':
              result['message'] ??
              result['data']?['message'] ??
              'EMI Details added successfully',
        });
      } else {
        Navigator.of(context).pop({
          'success': false,
          'error': result['error'] ?? 'Failed to add EMI details',
        });
      }
    } catch (e) {
      if (_isDisposed || !mounted) return;
      Navigator.of(
        context,
      ).pop({'success': false, 'error': 'Error: ${e.toString()}'});
    }
  }

  // Compact input decoration for smaller fields
  InputDecoration _compactInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: robotoRegular(
        context,
      ).copyWith(fontSize: Dimensions.fontSizeSmall(context)),
      hintStyle: robotoRegular(context).copyWith(
        fontSize: Dimensions.fontSizeExtraSmall(context),
        color: Theme.of(context).hintColor,
      ),
      errorStyle: robotoRegular(
        context,
      ).copyWith(fontSize: Dimensions.fontSizeExtraSmall(context)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        borderSide: BorderSide(color: widget.colorScheme.primary),
      ),
      prefixIcon: Icon(prefixIcon, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = robotoRegular(
      context,
    ).copyWith(fontSize: Dimensions.fontSizeSmall(context));

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: Row(
        children: [
          Icon(Icons.payment, color: widget.colorScheme.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            'Add EMI Details',
            style: robotoBold(
              context,
            ).copyWith(fontSize: Dimensions.fontSizeDefault(context)),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Purchase Date
                TextFormField(
                  controller: _purchaseDateController,
                  readOnly: true,
                  style: textStyle,
                  decoration: _compactInputDecoration(
                    labelText: 'Purchase Date',
                    hintText: 'Select date',
                    prefixIcon: Icons.calendar_today,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      onPressed: _selectDate,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select purchase date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Total Amount
                TextFormField(
                  controller: _totalAmountController,
                  keyboardType: TextInputType.number,
                  style: textStyle,
                  decoration: _compactInputDecoration(
                    labelText: 'Total Amount',
                    hintText: 'Enter amount',
                    prefixIcon: Icons.attach_money,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter total amount';
                    }
                    final totalAmount = double.tryParse(value);
                    if (totalAmount == null || totalAmount <= 0) {
                      return 'Enter valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Advance Amount
                TextFormField(
                  controller: _advanceAmountController,
                  keyboardType: TextInputType.number,
                  style: textStyle,
                  decoration: _compactInputDecoration(
                    labelText: 'Advance Amount',
                    hintText: 'Enter advance',
                    prefixIcon: Icons.payment,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter advance amount';
                    }
                    final advanceAmount = double.tryParse(value);
                    if (advanceAmount == null || advanceAmount < 0) {
                      return 'Enter valid amount';
                    }
                    final totalAmount =
                        double.tryParse(_totalAmountController.text) ?? 0;
                    if (totalAmount > 0 && advanceAmount >= totalAmount) {
                      return 'Advance must be less than total';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Total Months
                TextFormField(
                  controller: _totalMonthsController,
                  keyboardType: TextInputType.number,
                  style: textStyle,
                  decoration: _compactInputDecoration(
                    labelText: 'Total Months',
                    hintText: 'EMI months',
                    prefixIcon: Icons.calendar_month,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter total months';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Enter valid months';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(null),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Cancel',
            style: robotoMedium(
              context,
            ).copyWith(fontSize: Dimensions.fontSizeSmall(context)),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Save EMI',
                  style: robotoMedium(
                    context,
                  ).copyWith(fontSize: Dimensions.fontSizeSmall(context)),
                ),
        ),
      ],
    );
  }
}

// Social Apps Selection Dialog Widget
class _SocialAppsSelectionDialog extends StatefulWidget {
  final String title;
  final String urduTitle;
  final List<SocialApp> apps;
  final bool isHideMode;

  const _SocialAppsSelectionDialog({
    required this.title,
    required this.urduTitle,
    required this.apps,
    required this.isHideMode,
  });

  @override
  State<_SocialAppsSelectionDialog> createState() =>
      _SocialAppsSelectionDialogState();
}

class _SocialAppsSelectionDialogState
    extends State<_SocialAppsSelectionDialog> {
  final Set<String> _selectedApps = {};
  bool _selectAll = false;

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedApps.addAll(widget.apps.map((e) => e.commandName));
      } else {
        _selectedApps.clear();
      }
    });
  }

  void _toggleApp(String commandName) {
    setState(() {
      if (_selectedApps.contains(commandName)) {
        _selectedApps.remove(commandName);
        _selectAll = false;
      } else {
        _selectedApps.add(commandName);
        if (_selectedApps.length == widget.apps.length) {
          _selectAll = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title),
          Text(
            widget.urduTitle,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Select All Checkbox
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectAll
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.3),
                  width: _selectAll ? 2 : 1,
                ),
              ),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.select_all,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select All Apps',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'تمام ایپس منتخب کریں',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                value: _selectAll,
                onChanged: _toggleSelectAll,
                controlAffinity: ListTileControlAffinity.trailing,
                activeColor: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 08),
            const Divider(height: 1),
            const SizedBox(height: 08),
            // Apps List
            Expanded(
              child: ListView.builder(
                itemCount: widget.apps.length,
                itemBuilder: (context, index) {
                  final app = widget.apps[index];
                  final isSelected = _selectedApps.contains(app.commandName);
                  // Check if app color is too light (like Snapchat yellow)
                  final isLightColor = app.color.computeLuminance() > 0.5;
                  final selectionIndicatorColor = isLightColor
                      ? Colors.black87
                      : app.color;
                  final borderColor = isLightColor && isSelected
                      ? Colors.amber[700]!
                      : app.color;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: GestureDetector(
                      onTap: () => _toggleApp(app.commandName),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isLightColor
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : app.color.withValues(alpha: 0.15))
                              : colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.5,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? borderColor
                                : colorScheme.outline.withValues(alpha: 0.2),
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: borderColor.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            // App Icon
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: app.color,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: app.color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                app.icon,
                                color: isLightColor
                                    ? Colors.black
                                    : Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // App Name & Selection indicator
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (isSelected)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: selectionIndicatorColor,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            'Selected',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: selectionIndicatorColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      'Tap to select',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                // style: TextButton.styleFrom(
                //   padding: const EdgeInsets.symmetric(vertical: 12),
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(8),
                //     side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                //   ),
                // ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedApps.isEmpty
                    ? null
                    : () {
                        if (_selectAll) {
                          Navigator.of(context).pop(['all']);
                        } else {
                          Navigator.of(context).pop(_selectedApps.toList());
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isHideMode
                      ? Colors.grey[700]
                      : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isHideMode
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isHideMode ? 'Hide' : 'Show',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

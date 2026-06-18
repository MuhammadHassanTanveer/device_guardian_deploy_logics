import 'package:deviceguardianadmin/providers/login_provider.dart';
import 'package:deviceguardianadmin/screens/home_screen.dart';
import 'package:deviceguardianadmin/util/dimensions.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:deviceguardianadmin/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/snack_bar_widget.dart';

class UpdatePinScreen extends StatefulWidget {
  final bool isFirstTime;
  
  const UpdatePinScreen({super.key, this.isFirstTime = false});

  @override
  State<UpdatePinScreen> createState() => _UpdatePinScreenState();
}

class _UpdatePinScreenState extends State<UpdatePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _newPinFocusNode = FocusNode();
  final _confirmPinFocusNode = FocusNode();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    _newPinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final provider = context.read<LoginProvider>();
        final success = await provider.updatePin(_newPinController.text);
        
        if (mounted) {
          if (success) {
            showCustomSnackBar(context, "PIN updated successfully!", isError: false);
            
            // If first time setup, navigate to home screen
            if (widget.isFirstTime) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            } else {
              Navigator.of(context).pop();
            }
          } else {
            // Check if error is authentication related
            final errorMsg = provider.errorMessage ?? "Failed to update PIN. Please try again.";
            showCustomSnackBar(context, errorMsg, isError: true);

            // If session expired, offer to logout
            if (errorMsg.toLowerCase().contains('session expired') ||
                errorMsg.toLowerCase().contains('login again') ||
                errorMsg.toLowerCase().contains('unauthenticated')) {
              _showLogoutDialog();
            }
          }
        }
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(context, "Failed to update PIN. Please try again.", isError: true);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Session Expired',
            style: robotoBold(context),
          ),
          content: Text(
            'Your session has expired. Please login again to continue.',
            style: robotoRegular(context),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Logout and go to login screen
                final provider = context.read<LoginProvider>();
                await provider.logout();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                }
              },
              child: Text(
                'Logout',
                style: robotoBold(context).copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !widget.isFirstTime,
      child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isFirstTime, // Hide back button on first time setup
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isFirstTime ? 'Set PIN' : 'Update PIN',
              style: robotoBold(context).copyWith(
                fontSize: Dimensions.fontSizeLarge(context),
              ),
            ),
            Text(
              widget.isFirstTime ? 'پن سیٹ کریں' : 'پن اپڈیٹ کریں',
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  // Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Security Notice',
                                  style: robotoBold(context).copyWith(
                                    fontSize: Dimensions.fontSizeDefault(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your PIN must be exactly 4 digits. Keep it secure and do not share with anyone.',
                                  style: robotoRegular(context).copyWith(
                                    fontSize: Dimensions.fontSizeSmall(context),
                                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  'آپ کا پن بالکل 4 ہندسوں کا ہونا چاہیے۔ اسے محفوظ رکھیں۔',
                                  style: robotoRegular(context).copyWith(
                                    fontSize: Dimensions.fontSizeSmall(context),
                                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                  // New PIN Field
                  CustomTextFieldWidget(
                    labelText: 'New PIN (نیا پن)',
                    hintText: 'Enter 4 digit PIN',
                    controller: _newPinController,
                    focusNode: _newPinFocusNode,
                    nextFocus: _confirmPinFocusNode,
                    inputType: TextInputType.number,
                    isPassword: true,
                    prefixIcon: Icons.lock,
                    required: true,
                    maxLength: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter new PIN';
                      }
                      if (value.length != 4) {
                        return 'PIN must be exactly 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // Confirm PIN Field
                  CustomTextFieldWidget(
                    labelText: 'Confirm New PIN (نئے پن کی تصدیق)',
                    hintText: 'Enter 4 digit PIN',
                    controller: _confirmPinController,
                    focusNode: _confirmPinFocusNode,
                    inputType: TextInputType.number,
                    inputAction: TextInputAction.done,
                    isPassword: true,
                    prefixIcon: Icons.lock_clock,
                    required: true,
                    maxLength: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new PIN';
                      }
                      if (value.length != 4) {
                        return 'PIN must be exactly 4 digits';
                      }
                      if (value != _newPinController.text) {
                        return 'PINs do not match';
                      }
                      return null;
                    },
                    onSubmit: (_) => _handleUpdatePin(),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                  // Update Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleUpdatePin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      backgroundColor: colorScheme.primary,
                      disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.update, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                widget.isFirstTime ? 'Set PIN' : 'Update PIN',
                                style: robotoBold(context).copyWith(
                                  fontSize: Dimensions.fontSizeLarge(context),
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                  
                  // Cancel Button - only show if not first time setup
                  if (!widget.isFirstTime) ...[
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                        side: BorderSide(color: colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: robotoRegular(context).copyWith(
                          fontSize: Dimensions.fontSizeLarge(context),
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}


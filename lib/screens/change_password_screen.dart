import 'package:deviceguardianadmin/providers/change_password_provider.dart';
import 'package:deviceguardianadmin/providers/login_provider.dart';
import 'package:deviceguardianadmin/util/dimensions.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:deviceguardianadmin/widgets/custom_text_field_widget.dart';
import 'package:deviceguardianadmin/widgets/snack_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _currentPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ChangePasswordProvider>();
    final success = await provider.changePassword(
      currentPassword: _currentPasswordController.text,
      password: _newPasswordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      showCustomSnackBar(
        context,
        'Password changed successfully!',
        isError: false,
      );
      Navigator.of(context).pop();
      return;
    }

    final errorMsg =
        provider.errorMessage ?? 'Failed to change password. Please try again.';
    showCustomSnackBar(context, errorMsg, isError: true);

    if (errorMsg.toLowerCase().contains('session expired') ||
        errorMsg.toLowerCase().contains('login again') ||
        errorMsg.toLowerCase().contains('unauthenticated')) {
      _showLogoutDialog();
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Session Expired', style: robotoBold(context)),
          content: Text(
            'Your session has expired. Please login again to continue.',
            style: robotoRegular(context),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final loginProvider = context.read<LoginProvider>();
                await loginProvider.logout();
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
    final provider = context.watch<ChangePasswordProvider>();
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: robotoBold(context).copyWith(
                fontSize: Dimensions.fontSizeLarge(context),
              ),
            ),
            Text(
              'پاس ورڈ تبدیل کریں',
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.password_rounded,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
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
                                  'Password Requirements',
                                  style: robotoBold(context).copyWith(
                                    fontSize: Dimensions.fontSizeDefault(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'New password must be at least 8 characters and match confirmation.',
                                  style: robotoRegular(context).copyWith(
                                    fontSize: Dimensions.fontSizeSmall(context),
                                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  'نیا پاس ورڈ کم از کم 8 حروف کا ہونا چاہیے۔',
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
                  CustomTextFieldWidget(
                    labelText: 'Current Password (موجودہ پاس ورڈ)',
                    hintText: 'Enter current password',
                    controller: _currentPasswordController,
                    focusNode: _currentPasswordFocusNode,
                    nextFocus: _newPasswordFocusNode,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                    required: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  CustomTextFieldWidget(
                    labelText: 'New Password (نیا پاس ورڈ)',
                    hintText: 'Enter new password',
                    controller: _newPasswordController,
                    focusNode: _newPasswordFocusNode,
                    nextFocus: _confirmPasswordFocusNode,
                    isPassword: true,
                    prefixIcon: Icons.lock,
                    required: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  CustomTextFieldWidget(
                    labelText: 'Confirm Password (تصدیق)',
                    hintText: 'Confirm new password',
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    inputAction: TextInputAction.done,
                    isPassword: true,
                    prefixIcon: Icons.lock_clock,
                    required: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    onSubmit: (_) => _handleChangePassword(),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleChangePassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      backgroundColor: colorScheme.primary,
                      disabledBackgroundColor:
                          colorScheme.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                    child: isLoading
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
                              const Icon(Icons.check_circle_outline, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Change Password',
                                style: robotoBold(context).copyWith(
                                  fontSize: Dimensions.fontSizeLarge(context),
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

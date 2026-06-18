import 'package:deviceguardianadmin/providers/login_provider.dart';
import 'package:deviceguardianadmin/screens/home_screen.dart';
import 'package:deviceguardianadmin/screens/register_screen.dart';
import 'package:deviceguardianadmin/screens/update_pin_screen.dart';
import 'package:deviceguardianadmin/util/app_constants.dart';
import 'package:deviceguardianadmin/util/dimensions.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:deviceguardianadmin/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/snack_bar_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<LoginProvider>();
      final success = await provider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        showCustomSnackBar(context, "Login successful!", isError: false);

        if (!mounted) return;

        final pinConfigured = await provider.hasPinConfigured();
        if (!mounted) return;

        if (pinConfigured) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const UpdatePinScreen(isFirstTime: true)),
            (route) => false,
          );
        }
      } else if (provider.errorMessage != null && mounted) {
        showCustomSnackBar(context, provider.errorMessage!, isError: true);
      }
    }
  }

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
            children: [
              // Main content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          Image.asset(
                            'assets/images/logo.png',
                            height: 120,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeOverLarge),

                          // Welcome Text
                          Text(
                            'Welcome Back\nخوش آمدید',
                            style: robotoBold(context).copyWith(
                              fontSize: Dimensions.fontSizeOverLarge(context),
                              color: colorScheme.tertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Text(
                            'Sign in to continue\nجاری رکھنے کے لیے سائن ان کریں',
                            style: robotoRegular(context).copyWith(
                              color: theme.hintColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                          // Email Field
                          CustomTextFieldWidget(
                            labelText: 'Email ای میل',
                            hintText: 'Enter your email ای میل درج کریں',
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            nextFocus: _passwordFocusNode,
                            inputType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            required: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email ای میل درج کریں';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email درست ای میل درج کریں';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),

                          // Password Field
                          CustomTextFieldWidget(
                            labelText: 'Password پاس ورڈ',
                            hintText: 'Enter your password پاس ورڈ درج کریں',
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            inputType: TextInputType.visiblePassword,
                            inputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            required: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password پاس ورڈ درج کریں';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے';
                              }
                              return null;
                            },
                            onSubmit: (_) => _handleLogin(),
                          ),
                          
                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                showCustomSnackBar(context, "Please contact admin to reset your password پاس ورڈ ری سیٹ کرنے کے لیے ایڈمن سے رابطہ کریں", isError: false);
                              },
                              child: Text(
                                'Forgot Password? پاس ورڈ بھول گئے؟',
                                style: robotoRegular(context).copyWith(
                                  color: colorScheme.primary,
                                  fontSize: Dimensions.fontSizeSmall(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),

                          // Login Button
                          Consumer<LoginProvider>(
                            builder: (context, provider, child) {
                              return ElevatedButton(
                                onPressed: provider.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: Dimensions.paddingSizeDefault,
                                  ),
                                  backgroundColor: colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault,
                                    ),
                                  ),
                                ),
                                child: provider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Login لاگ ان',
                                        style: robotoBold(context).copyWith(
                                          fontSize:
                                              Dimensions.fontSizeLarge(context),
                                          color: Colors.white,
                                        ),
                                      ),
                              );
                            },
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),

                          // Register Link
                          Column(
                            children: [
                              Text(
                                "Don't have an account?",
                                style: robotoRegular(context).copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                              Text(
                                "اکاؤنٹ نہیں ہے؟",
                                style: robotoRegular(context).copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Register رجسٹر',
                                  style: robotoBold(context).copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                          // Footer - Version and Powered by
                          Column(
                            children: [
                              Text(
                                "Version: ${AppConstants.appVersion}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.hintColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Powered by Deploy Logics",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              Text(
                                "deploylogics.com",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


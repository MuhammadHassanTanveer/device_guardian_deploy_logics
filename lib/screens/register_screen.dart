import 'package:deviceguardianadmin/providers/registration_provider.dart';
import 'package:deviceguardianadmin/util/app_constants.dart';
import 'package:deviceguardianadmin/util/dimensions.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:deviceguardianadmin/widgets/custom_text_field_widget.dart';
import 'package:deviceguardianadmin/widgets/custom_location_dropdown_widget.dart';
import 'package:deviceguardianadmin/widgets/custom_phone_field_widget.dart';
import 'package:deviceguardianadmin/models/location_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/snack_bar_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _nameInUrduController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _referenceCodeController = TextEditingController();

  final _userNameFocusNode = FocusNode();
  final _companyNameFocusNode = FocusNode();
  final _nameInUrduFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _referenceCodeFocusNode = FocusNode();
  
  // Phone country code
  String _selectedCountryCode = '+92';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RegistrationProvider>();
      provider.clearAllData();
      provider.fetchCountries().then((_) {
        // Show error if countries failed to load
        if (provider.errorMessage != null && mounted) {
          showCustomSnackBar(
            context, 
            provider.errorMessage!, 
            isError: true,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _companyNameController.dispose();
    _nameInUrduController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _referenceCodeController.dispose();
    _userNameFocusNode.dispose();
    _companyNameFocusNode.dispose();
    _nameInUrduFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _referenceCodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<RegistrationProvider>();

      // Validate dropdowns
      if (provider.selectedCountry == null) {
        showCustomSnackBar(context, "Please select a country", isError: true);
        return;
      }

      if (provider.selectedState == null) {
        showCustomSnackBar(context, "Please select a state", isError: true);
        return;
      }

      if (provider.selectedCity == null) {
        showCustomSnackBar(context, "Please select a city", isError: true);
        return;
      }

      final success = await provider.registerUser(
        userName: _userNameController.text.trim(),
        companyName: _companyNameController.text.trim(),
        companyNameUrdu: _nameInUrduController.text.trim().isEmpty
            ? null
            : _nameInUrduController.text.trim(),
        contactNumber: '$_selectedCountryCode${_phoneController.text.trim()}',
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        address: _addressController.text.trim(),
        countryId: provider.selectedCountry!.id.toString(),
        stateId: provider.selectedState!.id.toString(),
        cityId: provider.selectedCity!.id.toString(),
        referenceCode: _referenceCodeController.text.trim().isEmpty
            ? null
            : _referenceCodeController.text.trim(),
      );

      if (success && mounted) {
        showCustomSnackBar(context, "Registration successful! Please login.", isError: false);
        Navigator.of(context).pop();
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
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Create Account\nاکاؤنٹ بنائیں',
                        style: robotoBold(context).copyWith(
                          fontSize: Dimensions.fontSizeExtraLarge(context),
                          color: colorScheme.tertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Image.asset(
                          'assets/images/logo.png',
                          height: 80,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Subtitle
                        Text(
                          'Fill in the details below to register\nرجسٹر کرنے کے لیے نیچے تفصیلات درج کریں',
                          style: robotoRegular(context).copyWith(
                            color: theme.hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                        // Username Field
                        CustomTextFieldWidget(
                          labelText: 'Username صارف نام',
                          hintText: 'Enter your username صارف نام درج کریں',
                          controller: _userNameController,
                          focusNode: _userNameFocusNode,
                          nextFocus: _companyNameFocusNode,
                          inputType: TextInputType.text,
                          prefixIcon: Icons.person_outline,
                          required: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter username صارف نام درج کریں';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters صارف نام کم از کم 3 حروف کا ہونا چاہیے';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Company Name Field
                        CustomTextFieldWidget(
                          labelText: 'Company Name کمپنی کا نام',
                          hintText: 'Enter your company name کمپنی کا نام درج کریں',
                          controller: _companyNameController,
                          focusNode: _companyNameFocusNode,
                          nextFocus: _nameInUrduFocusNode,
                          inputType: TextInputType.text,
                          prefixIcon: Icons.business,
                          required: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter company name کمپنی کا نام درج کریں';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Name in Urdu Field
                        CustomTextFieldWidget(
                          labelText: 'Name in Urdu اردو میں نام',
                          hintText: 'Enter name in Urdu اردو میں نام درج کریں',
                          controller: _nameInUrduController,
                          focusNode: _nameInUrduFocusNode,
                          nextFocus: _emailFocusNode,
                          inputType: TextInputType.text,
                          prefixIcon: Icons.text_fields,
                          required: false,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

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
                          nextFocus: _confirmPasswordFocusNode,
                          inputType: TextInputType.visiblePassword,
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
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Confirm Password Field
                        CustomTextFieldWidget(
                          labelText: 'Confirm Password پاس ورڈ کی تصدیق',
                          hintText: 'Confirm your password پاس ورڈ کی تصدیق کریں',
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          nextFocus: _phoneFocusNode,
                          inputType: TextInputType.visiblePassword,
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          required: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password پاس ورڈ کی تصدیق کریں';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match پاس ورڈ مماثل نہیں ہیں';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Phone Number Field
                        CustomPhoneFieldWidget(
                          labelText: 'Phone No. فون نمبر',
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          required: true,
                          hintText: 'Enter phone number فون نمبر درج کریں',
                          initialCountryCode: 'PK',
                          onCountryCodeChanged: (countryCode) {
                            setState(() {
                              _selectedCountryCode = countryCode;
                            });
                          },
                          validator: (phone) {
                            if (phone == null || phone.number.isEmpty) {
                              return 'Please enter phone number فون نمبر درج کریں';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Address Field
                        CustomTextFieldWidget(
                          labelText: 'Address پتہ',
                          hintText: 'Enter your address پتہ درج کریں',
                          controller: _addressController,
                          focusNode: _addressFocusNode,
                          nextFocus: _referenceCodeFocusNode,
                          inputType: TextInputType.streetAddress,
                          prefixIcon: Icons.location_on_outlined,
                          required: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your address پتہ درج کریں';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Country Dropdown
                        Consumer<RegistrationProvider>(
                          builder: (context, provider, child) {
                            return CustomLocationDropdown<CountryModel>(
                              labelText: 'Country ملک',
                              hintText: 'Select country ملک منتخب کریں',
                              selectedValue: provider.selectedCountry,
                              items: provider.countries,
                              isLoading: provider.isLoadingCountries,
                              required: true,
                              prefixIcon: Icons.public,
                              displayText: (country) => country.name,
                              onChanged: (country) {
                                provider.setSelectedCountry(country);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select country ملک منتخب کریں';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // State Dropdown
                        Consumer<RegistrationProvider>(
                          builder: (context, provider, child) {
                            return CustomLocationDropdown<StateModel>(
                              labelText: 'State صوبہ',
                              hintText: 'Select state صوبہ منتخب کریں',
                              selectedValue: provider.selectedState,
                              items: provider.states,
                              isLoading: provider.isLoadingStates,
                              isEnabled: provider.selectedCountry != null,
                              required: true,
                              prefixIcon: Icons.map,
                              displayText: (state) => state.name,
                              onChanged: (state) {
                                provider.setSelectedState(state);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select state صوبہ منتخب کریں';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // City Dropdown
                        Consumer<RegistrationProvider>(
                          builder: (context, provider, child) {
                            return CustomLocationDropdown<CityModel>(
                              labelText: 'City شہر',
                              hintText: 'Select city شہر منتخب کریں',
                              selectedValue: provider.selectedCity,
                              items: provider.cities,
                              isLoading: provider.isLoadingCities,
                              isEnabled: provider.selectedState != null,
                              required: true,
                              prefixIcon: Icons.location_city,
                              displayText: (city) => city.name,
                              onChanged: (city) {
                                provider.setSelectedCity(city);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select city شہر منتخب کریں';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Reference Code Field
                        CustomTextFieldWidget(
                          labelText: 'Reference Code حوالہ کوڈ',
                          hintText: 'Enter reference code (optional) حوالہ کوڈ درج کریں (اختیاری)',
                          controller: _referenceCodeController,
                          focusNode: _referenceCodeFocusNode,
                          inputType: TextInputType.text,
                          inputAction: TextInputAction.done,
                          prefixIcon: Icons.code,
                          required: false,
                          onSubmit: (_) => _handleRegister(),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        // Register Button
                        Consumer<RegistrationProvider>(
                          builder: (context, provider, child) {
                            return ElevatedButton(
                              onPressed: provider.isLoading ? null : _handleRegister,
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
                                      'Register رجسٹر',
                                      style: robotoBold(context).copyWith(
                                        fontSize: Dimensions.fontSizeLarge(context),
                                        color: Colors.white,
                                      ),
                                    ),
                            );
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Already have account link
                        Column(
                          children: [
                            Text(
                              "Already have an account?",
                              style: robotoRegular(context).copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            Text(
                              "پہلے سے اکاؤنٹ ہے؟",
                              style: robotoRegular(context).copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Login لاگ ان',
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
            ],
          ),
        ),
      ),
    );
  }
}









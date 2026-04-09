import 'package:deviceguardianadmin/providers/customer_provider.dart';
import 'package:deviceguardianadmin/providers/home_provider.dart';
import 'package:deviceguardianadmin/providers/profile_provider.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:deviceguardianadmin/widgets/custom_text_field_widget.dart';
import 'package:deviceguardianadmin/widgets/custom_location_dropdown_widget.dart';
import 'package:deviceguardianadmin/widgets/custom_phone_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/snack_bar_widget.dart';

import '../util/dimensions.dart';
import '../models/location_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();

  // Phone country code variables
  String _selectedCountryCode = '+92'; // Default to Pakistan
  String _selectedCountryIsoCode = 'PK'; // Default ISO code for Pakistan
  String? _initialPhoneNumber; // Initial phone number for edit mode
  int _phoneFieldKey = 0; // Key to rebuild phone field after data loads

  // Store provider reference to safely use in dispose
  CustomerProvider? _customerProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save the provider reference while the widget is still active
    _customerProvider ??= Provider.of<CustomerProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateFields();
      _initializeLocationDropdowns();
    });
  }

  void _populateFields() {
    final profileProvider = context.read<ProfileProvider>();
    
    _nameController.text = profileProvider.name != 'N/A' ? profileProvider.name : '';
    _emailController.text = profileProvider.email != 'N/A' ? profileProvider.email : '';
    _addressController.text = profileProvider.address != 'N/A' ? profileProvider.address : '';
    
    // Parse phone number to extract country code
    if (profileProvider.phone != 'N/A' && profileProvider.phone.isNotEmpty) {
      _parsePhoneNumber(profileProvider.phone);
    }
  }

  /// Parse phone number to extract country code and number
  void _parsePhoneNumber(String fullPhoneNumber) {
    String phoneNumber = fullPhoneNumber;
    
    if (fullPhoneNumber.startsWith('+')) {
      // Try to extract country code (common codes: +1, +44, +92, +91, etc.)
      // Check for Pakistan (+92) first as it's the default
      if (fullPhoneNumber.startsWith('+92')) {
        _selectedCountryCode = '+92';
        _selectedCountryIsoCode = 'PK';
        phoneNumber = fullPhoneNumber.substring(3);
      } else if (fullPhoneNumber.startsWith('+1')) {
        _selectedCountryCode = '+1';
        _selectedCountryIsoCode = 'US';
        phoneNumber = fullPhoneNumber.substring(2);
      } else if (fullPhoneNumber.startsWith('+44')) {
        _selectedCountryCode = '+44';
        _selectedCountryIsoCode = 'GB';
        phoneNumber = fullPhoneNumber.substring(3);
      } else if (fullPhoneNumber.startsWith('+91')) {
        _selectedCountryCode = '+91';
        _selectedCountryIsoCode = 'IN';
        phoneNumber = fullPhoneNumber.substring(3);
      } else if (fullPhoneNumber.startsWith('+971')) {
        _selectedCountryCode = '+971';
        _selectedCountryIsoCode = 'AE';
        phoneNumber = fullPhoneNumber.substring(4);
      } else if (fullPhoneNumber.startsWith('+966')) {
        _selectedCountryCode = '+966';
        _selectedCountryIsoCode = 'SA';
        phoneNumber = fullPhoneNumber.substring(4);
      } else {
        // Default to Pakistan if unknown country code
        _selectedCountryCode = '+92';
        _selectedCountryIsoCode = 'PK';
        // Try to find where the actual number starts (after + and country code digits)
        final match = RegExp(r'^\+(\d{1,4})(.*)$').firstMatch(fullPhoneNumber);
        if (match != null) {
          phoneNumber = match.group(2) ?? fullPhoneNumber;
        }
      }
    }
    
    // Remove any leading zeros from the phone number
    phoneNumber = phoneNumber.replaceFirst(RegExp(r'^0+'), '');
    
    setState(() {
      _initialPhoneNumber = phoneNumber;
      _phoneController.text = phoneNumber;
      _phoneFieldKey++; // Increment key to rebuild phone field
    });
    
    debugPrint('Parsed phone - Country Code: $_selectedCountryCode, ISO: $_selectedCountryIsoCode, Number: $phoneNumber');
  }

  Future<void> _initializeLocationDropdowns() async {
    final profileProvider = context.read<ProfileProvider>();
    final customerProvider = context.read<CustomerProvider>();
    
    // Clear previous selections
    customerProvider.clearLocationSelections();
    
    // Fetch countries first
    await customerProvider.fetchCountries();
    
    // Set location by IDs from profile
    final countryId = profileProvider.country.id;
    final stateId = profileProvider.state.id;
    final cityId = profileProvider.city.id;
    
    debugPrint('Initializing location dropdowns with Country: $countryId, State: $stateId, City: $cityId');
    
    if (countryId != 0 || stateId != 0 || cityId != 0) {
      await customerProvider.setLocationByIds(
        countryId: countryId,
        stateId: stateId,
        cityId: cityId,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    
    // Clear location selections after the frame is complete to avoid
    // "setState() called when widget tree was locked" error
    final provider = _customerProvider;
    if (provider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.clearLocationSelections();
      });
    }
    
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final profileProvider = context.read<ProfileProvider>();
      final customerProvider = context.read<CustomerProvider>();
      
      // Get selected location IDs and names from CustomerProvider
      final selectedCountry = customerProvider.selectedCountry;
      final selectedState = customerProvider.selectedState;
      final selectedCity = customerProvider.selectedCity;
      
      // Debug logging to trace location values
      debugPrint('=== SAVE PROFILE DEBUG ===');
      debugPrint('Selected Country: ${selectedCountry?.name} (ID: ${selectedCountry?.id})');
      debugPrint('Selected State: ${selectedState?.name} (ID: ${selectedState?.id})');
      debugPrint('Selected City: ${selectedCity?.name} (ID: ${selectedCity?.id})');
      debugPrint('Fallback Country ID: ${profileProvider.country.id}');
      debugPrint('Fallback State ID: ${profileProvider.state.id}');
      debugPrint('Fallback City ID: ${profileProvider.city.id}');
      
      final cityId = selectedCity?.id ?? profileProvider.city.id;
      final stateId = selectedState?.id ?? profileProvider.state.id;
      final countryId = selectedCountry?.id ?? profileProvider.country.id;
      
      debugPrint('Final City ID to send: $cityId');
      debugPrint('Final State ID to send: $stateId');
      debugPrint('Final Country ID to send: $countryId');
      debugPrint('=========================');
      
      final success = await profileProvider.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '$_selectedCountryCode${_phoneController.text.trim()}',
        address: _addressController.text.trim(),
        cityId: cityId,
        stateId: stateId,
        countryId: countryId,
        cityName: selectedCity?.name ?? profileProvider.cityName,
        stateName: selectedState?.name ?? profileProvider.stateName,
        countryName: selectedCountry?.name ?? profileProvider.countryName,
      );

      if (mounted) {
        if (success) {
          // Update HomeProvider with the new name
          context.read<HomeProvider>().updateUserName(_nameController.text.trim());
          
          showCustomSnackBar(context, "Profile updated successfully!", isError: false);
          Navigator.pop(context);
        } else {
          showCustomSnackBar(context, profileProvider.errorMessage ?? "Failed to update profile", isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(colorScheme),
              
              // Form Content
              Expanded(
                child: Consumer<ProfileProvider>(
                  builder: (context, profileProvider, child) {
                    return Stack(
                      children: [
                        SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Header
                                _buildProfileHeader(profileProvider),
                                const SizedBox(height: 24),

                                // Personal Information Section
                                _buildSectionTitle(
                                  'Personal Information',
                                  'ذاتی معلومات',
                                  Icons.person_rounded,
                                  Colors.blue,
                                ),
                                const SizedBox(height: 16),
                                _buildFormCard([
                                  CustomTextFieldWidget(
                                    labelText: 'Name (نام)',
                                    hintText: 'Enter your name',
                                    controller: _nameController,
                                    focusNode: _nameFocusNode,
                                    nextFocus: _phoneFocusNode,
                                    prefixIcon: Icons.person_outline_rounded,
                                    required: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                ]),
                                const SizedBox(height: 24),

                                // Contact Information Section
                                _buildSectionTitle(
                                  'Contact Information',
                                  'رابطے کی معلومات',
                                  Icons.contact_phone_rounded,
                                  Colors.green,
                                ),
                                const SizedBox(height: 16),
                                _buildFormCard([
                                  CustomTextFieldWidget(
                                    labelText: 'Email (ای میل)',
                                    hintText: 'Enter your email',
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    nextFocus: _phoneFocusNode,
                                    prefixIcon: Icons.email_rounded,
                                    inputType: TextInputType.emailAddress,
                                    readOnly: true,
                                    isEnabled: false,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomPhoneFieldWidget(
                                    key: ValueKey('phone_field_$_phoneFieldKey'),
                                    labelText: 'Phone No. فون نمبر',
                                    controller: _phoneController,
                                    focusNode: _phoneFocusNode,
                                    required: true,
                                    hintText: 'Enter phone number فون نمبر درج کریں',
                                    initialCountryCode: _selectedCountryIsoCode,
                                    initialValue: _initialPhoneNumber,
                                    onCountryCodeChanged: (countryCode) {
                                      setState(() {
                                        _selectedCountryCode = countryCode;
                                      });
                                    },
                                    validator: (phone) {
                                      if (phone == null || phone.number.isEmpty) {
                                        return 'Please enter your phone number فون نمبر درج کریں';
                                      }
                                      return null;
                                    },
                                  ),
                                ]),
                                const SizedBox(height: 24),

                                // Location Information Section
                                _buildSectionTitle(
                                  'Location Information',
                                  'مقام کی معلومات',
                                  Icons.location_on_rounded,
                                  Colors.orange,
                                ),
                                const SizedBox(height: 16),
                                _buildFormCard([
                                  CustomTextFieldWidget(
                                    labelText: 'Address (پتہ)',
                                    hintText: 'Enter your address',
                                    controller: _addressController,
                                    focusNode: _addressFocusNode,
                                    prefixIcon: Icons.home_rounded,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Country Dropdown
                                  Consumer<CustomerProvider>(
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
                                  const SizedBox(height: 16),
                                  
                                  // State Dropdown
                                  Consumer<CustomerProvider>(
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
                                  const SizedBox(height: 16),
                                  
                                  // City Dropdown
                                  Consumer<CustomerProvider>(
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
                                ]),
                                const SizedBox(height: 100), // Bottom padding for fixed button
                              ],
                            ),
                          ),
                        ),
                        
                        // Loading Overlay
                        if (profileProvider.isLoading)
                          Container(
                            color: Colors.white.withValues(alpha: 0.7),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Fixed Bottom Save Button
      bottomNavigationBar: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: _buildSaveButton(profileProvider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: colorScheme.primary, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  style: robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge(context),
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'پروفائل میں ترمیم کریں',
                  style: robotoRegular(context).copyWith(
                    fontSize: Dimensions.fontSizeSmall(context),
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ProfileProvider profileProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                _getInitials(profileProvider.name),
                style: robotoBold(context).copyWith(
                  fontSize: 24,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Your Profile',
                  style: robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeLarge(context),
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اپنی پروفائل اپڈیٹ کریں',
                  style: robotoRegular(context).copyWith(
                    fontSize: Dimensions.fontSizeSmall(context),
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Active Account',
                        style: robotoMedium(context).copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall(context),
                          color: Colors.green,
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
    );
  }

  Widget _buildSectionTitle(String title, String urduTitle, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: robotoBold(context).copyWith(
                fontSize: Dimensions.fontSizeLarge(context),
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              urduTitle,
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSaveButton(ProfileProvider profileProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: profileProvider.isLoading ? null : _handleSave,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (profileProvider.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else ...[
                const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Save Changes',
                  style: robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeDefault(context),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(تبدیلیاں محفوظ کریں)',
                  style: robotoRegular(context).copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall(context),
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'N/A') return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}




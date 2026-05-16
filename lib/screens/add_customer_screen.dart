import 'dart:convert';
import 'package:deviceguardianadmin/providers/customer_provider.dart';
import 'package:deviceguardianadmin/providers/profile_provider.dart';
import 'package:deviceguardianadmin/util/app_constants.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:deviceguardianadmin/widgets/custom_text_field_widget.dart';
import 'package:deviceguardianadmin/widgets/custom_phone_field_widget.dart';
import 'package:deviceguardianadmin/widgets/custom_location_dropdown_widget.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../util/dimensions.dart';
import '../models/location_model.dart';
import '../widgets/confirmation_dialog_widget.dart';
import '../widgets/custom_app_bar_widget.dart';
import '../widgets/custom_button_widget.dart';
import '../widgets/qr_scanner_dialog_widget.dart';
import '../widgets/snack_bar_widget.dart';
import '../widgets/validate_check.dart';

class AddCustomerScreen extends StatefulWidget {
  final int? customerId;

  const AddCustomerScreen({super.key, this.customerId});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final ScrollController _scrollController = ScrollController();
  GlobalKey<FormState>? _formKeyCustomer;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController imei1Controller = TextEditingController();
  final TextEditingController imei2Controller = TextEditingController();
  final TextEditingController mobileModelController = TextEditingController();

  // Mobile type dropdown options
  final List<String> _mobileTypeOptions = ['Android', 'iPhone'];
  String? _selectedMobileType;

  // Country dial code for phone field
  String _selectedCountryCode = '+92'; // Default to Pakistan
  String _selectedCountryIsoCode = 'PK'; // Default ISO code for Pakistan
  String? _initialPhoneNumber; // Initial phone number for edit mode
  int _phoneFieldKey = 0; // Key to rebuild phone field after data loads

  bool isEditMode = false;
  bool _isEditDataLoaded = false; // Track if edit data is fully loaded
  CustomerProvider? _customerProvider;

  @override
  void initState() {
    super.initState();
    _formKeyCustomer = GlobalKey<FormState>();
    isEditMode = widget.customerId != null;
    
    // Fetch countries and set default location on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      provider.clearLocationSelections();
      
      if (isEditMode) {
        // For edit mode - load customer data (which will set location by names)
        _loadCustomerData();
      } else {
        // For add mode - load user's default location from SharedPreferences
        _loadUserDefaultLocation(provider);
      }
    });
  }

  /// Load user's default location from ProfileProvider (for new customer)
  Future<void> _loadUserDefaultLocation(CustomerProvider provider) async {
    debugPrint('=== LOADING USER DEFAULT LOCATION FOR NEW CUSTOMER ===');
    
    // Get location from ProfileProvider (logged-in user's profile)
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    int userCountryId = 0;
    int userStateId = 0;
    int userCityId = 0;

    // Step 1: Check if profile data already exists in memory
    if (profileProvider.profileData != null) {
      debugPrint('Step 1: Profile data already in memory');
      userCountryId = profileProvider.country.id;
      userStateId = profileProvider.state.id;
      userCityId = profileProvider.city.id;
      debugPrint('  - From memory: Country=$userCountryId, State=$userStateId, City=$userCityId');
    }

    // Step 2: If no location in memory, try SharedPreferences directly (login data)
    if (userCountryId == 0 && userStateId == 0 && userCityId == 0) {
      debugPrint('Step 2: Loading from SharedPreferences (login data)...');
      final prefs = await SharedPreferences.getInstance();

      try {
        final countryJson = prefs.getString('user_country');
        debugPrint('  - user_country raw: $countryJson');
        if (countryJson != null && countryJson.isNotEmpty) {
          final countryData = jsonDecode(countryJson);
          userCountryId = countryData['id'] ?? 0;
          debugPrint('  - Parsed Country ID: $userCountryId');
        }
      } catch (e) {
        debugPrint('  - Error parsing country: $e');
      }

      try {
        final stateJson = prefs.getString('user_state');
        debugPrint('  - user_state raw: $stateJson');
        if (stateJson != null && stateJson.isNotEmpty) {
          final stateData = jsonDecode(stateJson);
          userStateId = stateData['id'] ?? 0;
          debugPrint('  - Parsed State ID: $userStateId');
        }
      } catch (e) {
        debugPrint('  - Error parsing state: $e');
      }

      try {
        final cityJson = prefs.getString('user_city');
        debugPrint('  - user_city raw: $cityJson');
        if (cityJson != null && cityJson.isNotEmpty) {
          final cityData = jsonDecode(cityJson);
          userCityId = cityData['id'] ?? 0;
          debugPrint('  - Parsed City ID: $userCityId');
        }
      } catch (e) {
        debugPrint('  - Error parsing city: $e');
      }
    }

    // Step 3: If still no data, try ProfileProvider's loadProfileDataFromPrefs
    if (userCountryId == 0 && userStateId == 0 && userCityId == 0) {
      debugPrint('Step 3: No data in SharedPreferences, trying ProfileProvider...');
      await profileProvider.loadProfileDataFromPrefs();
      userCountryId = profileProvider.country.id;
      userStateId = profileProvider.state.id;
      userCityId = profileProvider.city.id;
      debugPrint('  - From ProfileProvider: Country=$userCountryId, State=$userStateId, City=$userCityId');
    }

    // Step 4: If still no location data, fetch from API
    if (userCountryId == 0 && userStateId == 0 && userCityId == 0) {
      debugPrint('Step 4: No location found, fetching from API...');
      await profileProvider.fetchProfileData();
      userCountryId = profileProvider.country.id;
      userStateId = profileProvider.state.id;
      userCityId = profileProvider.city.id;
      debugPrint('  - From API: Country=$userCountryId, State=$userStateId, City=$userCityId');
    }

    debugPrint('Step 5: Final Location IDs to use:');
    debugPrint('  - Country ID: $userCountryId');
    debugPrint('  - State ID: $userStateId');
    debugPrint('  - City ID: $userCityId');

    // Fetch countries, then set location by IDs
    debugPrint('Step 6: Fetching countries list...');
    await provider.fetchCountries();
    debugPrint('  - Countries loaded: ${provider.countries.length} available');
    
    if (userCountryId != 0 || userStateId != 0 || userCityId != 0) {
      debugPrint('Step 7: Setting location by IDs...');
      await provider.setLocationByIds(
        countryId: userCountryId,
        stateId: userStateId,
        cityId: userCityId,
      );
      debugPrint('Step 8: Location set successfully!');
      debugPrint('  - Selected Country: ${provider.selectedCountry?.name} (ID: ${provider.selectedCountry?.id})');
      debugPrint('  - Selected State: ${provider.selectedState?.name} (ID: ${provider.selectedState?.id})');
      debugPrint('  - Selected City: ${provider.selectedCity?.name} (ID: ${provider.selectedCity?.id})');
    } else {
      debugPrint('Step 7: No location IDs found, dropdowns will be empty');
    }
    debugPrint('======================================================');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _customerProvider ??= Provider.of<CustomerProvider>(context, listen: false);
  }

  Future<void> _loadCustomerData() async {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    
    // Fetch countries first
    await customerProvider.fetchCountries();
    
    await customerProvider.getSingleCustomer(context, widget.customerId!);

    if (customerProvider.singleCustomer != null) {
      final customer = customerProvider.singleCustomer!;

      nameController.text = customer.customerName;
      
      // Parse phone number to extract country code
      _parsePhoneNumber(customer.customerMobileNo);
      
      emailController.text = customer.email;
      cnicController.text = customer.cnic;
      addressController.text = customer.address;
      imei1Controller.text = customer.imei1;
      imei2Controller.text = customer.imei2 ?? '';
      mobileModelController.text = customer.mobileModel ?? '';
      
      // Set mobile type dropdown value
      if (customer.mobileType.isNotEmpty) {
        // Match case-insensitively
        final matchedType = _mobileTypeOptions.firstWhere(
          (type) => type.toLowerCase() == customer.mobileType.toLowerCase(),
          orElse: () => '',
        );
        if (matchedType.isNotEmpty) {
          _selectedMobileType = matchedType;
        }
      }

      // Debug: Log the location IDs from customer
      debugPrint('=== EDIT CUSTOMER LOCATION DEBUG ===');
      debugPrint('Customer Country ID: ${customer.country}');
      debugPrint('Customer State ID: ${customer.state}');
      debugPrint('Customer City ID: ${customer.city}');
      debugPrint('Available Countries: ${customerProvider.countries.length}');
      debugPrint('====================================');

      // Load location data (Country -> State -> City) by IDs
      await customerProvider.setLocationByIds(
        countryId: customer.country,
        stateId: customer.state,
        cityId: customer.city,
      );
      
      // Debug: Log the selected values after setLocationByIds
      debugPrint('=== AFTER setLocationByIds ===');
      debugPrint('Selected Country: ${customerProvider.selectedCountry?.name} (ID: ${customerProvider.selectedCountry?.id})');
      debugPrint('Selected State: ${customerProvider.selectedState?.name} (ID: ${customerProvider.selectedState?.id})');
      debugPrint('Selected City: ${customerProvider.selectedCity?.name} (ID: ${customerProvider.selectedCity?.id})');
      debugPrint('==============================');

      if (customer.imei2 != null && customer.imei2!.isNotEmpty) {
        customerProvider.setImeiCount(2);
      } else {
        customerProvider.setImeiCount(1);
      }
      
      // Debug: Log isActive value before setting edit data as loaded
      debugPrint('=== CUSTOMER IS_ACTIVE DEBUG ===');
      debugPrint('customer.isActive: ${customer.isActive}');
      debugPrint('customer.isActive type: ${customer.isActive.runtimeType}');
      debugPrint('isActive != 0: ${customer.isActive != 0}');
      debugPrint('================================');
      
      // Mark edit data as loaded
      setState(() {
        _isEditDataLoaded = true;
      });
    }
  }

  /// Map of country codes to ISO codes for proper phone number parsing
  static const Map<String, String> _countryCodeToIso = {
    '+93': 'AF', // Afghanistan
    '+355': 'AL', // Albania
    '+213': 'DZ', // Algeria
    '+376': 'AD', // Andorra
    '+244': 'AO', // Angola
    '+54': 'AR', // Argentina
    '+374': 'AM', // Armenia
    '+61': 'AU', // Australia
    '+43': 'AT', // Austria
    '+994': 'AZ', // Azerbaijan
    '+973': 'BH', // Bahrain
    '+880': 'BD', // Bangladesh
    '+375': 'BY', // Belarus
    '+32': 'BE', // Belgium
    '+55': 'BR', // Brazil
    '+359': 'BG', // Bulgaria
    '+855': 'KH', // Cambodia
    '+237': 'CM', // Cameroon
    '+1': 'US', // USA/Canada (default to US)
    '+86': 'CN', // China
    '+57': 'CO', // Colombia
    '+506': 'CR', // Costa Rica
    '+385': 'HR', // Croatia
    '+53': 'CU', // Cuba
    '+357': 'CY', // Cyprus
    '+420': 'CZ', // Czech Republic
    '+45': 'DK', // Denmark
    '+20': 'EG', // Egypt
    '+372': 'EE', // Estonia
    '+251': 'ET', // Ethiopia
    '+358': 'FI', // Finland
    '+33': 'FR', // France
    '+49': 'DE', // Germany
    '+233': 'GH', // Ghana
    '+30': 'GR', // Greece
    '+852': 'HK', // Hong Kong
    '+36': 'HU', // Hungary
    '+354': 'IS', // Iceland
    '+91': 'IN', // India
    '+62': 'ID', // Indonesia
    '+98': 'IR', // Iran
    '+964': 'IQ', // Iraq
    '+353': 'IE', // Ireland
    '+972': 'IL', // Israel
    '+39': 'IT', // Italy
    '+81': 'JP', // Japan
    '+962': 'JO', // Jordan
    '+7': 'RU', // Russia/Kazakhstan (default to Russia)
    '+254': 'KE', // Kenya
    '+965': 'KW', // Kuwait
    '+996': 'KG', // Kyrgyzstan
    '+371': 'LV', // Latvia
    '+961': 'LB', // Lebanon
    '+218': 'LY', // Libya
    '+370': 'LT', // Lithuania
    '+352': 'LU', // Luxembourg
    '+60': 'MY', // Malaysia
    '+960': 'MV', // Maldives
    '+356': 'MT', // Malta
    '+52': 'MX', // Mexico
    '+373': 'MD', // Moldova
    '+976': 'MN', // Mongolia
    '+212': 'MA', // Morocco
    '+95': 'MM', // Myanmar
    '+977': 'NP', // Nepal
    '+31': 'NL', // Netherlands
    '+64': 'NZ', // New Zealand
    '+234': 'NG', // Nigeria
    '+47': 'NO', // Norway
    '+968': 'OM', // Oman
    '+92': 'PK', // Pakistan
    '+970': 'PS', // Palestine
    '+507': 'PA', // Panama
    '+51': 'PE', // Peru
    '+63': 'PH', // Philippines
    '+48': 'PL', // Poland
    '+351': 'PT', // Portugal
    '+974': 'QA', // Qatar
    '+40': 'RO', // Romania
    '+966': 'SA', // Saudi Arabia
    '+381': 'RS', // Serbia
    '+65': 'SG', // Singapore
    '+421': 'SK', // Slovakia
    '+386': 'SI', // Slovenia
    '+27': 'ZA', // South Africa
    '+82': 'KR', // South Korea
    '+34': 'ES', // Spain
    '+94': 'LK', // Sri Lanka
    '+249': 'SD', // Sudan
    '+46': 'SE', // Sweden
    '+41': 'CH', // Switzerland
    '+963': 'SY', // Syria
    '+886': 'TW', // Taiwan
    '+992': 'TJ', // Tajikistan
    '+255': 'TZ', // Tanzania
    '+66': 'TH', // Thailand
    '+216': 'TN', // Tunisia
    '+90': 'TR', // Turkey
    '+993': 'TM', // Turkmenistan
    '+256': 'UG', // Uganda
    '+380': 'UA', // Ukraine
    '+971': 'AE', // UAE
    '+44': 'GB', // United Kingdom
    '+598': 'UY', // Uruguay
    '+998': 'UZ', // Uzbekistan
    '+58': 'VE', // Venezuela
    '+84': 'VN', // Vietnam
    '+967': 'YE', // Yemen
    '+260': 'ZM', // Zambia
    '+263': 'ZW', // Zimbabwe
  };

  /// Parse phone number to extract country code and number
  void _parsePhoneNumber(String fullPhoneNumber) {
    String phoneNumber = fullPhoneNumber;
    
    if (fullPhoneNumber.startsWith('+')) {
      bool found = false;
      
      // Try to match country codes from longest to shortest (4 digits to 1 digit)
      // This ensures we match +971 before +97, +1 correctly, etc.
      for (int length = 4; length >= 1 && !found; length--) {
        if (fullPhoneNumber.length > length) {
          String possibleCode = fullPhoneNumber.substring(0, length + 1); // +1 for the '+' sign
          
          if (_countryCodeToIso.containsKey(possibleCode)) {
            _selectedCountryCode = possibleCode;
            _selectedCountryIsoCode = _countryCodeToIso[possibleCode]!;
            phoneNumber = fullPhoneNumber.substring(length + 1);
            found = true;
            debugPrint('Parsed country code: $_selectedCountryCode, ISO: $_selectedCountryIsoCode');
          }
        }
      }
      
      // If no match found, try to extract anyway but keep defaults
      if (!found) {
        debugPrint('Country code not found in map, keeping default. Full number: $fullPhoneNumber');
        // Try to extract phone number assuming 1-4 digit country code
        for (int i = 4; i >= 1; i--) {
          if (fullPhoneNumber.length > i + 1) {
            // Extract the country code part
            String extractedCode = fullPhoneNumber.substring(0, i + 1);
            phoneNumber = fullPhoneNumber.substring(i + 1);
            _selectedCountryCode = extractedCode;
            // Keep default ISO code since we don't know it
            break;
          }
        }
      }
    }
    
    // Set both controller and initialPhoneNumber for edit mode
    phoneController.text = phoneNumber;
    _initialPhoneNumber = phoneNumber;
    
    // Increment key to force rebuild of phone field widget
    _phoneFieldKey++;
    setState(() {});
  }

  @override
  void dispose() {
    if (_customerProvider != null) {
      if (isEditMode) {
        _customerProvider!.clearEditData();
      }
      _customerProvider!.clearAllData();
      // Don't call clearLocationSelections here - it calls notifyListeners() 
      // which is not allowed during dispose. We clear it on init instead.
    }

    phoneController.dispose();
    nameController.dispose();
    emailController.dispose();
    cnicController.dispose();
    addressController.dispose();
    imei1Controller.dispose();
    imei2Controller.dispose();
    mobileModelController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Opens QR/Barcode scanner dialog and fills the controller with scanned value
  void _openQrScanner(TextEditingController controller, String title) {
    showQrScannerDialog(
      context: context,
      title: title,
      onScanned: (String scannedValue) {
        setState(() {
          controller.text = scannedValue;
        });
        showCustomSnackBar(context, 'Scanned: $scannedValue', isError: false);
      },
    );
  }

  Future<void> _showBackPressedDialogue(BuildContext context, String title) async {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (BuildContext context) {
        return ConfirmationDialogWidget(
          title: title,
          description: "کیا آپ واقعی واپس جانا چاہتے ہیں؟\nAre you sure to go back?",
          onYesPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _showBackPressedDialogue(
            context,
            isEditMode ? "Customer Update Form Not Saved Yet" : "Customer Registration Form Not Saved Yet",
          );
        }
      },
      child: Scaffold(
        appBar: CustomAppBarWidget(
          title: isEditMode ? "Edit Customer\nکسٹمر میں ترمیم کریں" : "Add Customer\nکسٹمر شامل کریں",
          isBackButtonExist: true,
          onBackPressed: () async {
            await _showBackPressedDialogue(
              context,
              isEditMode ? "Customer Update Form Not Saved Yet" : "Customer Registration Form Not Saved Yet",
            );
          },
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Progress indicator section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeLarge,
                    vertical: Dimensions.paddingSizeSmall,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ذیل میں معلومات فراہم کریں\nProvide below information to proceed',
                        style: robotoRegular(context).copyWith(
                          fontSize: Dimensions.fontSizeSmall(context),
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      LinearProgressIndicator(
                        backgroundColor: Theme.of(context).disabledColor,
                        minHeight: 3,
                        value: 1.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                ),
                // Form content
                Expanded(
                  child: Consumer<CustomerProvider>(
                    builder: (context, customerProvider, child) {
                      // Show loading indicator in edit mode until data is fully loaded
                      if (isEditMode && !_isEditDataLoaded) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading customer data...'),
                            ],
                          ),
                        );
                      }
                      return SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeSmall,
                          horizontal: Dimensions.paddingSizeDefault,
                        ),
                        child: SizedBox(
                          width: Dimensions.webMaxWidth,
                          child: Column(
                            children: [
                              Form(
                                key: _formKeyCustomer,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                    // Personal Information Card
                                    _buildSectionCard(
                                      context,
                                      title: "Personal Information\nذاتی معلومات",
                                      children: [
                                        CustomTextFieldWidget(
                                          labelText: 'Customer Name کسٹمر کا نام',
                                          controller: nameController,
                                          required: true,
                                          prefixIcon: Icons.person,
                                          hintText: 'Enter customer name کسٹمر کا نام درج کریں',
                                          inputType: TextInputType.text,
                                          capitalization: TextCapitalization.none,
                                          isRequired: true,
                                          validator: (value) => ValidateCheck.validatePassword(
                                            value,
                                            'Enter your customer name کسٹمر کا نام درج کریں',
                                          ),
                                        ),
                                        const SizedBox(height: Dimensions.paddingSizeDefault),
                                        CustomTextFieldWidget(
                                          labelText: 'Email ای میل',
                                          controller: emailController,
                                          required: false,
                                          prefixIcon: Icons.email,
                                          hintText: 'Enter email ای میل درج کریں',
                                          inputType: TextInputType.emailAddress,
                                          capitalization: TextCapitalization.none,
                                          isRequired: false,
                                        ),
                                        const SizedBox(height: Dimensions.paddingSizeDefault),
                                        CustomPhoneFieldWidget(
                                          key: ValueKey('phone_field_$_phoneFieldKey'),
                                          labelText: 'Phone No. فون نمبر',
                                          controller: phoneController,
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
                                              return 'Enter customer phone no. کسٹمر فون نمبر درج کریں';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: Dimensions.paddingSizeDefault),
                                        CustomTextFieldWidget(
                                          labelText: 'CNIC No. شناختی کارڈ نمبر',
                                          controller: cnicController,
                                          required: true,
                                          prefixIcon: Icons.badge,
                                          hintText: 'Enter CNIC no. شناختی کارڈ نمبر درج کریں',
                                          inputType: TextInputType.number,
                                          capitalization: TextCapitalization.none,
                                          isRequired: true,
                                          validator: (value) => ValidateCheck.validatePassword(
                                            value,
                                            'Enter CNIC No. شناختی کارڈ نمبر درج کریں',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                    // Address Information Card
                                    _buildSectionCard(
                                      context,
                                      title: "Address Information\nپتے کی معلومات",
                                      children: [
                                        CustomTextFieldWidget(
                                          labelText: 'Address پتہ',
                                          controller: addressController,
                                          required: false,
                                          prefixIcon: Icons.location_on,
                                          hintText: 'Enter customer address کسٹمر کا پتہ درج کریں',
                                          inputType: TextInputType.streetAddress,
                                          capitalization: TextCapitalization.words,
                                          isRequired: false,
                                        ),
                                        const SizedBox(height: Dimensions.paddingSizeDefault),
                                        
                                        // Info banner for pre-filled location (only in ADD mode)
                                        if (!isEditMode)
                                          Container(
                                            margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                              border: Border.all(
                                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Theme.of(context).primaryColor,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: Dimensions.paddingSizeSmall),
                                                Expanded(
                                                  child: Text(
                                                    'Location pre-filled from your profile. You can change if needed.\nمقام آپ کے پروفائل سے پہلے سے بھرا ہوا ہے۔ ضرورت ہو تو تبدیل کر سکتے ہیں۔',
                                                    style: robotoRegular(context).copyWith(
                                                      fontSize: Dimensions.fontSizeExtraSmall(context),
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        
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
                                        const SizedBox(height: Dimensions.paddingSizeDefault),
                                        
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
                                        const SizedBox(height: Dimensions.paddingSizeDefault),
                                        
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
                                      ],
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                    // Device Information Card
                                    _buildSectionCard(
                                      context,
                                      title: "Device Information\nڈیوائس کی معلومات",
                                      children: [
                                        Text(
                                          'Select IMEI Type آئی ایم ای آئی کی قسم منتخب کریں',
                                          style: robotoBold(context).copyWith(
                                            fontSize: Dimensions.fontSizeSmall(context),
                                          ),
                                        ),
                                        const SizedBox(height: Dimensions.paddingSizeSmall),
                                        Consumer<CustomerProvider>(
                                          builder: (context, provider, child) => Column(
                                            children: [
                                              RadioListTile(
                                                title: Text('Single IMEI سنگل آئی ایم ای آئی'),
                                                value: 1,
                                                groupValue: provider.imeiCount,
                                                onChanged: (value) => provider.setImeiCount(value!),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              RadioListTile(
                                                title: Text('Dual IMEI ڈوئل آئی ایم آئی'),
                                                value: 2,
                                                groupValue: provider.imeiCount,
                                                onChanged: (value) => provider.setImeiCount(value!),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: Dimensions.paddingSizeDefault),
                                        // IMEI fields are disabled if customer is_active != 0 in edit mode
                                        Consumer<CustomerProvider>(
                                          builder: (context, provider, child) {
                                            // Check if IMEI fields should be disabled
                                            final bool isImeiDisabled = isEditMode && 
                                                provider.singleCustomer != null && 
                                                provider.singleCustomer!.isActive != 0;
                                            
                                            // Debug logging
                                            debugPrint('=== IMEI DISABLE CHECK ===');
                                            debugPrint('isEditMode: $isEditMode');
                                            debugPrint('singleCustomer is null: ${provider.singleCustomer == null}');
                                            if (provider.singleCustomer != null) {
                                              debugPrint('singleCustomer.isActive: ${provider.singleCustomer!.isActive}');
                                              debugPrint('isActive type: ${provider.singleCustomer!.isActive.runtimeType}');
                                            }
                                            debugPrint('isImeiDisabled: $isImeiDisabled');
                                            debugPrint('==========================');
                                            
                                            return Column(
                                              children: [
                                                // Show warning message if IMEI fields are disabled
                                                if (isImeiDisabled)
                                                  Container(
                                                    margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                      border: Border.all(color: Colors.orange, width: 1),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                                        const SizedBox(width: Dimensions.paddingSizeSmall),
                                                        Expanded(
                                                          child: Text(
                                                            'IMEI cannot be changed for active customers\nفعال کسٹمرز کے لیے IMEI تبدیل نہیں کیا جا سکتا',
                                                            style: robotoRegular(context).copyWith(
                                                              fontSize: Dimensions.fontSizeExtraSmall(context),
                                                              color: Colors.orange[800],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                CustomTextFieldWidget(
                                                  labelText: "IMEI-1 آئی ایم ای آئی 1",
                                                  controller: imei1Controller,
                                                  required: true,
                                                  prefixIcon: CupertinoIcons.barcode,
                                                  hintText: 'Enter phone imei-1 آئی ایم ای آئی 1 درج کریں',
                                                  inputType: TextInputType.text,
                                                  capitalization: TextCapitalization.none,
                                                  isRequired: true,
                                                  isEnabled: !isImeiDisabled,
                                                  readOnly: isImeiDisabled,
                                                  suffixChild: isImeiDisabled 
                                                      ? Icon(
                                                          Icons.lock,
                                                          color: Theme.of(context).disabledColor,
                                                        )
                                                      : IconButton(
                                                          icon: Icon(
                                                            Icons.qr_code_scanner,
                                                            color: Theme.of(context).primaryColor,
                                                          ),
                                                          onPressed: () => _openQrScanner(imei1Controller, 'Scan IMEI-1\nآئی ایم ای آئی 1 اسکین کریں'),
                                                        ),
                                                  validator: (value) => ValidateCheck.validatePassword(
                                                    value,
                                                    'Enter phone imei-1 آئی ایم ای آئی 1 درج کریں',
                                                  ),
                                                ),
                                                if (provider.imeiCount == 2) ...[
                                                  const SizedBox(height: Dimensions.paddingSizeDefault),
                                                  CustomTextFieldWidget(
                                                    labelText: "IMEI-2 آئی ایم ای آئی 2",
                                                    controller: imei2Controller,
                                                    required: true,
                                                    prefixIcon: CupertinoIcons.barcode,
                                                    hintText: 'Enter phone imei-2 آئی ایم ای آئی 2 درج کریں',
                                                    inputType: TextInputType.text,
                                                    capitalization: TextCapitalization.none,
                                                    isRequired: true,
                                                    isEnabled: !isImeiDisabled,
                                                    readOnly: isImeiDisabled,
                                                    suffixChild: isImeiDisabled 
                                                        ? Icon(
                                                            Icons.lock,
                                                            color: Theme.of(context).disabledColor,
                                                          )
                                                        : IconButton(
                                                            icon: Icon(
                                                              Icons.qr_code_scanner,
                                                              color: Theme.of(context).primaryColor,
                                                            ),
                                                            onPressed: () => _openQrScanner(imei2Controller, 'Scan IMEI-2\nآئی ایم ای آئی 2 اسکین کریں'),
                                                          ),
                                                    validator: (value) => ValidateCheck.validatePassword(
                                                      value,
                                                      'Enter phone imei-2 آئی ایم ای آئی 2 درج کریں',
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                        // Mobile Type Dropdown
                                        const SizedBox(height: Dimensions.paddingSizeDefault),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Mobile Type موبائل ٹائپ",
                                              style: robotoRegular(context).copyWith(
                                                fontSize: Dimensions.fontSizeDefault(context),
                                                color: Theme.of(context).hintColor,
                                              ),
                                            ),
                                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                                border: Border.all(
                                                  color: Theme.of(context).hintColor.withOpacity(0.3),
                                                ),
                                              ),
                                              child: DropdownButtonFormField<String>(
                                                value: _selectedMobileType,
                                                decoration: InputDecoration(
                                                  prefixIcon: Icon(
                                                    Icons.phone_android,
                                                    color: Theme.of(context).hintColor,
                                                  ),
                                                  border: InputBorder.none,
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: Dimensions.paddingSizeDefault,
                                                    vertical: Dimensions.paddingSizeSmall,
                                                  ),
                                                ),
                                                hint: Text(
                                                  'Select mobile type\nموبائل ٹائپ منتخب کریں',
                                                  style: robotoRegular(context).copyWith(
                                                    fontSize: Dimensions.fontSizeSmall(context),
                                                    color: Theme.of(context).hintColor,
                                                  ),
                                                ),
                                                items: _mobileTypeOptions.map((String type) {
                                                  return DropdownMenuItem<String>(
                                                    value: type,
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          type == 'Android' ? Icons.android : Icons.apple,
                                                          color: type == 'Android' ? Colors.green : Colors.grey,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          type,
                                                          style: robotoRegular(context).copyWith(
                                                            fontSize: Dimensions.fontSizeDefault(context),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (String? value) {
                                                  setState(() {
                                                    _selectedMobileType = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Mobile Model Field
                                        const SizedBox(height: Dimensions.paddingSizeDefault),
                                        CustomTextFieldWidget(
                                          labelText: "Mobile Model موبائل ماڈل",
                                          controller: mobileModelController,
                                          required: false,
                                          prefixIcon: Icons.smartphone,
                                          hintText: 'Enter mobile model (e.g., Samsung Galaxy S21)\nموبائل ماڈل درج کریں',
                                          inputType: TextInputType.text,
                                          capitalization: TextCapitalization.words,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                    // Documents Card
                                    _buildSectionCard(
                                      context,
                                      title: "Documents & Pictures\nدستاویزات اور تصاویر",
                                      children: [
                                        // Customer Profile Picture (single image) - moved to top
                                        _buildImagePickerSection(
                                          context,
                                          title: "Customer Picture کسٹمر کی تصویر",
                                          icon: Icons.person,
                                          onTap: () {
                                            Provider.of<CustomerProvider>(context, listen: false)
                                                .showProfilePictureSourceDialog(context);
                                          },
                                        ),
                                        _buildProfilePicturePreview(),

                                        // Front CNIC Picture
                                        _buildImagePickerSection(
                                          context,
                                          title: "Front CNIC سامنے والا شناختی کارڈ",
                                          icon: Icons.credit_card,
                                          onTap: () {
                                            Provider.of<CustomerProvider>(context, listen: false)
                                                .showFrontCnicSourceDialog(context);
                                          },
                                        ),
                                        _buildFrontCnicPreview(),

                                        // Back CNIC Picture
                                        _buildImagePickerSection(
                                          context,
                                          title: "Back CNIC پیچھے والا شناختی کارڈ",
                                          icon: Icons.credit_card_outlined,
                                          onTap: () {
                                            Provider.of<CustomerProvider>(context, listen: false)
                                                .showBackCnicSourceDialog(context);
                                          },
                                        ),
                                        _buildBackCnicPreview(),
                                        
                                        // Mobile Pictures
                                        _buildImagePickerSection(
                                          context,
                                          title: "Mobile Pictures موبائل کی تصاویر",
                                          icon: Icons.camera,
                                          onTap: () {
                                            Provider.of<CustomerProvider>(context, listen: false)
                                                .showImageSourceDialog(context, isMobilePicture: true);
                                          },
                                        ),
                                        _buildMobilePicturesGrid(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeLarge),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Button at the bottom
                _buildButtonView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: robotoBold(context).copyWith(
              fontSize: Dimensions.fontSizeSmall(context),
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          ...children,
        ],
      ),
    );
  }

  Widget _buildImagePickerSection(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).disabledColor, width: 0.5),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 35, color: Theme.of(context).primaryColor),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Text(
                title,
                style: robotoBold(context).copyWith(
                  fontSize: Dimensions.fontSizeSmall(context),
                ),
              ),
            ),
            Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontCnicPreview() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        // Check for local file first (newly selected)
        final hasLocalFile = customerProvider.frontCnicPicture != null;
        // Check for existing URL image (from API in edit mode)
        final hasUrlImage = isEditMode && 
            customerProvider.singleCustomer != null && 
            customerProvider.singleCustomer!.cnicFrontImage.isNotEmpty;
        
        if (!hasLocalFile && !hasUrlImage) {
          return const SizedBox(height: Dimensions.paddingSizeDefault);
        }
        
        return Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeSmall),
          child: DottedBorder(
            color: Theme.of(context).primaryColor,
            strokeWidth: 2,
            dashPattern: const [8, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(Dimensions.radiusDefault),
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: hasLocalFile
                          ? Image.file(
                              customerProvider.frontCnicPicture!,
                              width: 200,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              '${AppConstants.imageUrl}${customerProvider.singleCustomer!.cnicFrontImage}',
                              width: 200,
                              height: 120,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildShimmerPlaceholder(width: 200, height: 120);
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error, color: Colors.red),
                                );
                              },
                            ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          if (hasLocalFile) {
                            customerProvider.removeFrontCnicPicture();
                          } else {
                            // Clear existing URL image
                            customerProvider.clearExistingFrontCnicImage();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackCnicPreview() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        // Check for local file first (newly selected)
        final hasLocalFile = customerProvider.backCnicPicture != null;
        // Check for existing URL image (from API in edit mode)
        final hasUrlImage = isEditMode && 
            customerProvider.singleCustomer != null && 
            customerProvider.singleCustomer!.cnicBackImage.isNotEmpty;
        
        if (!hasLocalFile && !hasUrlImage) {
          return const SizedBox(height: Dimensions.paddingSizeDefault);
        }
        
        return Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeSmall),
          child: DottedBorder(
            color: Theme.of(context).primaryColor,
            strokeWidth: 2,
            dashPattern: const [8, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(Dimensions.radiusDefault),
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: hasLocalFile
                          ? Image.file(
                              customerProvider.backCnicPicture!,
                              width: 200,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              '${AppConstants.imageUrl}${customerProvider.singleCustomer!.cnicBackImage}',
                              width: 200,
                              height: 120,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildShimmerPlaceholder(width: 200, height: 120);
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error, color: Colors.red),
                                );
                              },
                            ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          if (hasLocalFile) {
                            customerProvider.removeBackCnicPicture();
                          } else {
                            // Clear existing URL image
                            customerProvider.clearExistingBackCnicImage();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePicturePreview() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        // Check for local file first (newly selected)
        final hasLocalFile = customerProvider.profilePicture != null;
        // Check for existing URL image (from API in edit mode)
        final hasUrlImage = isEditMode && 
            customerProvider.singleCustomer != null && 
            customerProvider.singleCustomer!.profileImage.isNotEmpty;
        
        if (!hasLocalFile && !hasUrlImage) {
          return const SizedBox(height: Dimensions.paddingSizeDefault);
        }
        
        return Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeSmall),
          child: DottedBorder(
            color: Theme.of(context).primaryColor,
            strokeWidth: 2,
            dashPattern: const [8, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(Dimensions.radiusDefault),
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: hasLocalFile
                          ? Image.file(
                              customerProvider.profilePicture!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              '${AppConstants.imageUrl}${customerProvider.singleCustomer!.profileImage}',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildShimmerPlaceholder(width: 120, height: 120);
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error, color: Colors.red),
                                );
                              },
                            ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          if (hasLocalFile) {
                            customerProvider.removeProfilePicture();
                          } else {
                            // Clear existing URL image
                            customerProvider.clearExistingProfileImage();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobilePicturesGrid() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        if (customerProvider.existingMobilePictures.isEmpty && customerProvider.mobilePictures.isEmpty) {
          return const SizedBox(height: Dimensions.paddingSizeDefault);
        }
        return Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeSmall),
          child: DottedBorder(
            color: Theme.of(context).primaryColor,
            strokeWidth: 2,
            dashPattern: const [8, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(Dimensions.radiusDefault),
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: Dimensions.paddingSizeDefault,
                runSpacing: Dimensions.paddingSizeDefault,
                children: [
                  ...customerProvider.existingMobilePictures.asMap().entries.map((entry) {
                    return _buildImageItem(
                      imageUrl: '${AppConstants.imageUrl}${entry.value}',
                      onRemove: () => customerProvider.removeExistingMobilePicture(entry.key),
                    );
                  }),
                  ...customerProvider.mobilePictures.asMap().entries.map((entry) {
                    return _buildFileImageItem(
                      file: entry.value,
                      onRemove: () => customerProvider.removeMobilePicture(entry.key),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildImageItem({required String imageUrl, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Image.network(
            imageUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildShimmerPlaceholder();
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Icon(Icons.error, color: Colors.red),
              );
            },
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }

  Widget _buildFileImageItem({required dynamic file, required VoidCallback onRemove}) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonView() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) => CustomButtonWidget(
        radius: Dimensions.radiusSmall,
        isBold: true,
        fontSize: Dimensions.fontSizeLarge(context),
        isLoading: customerProvider.isLoading,
        color: Theme.of(context).primaryColor,
        margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        buttonText: isEditMode ? 'Update Customer' : 'Register Customer',
        urduText: isEditMode ? 'کسٹمر اپڈیٹ کریں' : 'کسٹمر رجسٹر کریں',
        icon: isEditMode ? Icons.update : Icons.person_add,
        onPressed: () => _submitForm(customerProvider),
      ),
    );
  }

  Future<void> _submitForm(CustomerProvider customerProvider) async {
    if (_formKeyCustomer!.currentState!.validate()) {
      // Manual IMEI validation
      if (customerProvider.imeiCount == 1 && imei1Controller.text.trim().isEmpty) {
        showCustomSnackBar(context, 'Please enter IMEI-1', isError: true);
        return;
      }
      if (customerProvider.imeiCount == 2 &&
          (imei1Controller.text.trim().isEmpty || imei2Controller.text.trim().isEmpty)) {
        showCustomSnackBar(context, 'Please enter both IMEI numbers', isError: true);
        return;
      }

      // Check total file size before uploading
      final totalSizeMB = customerProvider.getTotalFileSizeMB();
      if (totalSizeMB > 15) {
        showCustomSnackBar(context, 'Total file size (${totalSizeMB.toStringAsFixed(2)} MB) is too large. Please reduce the number of images.', isError: true);
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                isEditMode
                    ? 'Updating customer...'
                    : 'Uploading ${(customerProvider.profilePicture != null ? 1 : 0) + (customerProvider.frontCnicPicture != null ? 1 : 0) + (customerProvider.backCnicPicture != null ? 1 : 0) + customerProvider.mobilePictures.length} files...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );

      // Call update or register API based on mode
      final phoneWithCountryCode = '$_selectedCountryCode${phoneController.text.trim()}';
      
      // Get location IDs from selected values
      final selectedCountryId = customerProvider.selectedCountry?.id ?? 0;
      final selectedStateId = customerProvider.selectedState?.id ?? 0;
      final selectedCityId = customerProvider.selectedCity?.id ?? 0;
      
      // DEBUG: Log the values being sent to API
      debugPrint('=== ADD/EDIT CUSTOMER - API REQUEST DATA ===');
      debugPrint('Mode: ${isEditMode ? 'EDIT' : 'ADD'}');
      debugPrint('Customer Name: ${nameController.text.trim()}');
      debugPrint('Phone: $phoneWithCountryCode');
      debugPrint('Email: ${emailController.text.trim()}');
      debugPrint('CNIC: ${cnicController.text.trim()}');
      debugPrint('----- LOCATION IDs -----');
      debugPrint('Country ID: $selectedCountryId (${customerProvider.selectedCountry?.name ?? 'None'})');
      debugPrint('State ID: $selectedStateId (${customerProvider.selectedState?.name ?? 'None'})');
      debugPrint('City ID: $selectedCityId (${customerProvider.selectedCity?.name ?? 'None'})');
      debugPrint('----- DEVICE INFO -----');
      debugPrint('Mobile Type: $_selectedMobileType');
      debugPrint('Mobile Model: ${mobileModelController.text.trim()}');
      debugPrint('IMEI-1: ${imei1Controller.text.trim()}');
      debugPrint('IMEI-2: ${customerProvider.imeiCount == 2 ? imei2Controller.text.trim() : 'N/A'}');
      debugPrint('IMEI Type: ${(customerProvider.imeiCount == 2 && imei2Controller.text.trim().isNotEmpty) ? 'double' : 'single'}');
      debugPrint('==========================================');

      final result = isEditMode
          ? await customerProvider.updateUserDevice(
              customerId: widget.customerId!,
              customerName: nameController.text.trim(),
              email: emailController.text.trim(),
              cnic: cnicController.text.trim(),
              customerMobileNo: phoneWithCountryCode,
              imei1: imei1Controller.text.trim(),
              imei2: customerProvider.imeiCount == 2 ? imei2Controller.text.trim() : null,
              address: addressController.text.trim(),
              countryId: selectedCountryId,
              cityId: selectedCityId,
              stateId: selectedStateId,
              mobileType: _selectedMobileType,
              mobileModel: mobileModelController.text.trim(),
              profilePicture: customerProvider.profilePicture,
              frontCnicPicture: customerProvider.frontCnicPicture,
              backCnicPicture: customerProvider.backCnicPicture,
              mobilePictures: customerProvider.mobilePictures,
              documents: customerProvider.documents,
            )
          : await customerProvider.registerUserDevice(
              customerName: nameController.text.trim(),
              email: emailController.text.trim(),
              cnic: cnicController.text.trim(),
              customerMobileNo: phoneWithCountryCode,
              imei1: imei1Controller.text.trim(),
              imei2: customerProvider.imeiCount == 2 ? imei2Controller.text.trim() : null,
              address: addressController.text.trim(),
              countryId: selectedCountryId,
              cityId: selectedCityId,
              stateId: selectedStateId,
              mobileType: _selectedMobileType,
              mobileModel: mobileModelController.text.trim(),
              profilePicture: customerProvider.profilePicture,
              frontCnicPicture: customerProvider.frontCnicPicture,
              backCnicPicture: customerProvider.backCnicPicture,
              mobilePictures: customerProvider.mobilePictures,
              documents: customerProvider.documents,
            );

      // Close loading indicator
      Navigator.pop(context);

      if (result['success'] == true) {
        showCustomSnackBar(context, isEditMode ? 'Customer updated successfully!' : 'Customer registered successfully!', isError: false);
        // Clear form
        _clearForm();
        customerProvider.clearAllData();
        customerProvider.clearEditData();
        Navigator.pop(context, true);
      } else {
        showCustomSnackBar(context, result['error'] ?? (isEditMode ? 'Failed to update customer' : 'Failed to register customer'), isError: true);
      }
    }
  }

  void _clearForm() {
    nameController.clear();
    emailController.clear();
    cnicController.clear();
    phoneController.clear();
    addressController.clear();
    imei1Controller.clear();
    imei2Controller.clear();
    mobileModelController.clear();
    _selectedMobileType = null;
    
    // Clear location selections
    _customerProvider?.clearLocationSelections();
  }

  Widget _buildShimmerPlaceholder({double width = 100, double height = 100}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
      ),
    );
  }
}


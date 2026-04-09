import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:intl_phone_field/countries.dart';

import '../util/dimensions.dart';
import '../util/styles.dart';

class CustomPhoneFieldWidget extends StatefulWidget {
  final String? labelText;
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool isEnabled;
  final bool required;
  final bool showLabelText;
  final String initialCountryCode;
  final String? initialValue; // Initial phone number value for edit mode
  final Function(PhoneNumber)? onChanged;
  final Function(Country)? onCountryChanged;
  final String? Function(PhoneNumber?)? validator;
  final Function(String)? onPhoneNumberChanged;
  final Function(String)? onCountryCodeChanged;

  const CustomPhoneFieldWidget({
    super.key,
    this.labelText,
    this.hintText = 'Enter phone number',
    this.controller,
    this.focusNode,
    this.isEnabled = true,
    this.required = false,
    this.showLabelText = true,
    this.initialCountryCode = 'PK',
    this.initialValue,
    this.onChanged,
    this.onCountryChanged,
    this.validator,
    this.onPhoneNumberChanged,
    this.onCountryCodeChanged,
  });

  @override
  State<CustomPhoneFieldWidget> createState() => _CustomPhoneFieldWidgetState();
}

class _CustomPhoneFieldWidgetState extends State<CustomPhoneFieldWidget> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.isEnabled,
      initialCountryCode: widget.initialCountryCode,
      initialValue: widget.initialValue,
      disableLengthCheck: false,
      dropdownIcon: Icon(
        Icons.arrow_drop_down,
        color: _hasFocus
            ? Theme.of(context).primaryColor
            : Theme.of(context).hintColor.withValues(alpha: 0.7),
      ),
      dropdownIconPosition: IconPosition.trailing,
      flagsButtonPadding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
      dropdownTextStyle: robotoRegular(context).copyWith(
        fontSize: Dimensions.fontSizeLarge(context),
      ),
      style: robotoRegular(context).copyWith(
        fontSize: Dimensions.fontSizeLarge(context),
      ),
      decoration: InputDecoration(
        errorMaxLines: 2,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          borderSide: BorderSide(
            width: 0.3,
            color: Theme.of(context).disabledColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          borderSide: BorderSide(
            width: 1,
            color: Theme.of(context).primaryColor,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          borderSide: BorderSide(
            width: 0.3,
            color: Theme.of(context).primaryColor,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        isDense: true,
        hintText: widget.hintText,
        fillColor: !widget.isEnabled
            ? Theme.of(context).disabledColor.withValues(alpha: 0.1)
            : Theme.of(context).cardColor,
        hintStyle: robotoRegular(context).copyWith(
          fontSize: Dimensions.fontSizeSmall(context),
          color: Theme.of(context).hintColor.withValues(alpha: 0.7),
        ),
        filled: true,
        labelStyle: widget.showLabelText
            ? robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeDefault(context),
                color: Theme.of(context).hintColor,
              )
            : null,
        errorStyle: robotoRegular(context).copyWith(
          fontSize: Dimensions.fontSizeSmall(context),
        ),
        label: widget.showLabelText && widget.labelText != null
            ? Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: widget.labelText!,
                      style: robotoRegular(context).copyWith(
                        fontSize: Dimensions.fontSizeLarge(context),
                        color: (_hasFocus || (widget.controller?.text.isNotEmpty ?? false)) && widget.isEnabled
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).hintColor.withValues(alpha: .75),
                      ),
                    ),
                    if (widget.required)
                      TextSpan(
                        text: ' *',
                        style: robotoRegular(context).copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: Dimensions.fontSizeLarge(context),
                        ),
                      ),
                  ],
                ),
              )
            : null,
      ),
      languageCode: "en",
      onChanged: (phone) {
        widget.onChanged?.call(phone);
        widget.onPhoneNumberChanged?.call(phone.number);
      },
      onCountryChanged: (country) {
        widget.onCountryChanged?.call(country);
        widget.onCountryCodeChanged?.call('+${country.dialCode}');
      },
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      invalidNumberMessage: 'Invalid phone number فون نمبر درست نہیں ہے',
    );
  }
}


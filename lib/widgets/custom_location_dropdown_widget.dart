import 'package:flutter/material.dart';

import '../util/dimensions.dart';
import '../util/styles.dart';

/// A reusable searchable dropdown widget for location selection (Country, State, City)
class CustomLocationDropdown<T> extends StatelessWidget {
  final String labelText;
  final String hintText;
  final T? selectedValue;
  final List<T> items;
  final bool isLoading;
  final bool isEnabled;
  final bool required;
  final IconData prefixIcon;
  final String Function(T) displayText;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const CustomLocationDropdown({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.selectedValue,
    required this.items,
    required this.displayText,
    this.isLoading = false,
    this.isEnabled = true,
    this.required = false,
    this.prefixIcon = Icons.location_on,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: selectedValue,
      validator: (value) {
        if (validator != null) {
          return validator!(value);
        }
        if (required && value == null) {
          return 'Please select $labelText';
        }
        return null;
      },
      builder: (FormFieldState<T> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: isEnabled && !isLoading && items.isNotEmpty
                  ? () {
                      // Remove focus from any text field before showing dropdown
                      FocusScope.of(context).unfocus();
                      _showSearchableBottomSheet(context, state);
                    }
                  : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  errorMaxLines: 2,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    borderSide: BorderSide(
                      width: 0.3,
                      color: state.hasError 
                          ? Theme.of(context).colorScheme.error 
                          : Theme.of(context).disabledColor,
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
                  fillColor: !isEnabled
                      ? Theme.of(context).disabledColor.withValues(alpha: 0.1)
                      : Theme.of(context).cardColor,
                  filled: true,
                  errorText: state.errorText,
                  errorStyle: robotoRegular(context).copyWith(
                    fontSize: Dimensions.fontSizeSmall(context),
                  ),
                  label: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: labelText,
                          style: robotoRegular(context).copyWith(
                            fontSize: Dimensions.fontSizeLarge(context),
                            color: Theme.of(context).hintColor.withValues(alpha: .75),
                          ),
                        ),
                        if (required)
                          TextSpan(
                            text: ' *',
                            style: robotoRegular(context).copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: Dimensions.fontSizeLarge(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                  prefixIcon: Icon(
                    prefixIcon,
                    size: 18,
                    color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                  ),
                  suffixIcon: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).hintColor,
                        ),
                ),
                child: Text(
                  selectedValue != null
                      ? displayText(selectedValue as T)
                      : isLoading
                          ? 'Loading...'
                          : items.isEmpty
                              ? 'No data available'
                              : hintText,
                  style: robotoRegular(context).copyWith(
                    fontSize: Dimensions.fontSizeLarge(context),
                    color: selectedValue != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).hintColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSearchableBottomSheet(BuildContext context, FormFieldState<T> state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return _SearchableBottomSheet<T>(
          title: labelText,
          items: items,
          selectedValue: selectedValue,
          displayText: displayText,
          onSelected: (T? value) {
            state.didChange(value);
            onChanged?.call(value);
            Navigator.pop(bottomSheetContext);
          },
        );
      },
    ).then((_) {
      // Unfocus any field after bottom sheet closes
      FocusScope.of(context).unfocus();
    });
  }
}

class _SearchableBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final String Function(T) displayText;
  final void Function(T?) onSelected;

  const _SearchableBottomSheet({
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.displayText,
    required this.onSelected,
  });

  @override
  State<_SearchableBottomSheet<T>> createState() => _SearchableBottomSheetState<T>();
}

class _SearchableBottomSheetState<T> extends State<_SearchableBottomSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return widget.displayText(item).toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Text(
              'Select ${widget.title}',
              style: robotoBold(context).copyWith(
                fontSize: Dimensions.fontSizeLarge(context),
              ),
            ),
          ),
          
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search ${widget.title}...',
                hintStyle: robotoRegular(context).copyWith(
                  color: Theme.of(context).hintColor,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterItems('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  borderSide: BorderSide(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  borderSide: BorderSide(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeSmall,
                ),
              ),
              onChanged: _filterItems,
            ),
          ),
          
          const SizedBox(height: Dimensions.paddingSizeSmall),
          
          // Items count
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredItems.length} items found',
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeSmall(context),
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: Dimensions.paddingSizeSmall),
          
          // Items list
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          'No results found',
                          style: robotoRegular(context).copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                    ),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = widget.selectedValue == item;
                      
                      return ListTile(
                        title: Text(
                          widget.displayText(item),
                          style: robotoRegular(context).copyWith(
                            fontSize: Dimensions.fontSizeDefault(context),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected 
                                ? Theme.of(context).primaryColor 
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                              )
                            : null,
                        onTap: () => widget.onSelected(item),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        ),
                        tileColor: isSelected
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}



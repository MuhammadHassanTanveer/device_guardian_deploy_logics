import 'package:deviceguardianadmin/screens/add_customer_screen.dart';
import 'package:deviceguardianadmin/screens/customer_management_screen.dart';
import 'package:deviceguardianadmin/screens/login_screen.dart';
import 'package:deviceguardianadmin/widgets/custom_dropdown_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/snack_bar_widget.dart';

import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../util/app_constants.dart';
import '../util/dimensions.dart';
import '../util/styles.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  bool isInit = true;
  String _selectedFilter = 'All'; // Filter state variable (display value)
  String _selectedFilterValue = 'all'; // Filter value for API
  String _searchQuery = ''; // Search query state variable
  bool _isSearchExpanded = false; // Track if search bar is expanded

  // TextEditingController for search bar
  final TextEditingController _searchController = TextEditingController();

  // RefreshController for pull_to_refresh
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  // Filter options (display name -> API value)
  final Map<String, String> _filterOptionsMap = {
    'All': 'all',
    'In-active': '0',
    'Active': '1',
    'Uninstall': '2',
  };

  // Filter display options
  List<String> get _filterOptions => _filterOptionsMap.keys.toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Check if user has auth token before fetching
        final prefs = await SharedPreferences.getInstance();
        final authToken = prefs.getString('auth_token') ?? '';

        if (authToken.isEmpty) {
          // No token found, redirect to login
          if (mounted) {
            showCustomSnackBar(context, "Please login to view customers", isError: true);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        }

        if (mounted) {
          final customerProvider = Provider.of<CustomerProvider>(
            context,
            listen: false,
          );
          await customerProvider.fetchCustomers(
            context,
            isRefresh: true,
            filter: _selectedFilterValue,
            search: _searchQuery,
          );

          // Check if unauthorized after fetch
          if (customerProvider.customersModel?.message == 'Unauthorized') {
            if (mounted) {
              showCustomSnackBar(context, "Session expired. Please login again", isError: true);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        }
      });
      isInit = false;
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Pull-to-refresh handler
  Future<void> _onRefresh() async {
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    final result = await customerProvider.fetchCustomers(
      context,
      isRefresh: true,
      filter: _selectedFilterValue,
      search: _searchQuery,
    );

    if (result) {
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshFailed();
    }

    // Check if unauthorized after refresh
    if (customerProvider.customersModel?.message == 'Unauthorized' && mounted) {
      showCustomSnackBar(context, "Session expired. Please login again", isError: true);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Load more handler
  Future<void> _onLoading() async {
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    final result = await customerProvider.fetchMoreCustomers(context);
    
    if (result) {
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  Future<void> _refreshCustomers() async {
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    await customerProvider.fetchCustomers(
      context,
      isRefresh: true,
      filter: _selectedFilterValue,
      search: _searchQuery,
    );

    // Check if unauthorized after refresh
    if (customerProvider.customersModel?.message == 'Unauthorized' && mounted) {
      showCustomSnackBar(context, "Session expired. Please login again", isError: true);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = Provider.of<CustomerProvider>(context);
    // No client-side filtering - API handles filtering and search
    final customers = provider.customers;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: AnimatedContainer(
        duration: const Duration(seconds: 1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface, // Alice blue background (F0F8FF)
              colorScheme.tertiaryContainer, // Lighter sky blue (A8C6FF)
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Card(
                elevation: 2,
                color: colorScheme.surface,
                margin: EdgeInsets.only(
                  left: Dimensions.paddingSizeDefault,
                  right: Dimensions.paddingSizeDefault,
                  top: Dimensions.paddingSizeDefault,
                  bottom: 4,
                ),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "Customers List",
                          style: robotoBold(context).copyWith(
                            fontSize: Dimensions.fontSizeOverLarge(context),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: provider.isLoading ? null : _refreshCustomers,
                      icon: provider.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              // Filter dropdown
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: 2,
                ),
                child: Card(
                  elevation: 2,
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: SizedBox(
                      height: 42, // Fixed height to prevent resizing
                      child: Row(
                        children: [
                          // Filter section - hide when search is expanded
                          if (!_isSearchExpanded) ...[
                            Icon(
                              Icons.filter_list,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Filter:',
                              style: robotoBold(context).copyWith(
                                fontSize: Dimensions.fontSizeDefault(context),
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                // width: 140,
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: CustomDropdown<String>(
                                  canAddValue: false,
                                  icon: Icon(
                                    Icons.arrow_drop_down_circle,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  dropdownStyle: DropdownStyle(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    elevation: 3,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                  dropdownButtonStyle: const DropdownButtonStyle(
                                    height: 34,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  ),
                                  onChange: (String? value, int index) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedFilter = value;
                                        _selectedFilterValue = _filterOptionsMap[value] ?? 'all';
                                      });
                                      // Trigger API call with new filter
                                      _refreshCustomers();
                                    }
                                  },
                                  items: _filterOptions.map((String value) {
                                    return DropdownItem<String>(
                                      value: value,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        child: Text(
                                          value,
                                          style: robotoRegular(context).copyWith(
                                            fontSize: Dimensions.fontSizeDefault(context),
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _selectedFilter,
                                      style: robotoRegular(context).copyWith(
                                        fontSize: Dimensions.fontSizeDefault(context),
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),  
                          ],
                          // Search section
                          if (_isSearchExpanded)
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: colorScheme.primary.withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        autofocus: true,
                                        style: robotoRegular(context).copyWith(
                                          fontSize: Dimensions.fontSizeDefault(context),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Search by name, mobile, IMEI...',
                                          hintStyle: robotoRegular(context).copyWith(
                                            fontSize: Dimensions.fontSizeSmall(context),
                                            color: Colors.grey,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          isDense: true,
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: colorScheme.primary,
                                            size: 20,
                                          ),
                                          suffixIcon: _searchController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(Icons.clear, size: 18, color: Colors.grey),
                                                  onPressed: () {
                                                    setState(() {
                                                      _searchController.clear();
                                                      _searchQuery = '';
                                                    });
                                                    // Trigger API call to clear search
                                                    _refreshCustomers();
                                                  },
                                                )
                                              : null,
                                        ),
                                        onSubmitted: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                          // Trigger API call with search
                                          _refreshCustomers();
                                        },
                                        onChanged: (value) {
                                          setState(() {}); // Rebuild to show/hide clear button
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Search button
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _searchQuery = _searchController.text;
                                      });
                                      // Trigger API call with search
                                      _refreshCustomers();
                                    },
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.search,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Close button
                                  GestureDetector(
                                    onTap: () {
                                      final hadSearchQuery = _searchQuery.isNotEmpty;
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                        _isSearchExpanded = false;
                                      });
                                      // Refresh customers if we had a search query
                                      if (hadSearchQuery) {
                                        _refreshCustomers();
                                      }
                                    },
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            // Search icon button when collapsed
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSearchExpanded = true;
                                });
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SmartRefresher(
                        controller: _refreshController,
                        enablePullDown: true,
                        enablePullUp: true,
                        onRefresh: _onRefresh,
                        onLoading: _onLoading,
                        header: const WaterDropHeader(
                          waterDropColor: Colors.blue,
                        ),
                        footer: CustomFooter(
                          builder: (BuildContext context, LoadStatus? mode) {
                            Widget body;
                            if (mode == LoadStatus.idle) {
                              body = const Text("Pull up to load more");
                            } else if (mode == LoadStatus.loading) {
                              body = const CircularProgressIndicator(strokeWidth: 2);
                            } else if (mode == LoadStatus.failed) {
                              body = const Text("Load Failed! Click to retry");
                            } else if (mode == LoadStatus.canLoading) {
                              body = const Text("Release to load more");
                            } else {
                              body = const Text("No more customers");
                            }
                            return Container(
                              height: 55.0,
                              child: Center(child: body),
                            );
                          },
                        ),
                        child: customers.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 72,
                                        color: colorScheme.primary.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No customers found',
                                        style: robotoBold(context).copyWith(
                                          fontSize: Dimensions.fontSizeLarge(context),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Pull to refresh or add a new customer',
                                        style: robotoRegular(context),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: _refreshCustomers,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                      )
                                    ],
                                  ),
                                ],
                              )
                            : ListView.separated(
                            padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                            itemBuilder: (context, index) {
                              final customer = customers[index];

                              // Find matching device by IMEI1 or IMEI2
                              Datum? matchingDevice;
                              try {
                                matchingDevice = provider.userDevices
                                    .firstWhere((device) {
                                      debugPrint("customer imei1 ${customer.imei1}");
                                      debugPrint("device imei1 ${device.imei1}");
                                      final imei1Match =
                                          customer.imei1.toString().isNotEmpty &&
                                          device.imei1.toString() ==
                                              customer.imei1.toString();

                                      final imei2Match =
                                          customer.imei2 != null &&
                                          customer.imei2!.isNotEmpty &&
                                          device.imei2 != null &&
                                          device.imei2!.isNotEmpty &&
                                          device.imei2.toString() ==
                                              customer.imei2.toString();

                                      return imei1Match || imei2Match;
                                    });
                              } catch (e) {
                                matchingDevice = null;
                              }

                              final bool deviceFound = matchingDevice != null;
                              final String statusDevice = deviceFound
                                  ? matchingDevice.status
                                  : 'Disconnected';
                              final bool cameraDisabled = false;

                              // Debug print to verify matching device
                              if (deviceFound) {
                                debugPrint(
                                  "Customer ${customer.customerName} matched device: ${matchingDevice.customerName}",
                                );
                              } else {
                                debugPrint(
                                  "Customer ${customer.customerName} has no matching device",
                                );
                              }

                              return Stack(
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          colorScheme
                                              .surface, // Alice blue background (F0F8FF)
                                          colorScheme
                                              .tertiaryContainer, // Lighter sky blue (A8C6FF)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.radiusLarge,
                                      ),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).hintColor,
                                          blurRadius: 2,
                                          offset: const Offset(0, 0),
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: customer.profileImage.isNotEmpty
                                              ? Image.network(
                                                  '${AppConstants.imageUrl}${customer.profileImage}',
                                                  width: 75,
                                                  height: 110,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: 75,
                                                      height: 110,
                                                      color: Colors.grey[300],
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 40,
                                                        color: Colors.grey[600],
                                                      ),
                                                    );
                                                  },
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Container(
                                                      width: 75,
                                                      height: 110,
                                                      color: Colors.grey[200],
                                                      child: Center(
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded /
                                                                  loadingProgress.expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  width: 75,
                                                  height: 110,
                                                  color: Colors.grey[300],
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 40,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Row(
                                                children: <Widget>[
                                                  Text('CUST ID :', style: robotoRegular(context).copyWith(fontSize: 10)),
                                                  const SizedBox(width: 4,),
                                                  Text((customer.customerCode.isNotEmpty ? customer.customerCode : customer.id.toString()).toUpperCase(), style: robotoRegular(context).copyWith(fontSize: 10)),
                                                ],
                                              ),
                                              infoRow(
                                                Icons.person,
                                                customer.customerName,
                                              ),
                                              infoRow(
                                                Icons.phone,
                                                customer.customerMobileNo,
                                              ),
                                              infoRow(
                                                Icons.qr_code,
                                                customer.imei1,
                                              ),
                                              if (customer.imei2 != null &&
                                                  customer.imei2!.isNotEmpty)
                                                infoRow(
                                                  Icons.qr_code,
                                                  customer.imei2!,
                                                ),
                                              infoRow(
                                                Icons.calendar_today,
                                                customer.createdAt
                                                    .toString()
                                                    .substring(0, 10),
                                              ),
                                              const SizedBox(height: 2),
                                              // Status based on is_active: 0=Inactive, 1=Active, 2=Uninstall
                                              Row(
                                                children: [
                                                  Text(
                                                    'Status: ',
                                                    style: robotoBold(context).copyWith(fontSize: 10),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: customer.isActive == 0
                                                          ? Colors.orange.withValues(alpha: 0.2)
                                                          : customer.isActive == 1
                                                              ? Colors.green.withValues(alpha: 0.2)
                                                              : Colors.red.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      customer.isActive == 0
                                                          ? 'Inactive'
                                                          : customer.isActive == 1
                                                              ? 'Active'
                                                              : 'Uninstall',
                                                      style: robotoBold(context).copyWith(
                                                        fontSize: 10,
                                                        color: customer.isActive == 0
                                                            ? Colors.orange[800]
                                                            : customer.isActive == 1
                                                                ? Colors.green[800]
                                                                : Colors.red[800],
                                                      ),
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
                                  // Edit button at top right
                                  Positioned(
                                    top: 3,
                                    right: 3,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final result = await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => AddCustomerScreen(
                                              customerId: customer.id,
                                            ),
                                          ),
                                        );
                                        // Refresh list if customer was updated
                                        if (result == true) {
                                          _refreshCustomers();
                                        }
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (deviceFound && customer.isActive != 0 )
                                    Positioned(
                                      bottom: 3,
                                      right: 3,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CustomerManagementScreen(
                                                    customerId: customer.id,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 80,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .secondaryHeaderColor
                                                .withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                            separatorBuilder: (context, index) =>
                                SizedBox(height: Dimensions.paddingSizeSmall),
                            itemCount: customers.length,
                          ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Row(
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 3),
          Flexible(child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
        ],
      ),
    );
  }
}

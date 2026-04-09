import 'dart:ui';

import 'package:deviceguardianadmin/models/purchase_history_model.dart';
import 'package:deviceguardianadmin/providers/purchase_history_provider.dart';
import 'package:deviceguardianadmin/screens/login_screen.dart';
import 'package:deviceguardianadmin/widgets/custom_dropdown_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/snack_bar_widget.dart';

import '../util/app_constants.dart';
import '../util/dimensions.dart';
import '../util/styles.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  bool isInit = true;
  String _selectedFilter = 'All';
  String _selectedFilterValue = 'All';
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  final TextEditingController _searchController = TextEditingController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  // Filter options
  final Map<String, String> _filterOptionsMap = {
    'All': 'All',
    'Pending': 'Pending',
    'Approved': 'Approved',
    'Rejected': 'Rejected',
  };

  List<String> get _filterOptions => _filterOptionsMap.keys.toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final prefs = await SharedPreferences.getInstance();
        final authToken = prefs.getString('auth_token') ?? '';

        if (authToken.isEmpty) {
          if (mounted) {
            showCustomSnackBar(context, "Please login to view purchase history", isError: true);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        }

        if (mounted) {
          final provider = Provider.of<PurchaseHistoryProvider>(
            context,
            listen: false,
          );
          await provider.fetchPurchaseHistory(
            context,
            isRefresh: true,
            filter: _selectedFilterValue,
            search: _searchQuery,
          );

          if (provider.purchaseHistoryModel?.message == 'Unauthorized') {
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

  Future<void> _onRefresh() async {
    final provider = Provider.of<PurchaseHistoryProvider>(
      context,
      listen: false,
    );
    final result = await provider.fetchPurchaseHistory(
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

    if (provider.purchaseHistoryModel?.message == 'Unauthorized' && mounted) {
      showCustomSnackBar(context, "Session expired. Please login again", isError: true);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _onLoading() async {
    final provider = Provider.of<PurchaseHistoryProvider>(
      context,
      listen: false,
    );
    final result = await provider.fetchMorePurchaseHistory(context);

    if (result) {
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  Future<void> _refreshHistory() async {
    final provider = Provider.of<PurchaseHistoryProvider>(
      context,
      listen: false,
    );
    await provider.fetchPurchaseHistory(
      context,
      isRefresh: true,
      filter: _selectedFilterValue,
      search: _searchQuery,
    );

    if (provider.purchaseHistoryModel?.message == 'Unauthorized' && mounted) {
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
    final provider = Provider.of<PurchaseHistoryProvider>(context);
    final historyList = provider.purchaseHistoryList;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
            children: <Widget>[
              // AppBar Card
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
                          "Purchase History",
                          style: robotoBold(context).copyWith(
                            fontSize: Dimensions.fontSizeOverLarge(context),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: provider.isLoading ? null : _refreshHistory,
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
                      height: 42,
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
                                        _selectedFilterValue = _filterOptionsMap[value] ?? 'All';
                                      });
                                      _refreshHistory();
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
                                          hintText: 'Search by transaction ID...',
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
                                                    _refreshHistory();
                                                  },
                                                )
                                              : null,
                                        ),
                                        onSubmitted: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                          _refreshHistory();
                                        },
                                        onChanged: (value) {
                                          setState(() {});
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
                                      _refreshHistory();
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
                                      if (hadSearchQuery) {
                                        _refreshHistory();
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
              const SizedBox(height: Dimensions.paddingSizeSmall),
              // Title Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                child: _buildReportTitle(context),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              // List
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
                              body = const Text("No more records");
                            }
                            return SizedBox(
                              height: 55.0,
                              child: Center(child: body),
                            );
                          },
                        ),
                        child: historyList.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 72,
                                        color: colorScheme.primary.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No purchase history found',
                                        style: robotoBold(context).copyWith(
                                          fontSize: Dimensions.fontSizeLarge(context),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Pull to refresh or make a purchase',
                                        style: robotoRegular(context),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: _refreshHistory,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                      )
                                    ],
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeSmall,
                                ),
                                itemBuilder: (context, index) {
                                  final item = historyList[index];
                                  return PurchaseHistoryCardView(
                                    index: index,
                                    item: item,
                                  );
                                },
                                separatorBuilder: (context, index) => const SizedBox(
                                  height: Dimensions.paddingSizeExtraSmall,
                                ),
                                itemCount: historyList.length,
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTitle(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
                  'Date',
                  style: robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeDefault(context),
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Qty',
                  style: robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeDefault(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  style: robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeDefault(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Status',
                    style: robotoBold(context).copyWith(
                      fontSize: Dimensions.fontSizeDefault(context),
                    ),
                    textAlign: TextAlign.end,
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

class PurchaseHistoryCardView extends StatelessWidget {
  final int index;
  final PurchaseHistoryItem item;

  const PurchaseHistoryCardView({
    super.key,
    required this.index,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get status color
    Color statusColor;
    Color statusBgColor;
    switch (item.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green.shade700;
        statusBgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'rejected':
        statusColor = Colors.red.shade700;
        statusBgColor = Colors.red.withValues(alpha: 0.1);
        break;
      case 'pending':
      default:
        statusColor = Colors.orange.shade700;
        statusBgColor = Colors.orange.withValues(alpha: 0.1);
        break;
    }

    return InkWell(
      onTap: () {
        _showDetailDialog(context, item);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.formattedShortDate,
                    style: robotoBold(context).copyWith(
                      fontSize: Dimensions.fontSizeDefault(context),
                      color: colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.requestDate.year.toString(),
                    style: robotoRegular(context).copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall(context),
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                item.quantity.toString(),
                style: robotoBold(context).copyWith(
                  fontSize: Dimensions.fontSizeDefault(context),
                  color: colorScheme.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Rs. ${item.amount.toStringAsFixed(0)}',
                style: robotoBold(context).copyWith(
                  fontSize: Dimensions.fontSizeDefault(context),
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Text(
                    item.status,
                    style: robotoBold(context).copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall(context),
                      color: statusColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, PurchaseHistoryItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get status color
    Color statusColor;
    Color statusBgColor;
    switch (item.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green.shade700;
        statusBgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'rejected':
        statusColor = Colors.red.shade700;
        statusBgColor = Colors.red.withValues(alpha: 0.1);
        break;
      case 'pending':
      default:
        statusColor = Colors.orange.shade700;
        statusBgColor = Colors.orange.withValues(alpha: 0.1);
        break;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "Purchase Details",
                        style: robotoBold(context).copyWith(
                          fontSize: Dimensions.fontSizeExtraLarge(context),
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.hintColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeSmall,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.status.toLowerCase() == 'approved'
                            ? Icons.check_circle
                            : item.status.toLowerCase() == 'rejected'
                                ? Icons.cancel
                                : Icons.hourglass_empty,
                        size: 18,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.status,
                        style: robotoBold(context).copyWith(
                          fontSize: Dimensions.fontSizeDefault(context),
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                // Details Container
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(context, "Date", item.formattedDate),
                      const Divider(height: 16),
                      _buildDetailRow(context, "Quantity", item.quantity.toString()),
                      const Divider(height: 16),
                      _buildDetailRow(context, "Price per Key", "Rs. ${item.pricePerKey.toStringAsFixed(0)}"),
                      const Divider(height: 16),
                      _buildDetailRow(context, "Total Amount", "Rs. ${item.amount.toStringAsFixed(0)}", isHighlighted: true),
                      if (item.transactionId.isNotEmpty) ...[
                        const Divider(height: 16),
                        _buildDetailRow(context, "Transaction ID", item.transactionId),
                      ],
                    ],
                  ),
                ),
                // Payment Proof Image
                if ((item.paymentProofUrl != null && item.paymentProofUrl!.isNotEmpty) || 
                    (item.paymentProof != null && item.paymentProof!.isNotEmpty)) ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text(
                    "Payment Proof",
                    style: robotoBold(context).copyWith(
                      fontSize: Dimensions.fontSizeDefault(context),
                      color: colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: Image.network(
                      item.paymentProofUrl != null && item.paymentProofUrl!.isNotEmpty
                          ? item.paymentProofUrl!
                          : '${AppConstants.imageUrl}${item.paymentProof}',
                      width: double.infinity,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 150,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 32, color: theme.hintColor),
                              const SizedBox(height: 4),
                              Text("Failed to load image", style: TextStyle(color: theme.hintColor, fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: Dimensions.paddingSizeDefault),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isHighlighted = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: robotoRegular(context).copyWith(
            fontSize: Dimensions.fontSizeDefault(context),
            color: theme.hintColor,
          ),
        ),
        Text(
          value,
          style: robotoBold(context).copyWith(
            fontSize: Dimensions.fontSizeDefault(context),
            color: isHighlighted ? colorScheme.primary : colorScheme.tertiary,
          ),
        ),
      ],
    );
  }
}





import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/purchase_history_model.dart';
import '../util/app_constants.dart';

class PurchaseHistoryProvider with ChangeNotifier {
  // State variables
  PurchaseHistoryModel? purchaseHistoryModel;
  List<PurchaseHistoryItem> purchaseHistoryList = [];
  bool isLoading = false;
  bool isLoadingMore = false;

  // Pagination variables
  int pageIndex = 1;
  int totalPages = 1;
  bool? showMore;
  bool? showingMore;

  // Filter and search state
  String _currentFilter = 'All';
  String _currentSearch = '';

  String get currentFilter => _currentFilter;
  String get currentSearch => _currentSearch;

  // Computed property for pagination
  bool get hasMorePages => pageIndex <= totalPages;

  // Reset pagination state
  void resetPagination() {
    purchaseHistoryList = [];
    pageIndex = 1;
    totalPages = 1;
    showMore = null;
    showingMore = null;
    isLoadingMore = false;
  }

  // Clear data - called when refreshing
  void clearData() {
    purchaseHistoryModel = null;
    purchaseHistoryList = [];
    pageIndex = 1;
    totalPages = 1;
    showMore = null;
    showingMore = null;
    notifyListeners();
  }

  // Fetch purchase history with pagination support
  Future<bool> fetchPurchaseHistory(
    BuildContext context, {
    bool isRefresh = false,
    String? filter,
    String? search,
  }) async {
    // Update filter and search if provided
    if (filter != null) {
      _currentFilter = filter;
    }
    if (search != null) {
      _currentSearch = search;
    }

    if (isRefresh) {
      pageIndex = 1;
    } else {
      if (pageIndex > totalPages) {
        return false;
      }
    }

    if (isRefresh) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final authToken = prefs.getString('auth_token') ?? '';

      if (authToken.isEmpty) {
        debugPrint("Auth token is empty");
        return false;
      }

      debugPrint("=== Fetch Purchase History Debug ===");
      debugPrint("Retrieved user_id: $userId");
      debugPrint("Auth token present: ${authToken.isNotEmpty}");

      // Build URL with query parameters
      String filterValue = _currentFilter == 'All' ? '' : _currentFilter;
      final url = '${AppConstants.baseUrl}/purchase_request_history?page=$pageIndex&filter=$filterValue&search=$_currentSearch';

      debugPrint("Purchase History API URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        debugPrint("Purchase History API success");
        debugPrint("=== FULL RESPONSE BODY ===");
        debugPrint(response.body);
        debugPrint("=== END RESPONSE BODY ===");

        try {
          final jsonData = json.decode(response.body);
          purchaseHistoryModel = PurchaseHistoryModel.fromJson(jsonData);

          // Update pagination state from API response
          if (isRefresh) {
            purchaseHistoryList = purchaseHistoryModel!.data;
          } else {
            purchaseHistoryList.addAll(purchaseHistoryModel!.data);
          }

          pageIndex++;
          totalPages = purchaseHistoryModel!.meta.lastPage;

          // Update showMore flag
          if (purchaseHistoryModel!.meta.total == purchaseHistoryList.length) {
            showMore = false;
          } else {
            showMore = true;
          }
          showingMore = false;

          debugPrint("=== Pagination State After Fetch ===");
          debugPrint("Items loaded: ${purchaseHistoryList.length}");
          debugPrint("Current page index: $pageIndex");
          debugPrint("Total pages: $totalPages");
          debugPrint("Total items: ${purchaseHistoryModel!.meta.total}");
          debugPrint("Has more pages: $hasMorePages");

          notifyListeners();
          return true;
        } catch (parseError) {
          debugPrint("Error parsing purchase history response: $parseError");
          debugPrint("Full response body: ${response.body}");
          return false;
        }
      } else if (response.statusCode == 401) {
        debugPrint("Purchase History API unauthorized 401: ${response.body}");
        purchaseHistoryModel = PurchaseHistoryModel(
          success: false,
          message: 'Unauthorized',
          data: [],
          meta: PurchaseHistoryMeta(
            currentPage: 1,
            lastPage: 1,
            perPage: 10,
            total: 0,
          ),
        );
        return false;
      } else {
        debugPrint("Purchase History API error ${response.statusCode}: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint('Error fetching purchase history: $e');
      return false;
    } finally {
      isLoading = false;
      showingMore = false;
      notifyListeners();
    }
  }

  // Fetch more items (for pagination - load next page)
  Future<bool> fetchMorePurchaseHistory(BuildContext context) async {
    if (!hasMorePages || isLoadingMore) {
      return false;
    }

    isLoadingMore = true;
    showingMore = true;
    notifyListeners();

    final result = await fetchPurchaseHistory(
      context,
      isRefresh: false,
      filter: _currentFilter,
      search: _currentSearch,
    );

    isLoadingMore = false;
    showingMore = false;
    notifyListeners();

    return result;
  }

  // Update filter
  void updateFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // Update search query
  void updateSearch(String search) {
    _currentSearch = search;
    notifyListeners();
  }
}



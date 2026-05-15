import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/purchase_history_model.dart';
import '../util/app_constants.dart';
import '../util/session_manager.dart';

class PurchaseHistoryProvider with ChangeNotifier {
  PurchaseHistoryModel? purchaseHistoryModel;
  List<PurchaseHistoryItem> purchaseHistoryList = [];
  bool isLoading = false;
  bool isLoadingMore = false;

  int pageIndex = 1;
  int totalPages = 1;
  bool? showMore;
  bool? showingMore;

  static const int _perPage = 10;

  String _currentFilter = 'All';
  String _currentSearch = '';

  String get currentFilter => _currentFilter;
  String get currentSearch => _currentSearch;
  bool get hasMorePages => pageIndex <= totalPages;

  void resetPagination() {
    purchaseHistoryList = [];
    pageIndex = 1;
    totalPages = 1;
    showMore = null;
    showingMore = null;
    isLoadingMore = false;
  }

  void clearData() {
    purchaseHistoryModel = null;
    purchaseHistoryList = [];
    pageIndex = 1;
    totalPages = 1;
    showMore = null;
    showingMore = null;
    notifyListeners();
  }

  Uri _buildHistoryUrl() {
    final filterValue = _currentFilter == 'All' ? '' : _currentFilter;
    final queryParams = <String, String>{
      'page': pageIndex.toString(),
      'per_page': _perPage.toString(),
      if (filterValue.isNotEmpty) 'filter': filterValue,
      if (_currentSearch.isNotEmpty) 'search': _currentSearch,
    };
    return Uri.parse(
      '${AppConstants.baseUrl}/mobile/purchase-requests/history',
    ).replace(queryParameters: queryParams);
  }

  void _applyPaginationResponse(PurchaseHistoryModel model, {required bool isRefresh}) {
    purchaseHistoryModel = model;

    if (isRefresh) {
      purchaseHistoryList = model.data;
    } else {
      purchaseHistoryList.addAll(model.data);
    }

    pageIndex++;
    totalPages = model.meta.lastPage;

    showMore = model.meta.total > purchaseHistoryList.length;
    showingMore = false;
  }

  Future<bool> fetchPurchaseHistory(
    BuildContext context, {
    bool isRefresh = false,
    String? filter,
    String? search,
  }) async {
    if (filter != null) {
      _currentFilter = filter;
    }
    if (search != null) {
      _currentSearch = search;
    }

    if (isRefresh) {
      pageIndex = 1;
      totalPages = 1;
    } else if (pageIndex > totalPages) {
      return false;
    }

    if (isRefresh) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      if (authToken.isEmpty) {
        debugPrint("Auth token is empty");
        return false;
      }

      final url = _buildHistoryUrl();
      debugPrint("Purchase History API URL: $url");

      final response = await http.get(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        debugPrint("Purchase History API success");

        try {
          final jsonData = json.decode(response.body);
          final model = PurchaseHistoryModel.fromJson(jsonData);
          _applyPaginationResponse(model, isRefresh: isRefresh);

          debugPrint("=== Pagination State After Fetch ===");
          debugPrint("Items loaded: ${purchaseHistoryList.length}");
          debugPrint("Next page index: $pageIndex");
          debugPrint("Total pages: $totalPages");
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
        await SessionManager.handleSessionExpiry(response.statusCode);
        purchaseHistoryModel = PurchaseHistoryModel(
          success: false,
          message: 'Unauthorized',
          data: [],
          meta: PurchaseHistoryMeta(
            currentPage: 1,
            lastPage: 1,
            perPage: _perPage,
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

  Future<bool> fetchMorePurchaseHistory(BuildContext context) async {
    debugPrint("=== fetchMorePurchaseHistory called ===");
    debugPrint(
      "isLoadingMore: $isLoadingMore, pageIndex: $pageIndex, totalPages: $totalPages",
    );

    if (isLoadingMore) {
      debugPrint("Skipping fetchMorePurchaseHistory - already loading");
      return false;
    }

    if (pageIndex > totalPages) {
      debugPrint(
        "Skipping fetchMorePurchaseHistory - no more pages (pageIndex $pageIndex > totalPages $totalPages)",
      );
      return false;
    }

    isLoadingMore = true;
    showingMore = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      if (authToken.isEmpty) {
        return false;
      }

      final url = _buildHistoryUrl();
      debugPrint("Fetching more purchase history - page $pageIndex");
      debugPrint("URL: $url");

      final response = await http.get(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          final model = PurchaseHistoryModel.fromJson(jsonData);
          _applyPaginationResponse(model, isRefresh: false);

          debugPrint("=== After Load More ===");
          debugPrint("New items: ${model.data.length}");
          debugPrint("Total loaded: ${purchaseHistoryList.length}");
          debugPrint("Next page index: $pageIndex");
          debugPrint("Has more pages: ${pageIndex <= totalPages}");

          notifyListeners();
          return model.data.isNotEmpty;
        } catch (parseError) {
          debugPrint("Error parsing more purchase history response: $parseError");
          return false;
        }
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        purchaseHistoryModel = PurchaseHistoryModel(
          success: false,
          message: 'Unauthorized',
          data: purchaseHistoryList,
          meta: PurchaseHistoryMeta(
            currentPage: 1,
            lastPage: 1,
            perPage: _perPage,
            total: purchaseHistoryList.length,
          ),
        );
        return false;
      } else {
        debugPrint("Load more failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint('Error fetching more purchase history: $e');
      return false;
    } finally {
      isLoadingMore = false;
      showingMore = false;
      notifyListeners();
    }
  }

  void updateFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void updateSearch(String search) {
    _currentSearch = search;
    notifyListeners();
  }
}

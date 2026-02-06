import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/unified_filter_model.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';

class ListingController extends BaseController {
  ListingController({required PropertiesRepository repository})
    : _repository = repository;

  final PropertiesRepository _repository;
  final LocationService _locationService = Get.find<LocationService>();

  final ScrollController scrollController = ScrollController();

  final RxList<Property> listings = <Property>[].obs;
  final RxBool isRefreshing = false.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt pageSize = 20.obs;
  final RxInt totalCount = 0.obs;

  double? _queryLat;
  double? _queryLng;
  double _radiusKm = 100.0;
  Map<String, dynamic>? _filtersFromArgs;
  UnifiedFilterModel _activeFilters = UnifiedFilterModel.empty;
  FilterController? _filterController;
  Worker? _filterWorker;

  @override
  void onInit() {
    super.onInit();
    _initQueryFromArgsOrService();
    _attachFilterController();
    fetch();
  }

  @override
  void onClose() {
    scrollController.dispose();
    // Worker is automatically disposed by BaseController via trackWorker
    super.onClose();
  }

  void _initQueryFromArgsOrService() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      _queryLat =
          (args['lat'] as num?)?.toDouble() ?? _locationService.latitude;
      _queryLng =
          (args['lng'] as num?)?.toDouble() ?? _locationService.longitude;
      _radiusKm = (args['radius_km'] as num?)?.toDouble() ?? _radiusKm;
      final rawFilters = args['filters'];
      if (rawFilters is Map<String, dynamic>) {
        _filtersFromArgs = Map<String, dynamic>.from(rawFilters)
          ..removeWhere((_, value) => value == null)
          ..remove('page')
          ..remove('limit')
          ..remove('lat')
          ..remove('lng');
      }
      final initialScopeFilters = args['scopeFilters'] as UnifiedFilterModel?;
      if (initialScopeFilters != null) {
        _activeFilters = initialScopeFilters;
      }
    } else {
      _queryLat = _locationService.latitude;
      _queryLng = _locationService.longitude;
    }
  }

  void _attachFilterController() {
    if (!Get.isRegistered<FilterController>()) return;
    _filterController = Get.find<FilterController>();
    // Use locate scope for detail search, fall back to explore if empty.
    final locateFilters = _filterController!.filterFor(FilterScope.locate);
    if (locateFilters.isNotEmpty) {
      _activeFilters = locateFilters;
    } else {
      _activeFilters = _filterController!.filterFor(FilterScope.explore);
    }
    _filterWorker = trackWorker(debounce<UnifiedFilterModel>(
      _filterController!.rxFor(FilterScope.locate),
      (filters) async {
        if (_activeFilters == filters) return;
        _activeFilters = filters;
        await fetch(pageOverride: 1, jumpToTop: true);
      },
      time: const Duration(milliseconds: 150),
    ));
  }

  Map<String, dynamic>? _buildFilters() {
    final combined = <String, dynamic>{};
    if (_filtersFromArgs != null) {
      combined.addAll(_filtersFromArgs!);
    }
    final scoped = _activeFilters.toQueryParameters();
    if (scoped.isNotEmpty) combined.addAll(scoped);
    return combined.isEmpty ? null : combined;
  }

  Future<void> fetch({
    int? pageOverride,
    bool showLoader = true,
    bool jumpToTop = false,
  }) async {
    final targetPage = pageOverride ?? currentPage.value;
    if (targetPage < 1) {
      await fetch(
        pageOverride: 1,
        showLoader: showLoader,
        jumpToTop: jumpToTop,
      );
      return;
    }
    if (showLoader) {
      isLoading.value = true;
    } else {
      isRefreshing.value = true;
    }
    errorMessage.value = '';
    try {
      final response = await _repository.explore(
        lat: _queryLat,
        lng: _queryLng,
        page: targetPage,
        limit: pageSize.value,
        radiusKm: _radiusKm,
        filters: _buildFilters(),
      );
      currentPage.value = response.currentPage;
      totalPages.value = response.totalPages;
      totalCount.value = response.totalCount;
      pageSize.value = response.pageSize;
      listings.assignAll(response.properties);
    } catch (e) {
      errorMessage.value = 'Failed to load properties';
      listings.clear();
    } finally {
      if (showLoader) {
        isLoading.value = false;
      } else {
        isRefreshing.value = false;
      }
      if (jumpToTop) {
        _scrollToTop();
      }
    }
  }

  @override
  Future<void> refresh() async {
    await fetch(showLoader: false);
  }

  Future<void> goToPage(int page) async {
    if (page == currentPage.value) return;
    if (page < 1 || page > totalPages.value) return;
    await fetch(pageOverride: page, jumpToTop: true);
  }

  Future<void> nextPage() async {
    if (currentPage.value >= totalPages.value) return;
    await goToPage(currentPage.value + 1);
  }

  Future<void> previousPage() async {
    if (currentPage.value <= 1) return;
    await goToPage(currentPage.value - 1);
  }

  Future<void> changePageSize(int newSize) async {
    if (newSize == pageSize.value) return;
    pageSize.value = newSize;
    await fetch(pageOverride: 1, jumpToTop: true);
  }

  Future<void> setQueryLocation({
    required double lat,
    required double lng,
    double? radiusKm,
    Map<String, dynamic>? filters,
  }) async {
    _queryLat = lat;
    _queryLng = lng;
    if (radiusKm != null) _radiusKm = radiusKm;
    if (filters != null) {
      _filtersFromArgs = Map<String, dynamic>.from(filters)
        ..removeWhere((_, value) => value == null);
    }
    await fetch(pageOverride: 1, jumpToTop: true);
  }

  void _scrollToTop() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }
}

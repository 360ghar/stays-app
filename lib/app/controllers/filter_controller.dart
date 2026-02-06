import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/unified_filter_model.dart';
import '../ui/widgets/filters/property_filter_sheet.dart';

enum FilterScope { explore, wishlist, booking, locate }

class FilterController extends GetxController {
  FilterController();

  final Map<FilterScope, Rx<UnifiedFilterModel>> _filters = {
    for (final scope in FilterScope.values) scope: UnifiedFilterModel.empty.obs,
  };

  UnifiedFilterModel filterFor(FilterScope scope) => _filters[scope]!.value;

  Rx<UnifiedFilterModel> rxFor(FilterScope scope) => _filters[scope]!;

  bool hasActiveFilters(FilterScope scope) => filterFor(scope).isNotEmpty;

  List<String> tagsFor(FilterScope scope) => filterFor(scope).activeTags();

  void setFilters(FilterScope scope, UnifiedFilterModel filters) {
    if (_filters[scope]!.value == filters) return;
    _filters[scope]!.value = filters;
  }

  void mergeFilters(FilterScope scope, UnifiedFilterModel filters) {
    final merged = filterFor(scope).merge(filters);
    setFilters(scope, merged);
  }

  void clear(FilterScope scope) {
    if (_filters[scope]!.value.isEmpty) return;
    _filters[scope]!.value = UnifiedFilterModel.empty;
  }

  Future<void> openFilterSheet(BuildContext context, FilterScope scope) async {
    final result = await showPropertyFilterSheet(
      context: context,
      initial: filterFor(scope),
    );
    if (result != null) {
      setFilters(scope, result);
    }
  }
}

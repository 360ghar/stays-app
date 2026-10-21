import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/app/data/models/unified_filter_model.dart';
import 'package:stays_app/app/ui/widgets/filters/property_filter_sheet.dart';

enum FilterScope { explore, wishlist, booking, locate }

/// Per-scope filter state. Replaces the legacy GetX `FilterController`.
final filtersProvider =
    NotifierProvider<FiltersNotifier, Map<FilterScope, UnifiedFilterModel>>(
      FiltersNotifier.new,
    );

class FiltersNotifier extends Notifier<Map<FilterScope, UnifiedFilterModel>> {
  @override
  Map<FilterScope, UnifiedFilterModel> build() => {
    for (final scope in FilterScope.values) scope: UnifiedFilterModel.empty,
  };

  UnifiedFilterModel filterFor(FilterScope scope) => state[scope]!;

  bool hasActiveFilters(FilterScope scope) => filterFor(scope).isNotEmpty;

  List<String> tagsFor(FilterScope scope) => filterFor(scope).activeTags();

  void setFilters(FilterScope scope, UnifiedFilterModel filters) {
    if (state[scope] == filters) return;
    state = {...state, scope: filters};
  }

  void mergeFilters(FilterScope scope, UnifiedFilterModel filters) {
    setFilters(scope, filterFor(scope).merge(filters));
  }

  void clear(FilterScope scope) {
    if (state[scope]!.isEmpty) return;
    state = {...state, scope: UnifiedFilterModel.empty};
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

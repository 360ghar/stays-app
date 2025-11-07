import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/filter_controller.dart';
import '../../../data/services/location_service.dart';
import '../../../routes/app_routes.dart';
import '../../theme/theme_extensions.dart';
import 'filter_button.dart';
import 'search_bar_widget.dart';

class LocationFilterAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const LocationFilterAppBar({
    super.key,
    required this.scope,
    this.showBackButton = false,
    this.onLocationTap,
    this.onFilterPressed,
    this.trailingActions,
  });

  final FilterScope scope;
  final bool showBackButton;
  final VoidCallback? onLocationTap;
  final VoidCallback? onFilterPressed;
  final List<Widget>? trailingActions;

  FilterController? get _filterController =>
      Get.isRegistered<FilterController>() ? Get.find<FilterController>() : null;

  LocationService? get _locationService =>
      Get.isRegistered<LocationService>() ? Get.find<LocationService>() : null;

  @override
  Size get preferredSize => const Size.fromHeight(84);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: showBackButton,
      titleSpacing: showBackButton ? 0 : 16,
      toolbarHeight: preferredSize.height,
      actions: trailingActions,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildSearchField(context)),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            width: 52,
            child: _buildFilterButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final tapHandler = onLocationTap ?? _openLocationSearch;
    final colors = context.colors;
    final locationService = _locationService;
    if (locationService == null) {
      return SearchBarWidget(
        placeholder: 'Search nearby stays',
        onTap: tapHandler,
        fontSize: 14,
        iconSize: 20,
        margin: EdgeInsets.zero,
        height: 52,
        borderRadius: BorderRadius.circular(18),
        shadowColor: colors.shadow.withValues(alpha: 0.08),
        backgroundColor: colors.surface,
        trailing: _buildUseLocationButton(context, isEnabled: false),
      );
    }
    return Obx(() {
      final locationName = locationService.locationNameRx.value;
      final hint = locationName.isEmpty
          ? 'Search nearby stays'
          : 'Search near $locationName';
      return SearchBarWidget(
        placeholder: hint,
        onTap: tapHandler,
        fontSize: 14,
        iconSize: 20,
        margin: EdgeInsets.zero,
        height: 52,
        borderRadius: BorderRadius.circular(18),
        shadowColor: colors.shadow.withValues(alpha: 0.08),
        backgroundColor: colors.surface,
        trailing: _buildUseLocationButton(context, isEnabled: true),
      );
    });
  }

  Widget _buildFilterButton(BuildContext context) {
    final controller = _filterController;
    if (controller == null) {
      return FilterButton(
        isActive: false,
        onPressed: () => _showFilterUnavailable(context),
      );
    }
    final filtersRx = controller.rxFor(scope);
    return Obx(
      () => FilterButton(
        isActive: filtersRx.value.isNotEmpty,
        onPressed: onFilterPressed ??
            () => controller.openFilterSheet(context, scope),
      ),
    );
  }

  Widget _buildUseLocationButton(
    BuildContext context, {
    required bool isEnabled,
  }) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final locationService = _locationService;
    if (!isEnabled || locationService == null) {
      return TextButton.icon(
        onPressed: null,
        icon: Icon(Icons.my_location, size: 16, color: colors.outline),
        label: Text(
          'Use my location',
          style: textStyles.labelSmall?.copyWith(color: colors.outline),
        ),
      );
    }
    return TextButton.icon(
      onPressed: () => _useMyLocation(),
      icon: Icon(Icons.my_location,
          size: 16, color: colors.primary),
      label: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          'Use my location',
          style: textStyles.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.primary,
          ),
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Future<void> _useMyLocation() async {
    final locationService = _locationService;
    if (locationService == null) return;
    try {
      await locationService.updateLocation(ensurePrecise: true);
      Get.snackbar(
        'Location updated',
        'Using your current location for nearby stays',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      Get.snackbar(
        'Location unavailable',
        'Unable to fetch current location. Check permissions.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _openLocationSearch() {
    if (Get.currentRoute == Routes.search) return;
    Get.toNamed(Routes.search);
  }

  void _showFilterUnavailable(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.error,
        content: const Text('Filters are unavailable on this screen'),
      ),
    );
  }
}

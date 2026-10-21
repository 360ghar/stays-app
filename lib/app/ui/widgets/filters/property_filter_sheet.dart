import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/core/l10n/strings.dart';

import '../../../data/models/unified_filter_model.dart';
import '../../../data/models/wire_enums.dart';
import '../../theme/app_animations.dart';

Future<UnifiedFilterModel?> showPropertyFilterSheet({
  required BuildContext context,
  required UnifiedFilterModel initial,
}) async {
  final result = await Navigator.of(context).push<_FilterSheetRouteResult>(
    _FilterSheetRoute(
      initial: initial,
      curve: AppAnimations.sheetCurve,
      duration: AppAnimations.sheetDuration,
    ),
  );
  return result?.filters;
}

class _FilterSheetRouteResult {
  const _FilterSheetRouteResult({required this.filters});
  final UnifiedFilterModel filters;
}

class _FilterSheetRoute extends PopupRoute<_FilterSheetRouteResult> {
  _FilterSheetRoute({
    required this.initial,
    required this.curve,
    required this.duration,
  });

  final UnifiedFilterModel initial;
  final Curve curve;
  final Duration duration;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.5);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss filter sheet';

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _PropertyFilterSheet(
      initial: initial,
      animation: animation,
      curve: curve,
    );
  }
}

class _PropertyFilterSheet extends ConsumerStatefulWidget {
  const _PropertyFilterSheet({
    required this.initial,
    required this.animation,
    required this.curve,
  });

  final UnifiedFilterModel initial;
  final Animation<double> animation;
  final Curve curve;

  @override
  ConsumerState<_PropertyFilterSheet> createState() =>
      _PropertyFilterSheetState();
}

class _PropertyFilterSheetState extends ConsumerState<_PropertyFilterSheet> {
  static const double _priceFloor = 0;
  static const double _priceCeil = 200000;
  // The property types the backend knows, from the generated wire enum.
  static const List<PropertyType> _propertyTypeOptions = PropertyType.values;

  late ThemeData _theme;
  late ColorScheme _colorScheme;
  late bool _isDarkTheme;
  late Color _dividerColor;

  late RangeValues _priceRange;
  late Set<PropertyType> _selectedTypes;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  bool _isUpdatingPriceFields = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _priceRange = _resolveRange(initial.minPrice, initial.maxPrice);
    _selectedTypes = initial.propertyTypes.toSet();
    _minPriceController = TextEditingController(
      text: _initialPriceText(initial.minPrice),
    )..addListener(_handleMinPriceInput);
    _maxPriceController = TextEditingController(
      text: _initialPriceText(initial.maxPrice),
    )..addListener(_handleMaxPriceInput);
    _syncPriceControllers(_priceRange);
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  RangeValues _resolveRange(double? min, double? max) {
    final start = (min ?? _priceFloor).clamp(_priceFloor, _priceCeil);
    final end = (max ?? _priceCeil).clamp(_priceFloor, _priceCeil);
    if (end < start) return RangeValues(start, start);
    return RangeValues(start, end);
  }

  String _initialPriceText(double? value) {
    if (value == null) return '';
    final clamped = value.clamp(_priceFloor, _priceCeil);
    if (clamped <= _priceFloor || clamped >= _priceCeil) return '';
    return clamped.round().toString();
  }

  double? _parsePrice(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _handleMinPriceInput() {
    if (_isUpdatingPriceFields) return;
    final value = _parsePrice(_minPriceController.text);
    final double start = value?.clamp(_priceFloor, _priceCeil) ?? _priceFloor;
    double end = _priceRange.end;
    if (start > end) {
      end = start;
    }
    setState(() {
      _priceRange = RangeValues(start, end);
    });
    _syncPriceControllers(_priceRange);
  }

  void _handleMaxPriceInput() {
    if (_isUpdatingPriceFields) return;
    final value = _parsePrice(_maxPriceController.text);
    final double end = value?.clamp(_priceFloor, _priceCeil) ?? _priceCeil;
    double start = _priceRange.start;
    if (end < start) {
      start = end;
    }
    setState(() {
      _priceRange = RangeValues(start, end);
    });
    _syncPriceControllers(_priceRange);
  }

  void _syncPriceControllers(RangeValues values) {
    _isUpdatingPriceFields = true;
    _updateControllerText(
      _minPriceController,
      values.start <= _priceFloor ? '' : values.start.round().toString(),
    );
    _updateControllerText(
      _maxPriceController,
      values.end >= _priceCeil ? '' : values.end.round().toString(),
    );
    _isUpdatingPriceFields = false;
  }

  void _updateControllerText(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    _colorScheme = _theme.colorScheme;
    _isDarkTheme = _theme.brightness == Brightness.dark;
    _dividerColor = _colorScheme.outlineVariant.withValues(
      alpha: _isDarkTheme ? 0.35 : 0.55,
    );

    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.85;
    final curvedAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: widget.curve,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Container(
                height: height,
                padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
                decoration: BoxDecoration(
                  color: _colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _colorScheme.shadow.withValues(
                        alpha: _isDarkTheme ? 0.6 : 0.12,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Divider(height: 1, thickness: 1, color: _dividerColor),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPriceSection(context),
                              const SizedBox(height: 24),
                              _buildPropertyTypeSection(context),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: _dividerColor),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = _theme.textTheme;
    final handleColor = _colorScheme.outlineVariant.withValues(
      alpha: _isDarkTheme ? 0.6 : 0.3,
    );
    final iconColor = _colorScheme.onSurface.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              tr(ref, 'filters.title'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: iconColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    final labelStyle = _theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    InputDecoration priceDecoration(String label) => InputDecoration(
      labelText: label,
      prefixText: '₹ ',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(ref, 'filters.price_per_night'), style: labelStyle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: priceDecoration(tr(ref, 'filters.min')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: priceDecoration(tr(ref, 'filters.max')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: _priceRange,
          max: _priceCeil,
          divisions: 40,
          labels: RangeLabels(
            _formatAmount(_priceRange.start),
            _formatAmount(_priceRange.end),
          ),
          activeColor: _colorScheme.primary,
          inactiveColor: _colorScheme.primary.withValues(alpha: 0.15),
          onChanged: (values) {
            setState(() => _priceRange = values);
            _syncPriceControllers(values);
          },
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    if (value <= _priceFloor) return 'Any';
    if (value >= _priceCeil) return '200k+';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  Widget _buildPropertyTypeSection(BuildContext context) {
    final labelStyle = _theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Property type', style: labelStyle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _propertyTypeOptions.map((option) {
            final selected = _selectedTypes.contains(option);
            return FilterChip(
              label: Text(_formatPropertyType(option.wire)),
              selected: selected,
              selectedColor: _colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: _colorScheme.onPrimaryContainer,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedTypes.add(option);
                  } else {
                    _selectedTypes.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatPropertyType(String option) {
    return option
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: _colorScheme.primary,
                side: BorderSide(
                  color: _colorScheme.primary.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _apply(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorScheme.primary,
                foregroundColor: _colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _priceRange = const RangeValues(_priceFloor, _priceCeil);
      _selectedTypes.clear();
    });
    _syncPriceControllers(_priceRange);
  }

  void _apply(BuildContext context) {
    final min = _parsePrice(_minPriceController.text);
    final max = _parsePrice(_maxPriceController.text);
    final model = UnifiedFilterModel(
      minPrice: min,
      maxPrice: max,
      propertyTypes: _selectedTypes.isEmpty ? null : _selectedTypes.toList(),
    );
    Navigator.of(context).pop(_FilterSheetRouteResult(filters: model));
  }
}

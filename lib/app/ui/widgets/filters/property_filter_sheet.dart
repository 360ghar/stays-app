import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/unified_filter_model.dart';

Future<UnifiedFilterModel?> showPropertyFilterSheet({
  required BuildContext context,
  required UnifiedFilterModel initial,
}) {
  return showModalBottomSheet<UnifiedFilterModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PropertyFilterSheet(initial: initial),
  );
}

class _PropertyFilterSheet extends StatefulWidget {
  const _PropertyFilterSheet({required this.initial});

  final UnifiedFilterModel initial;

  @override
  State<_PropertyFilterSheet> createState() => _PropertyFilterSheetState();
}

class _PropertyFilterSheetState extends State<_PropertyFilterSheet> {
  static const double _priceFloor = 0;
  static const double _priceCeil = 200000;
  static const double _defaultRadius = 10;
  static const List<String> _propertyTypeOptions = <String>[
    'apartment',
    'house',
    'builder_floor',
    'room',
  ];

  late RangeValues _priceRange;
  late Set<String> _selectedTypes;
  late double _minRating;
  late bool _instantBook;
  late bool _selfCheckIn;
  late bool _petsAllowed;
  late bool _smokingAllowed;
  late double _radius;
  late final TextEditingController _cityController;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  bool _isUpdatingPriceFields = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _priceRange = _resolveRange(initial.minPrice, initial.maxPrice);
    _selectedTypes = initial.propertyTypes.toSet();
    _minRating = initial.minRating ?? 0;
    _instantBook = initial.instantBook ?? false;
    _selfCheckIn = initial.selfCheckIn ?? false;
    _petsAllowed = initial.petsAllowed ?? false;
    _smokingAllowed = initial.smokingAllowed ?? false;
    _radius = initial.radiusKm ?? _defaultRadius;
    _cityController = TextEditingController(text: initial.city ?? '');
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
    _cityController.dispose();
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
    double start = value?.clamp(_priceFloor, _priceCeil) ?? _priceFloor;
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
    double end = value?.clamp(_priceFloor, _priceCeil) ?? _priceCeil;
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
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.85;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: height,
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPriceSection(),
                    const SizedBox(height: 24),
                    _buildPropertyTypeSection(),
                    const SizedBox(height: 24),
                    _buildRatingSection(),
                    const SizedBox(height: 24),
                    _buildExperienceSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              'filters.title'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'filters.price_per_night'.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'filters.min'.tr,
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'filters.max'.tr,
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: _priceRange,
          min: _priceFloor,
          max: _priceCeil,
          divisions: 40,
          labels: RangeLabels(
            _formatAmount(_priceRange.start),
            _formatAmount(_priceRange.end),
          ),
          activeColor: Colors.blue[600],
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

  Widget _buildPropertyTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _propertyTypeOptions.map((option) {
            final selected = _selectedTypes.contains(option);
            return FilterChip(
              label: Text(_formatPropertyType(option)),
              selected: selected,
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

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guest rating',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Any'),
            Text('${_minRating.toStringAsFixed(1)} ★'),
            const Text('5 ★'),
          ],
        ),
        Slider(
          value: _minRating,
          min: 0,
          max: 5,
          divisions: 10,
          activeColor: Colors.blue[600],
          onChanged: (value) => setState(() => _minRating = value),
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    final quickFilters = <_QuickFilterOption>[
      _QuickFilterOption('Instant book', _instantBook, (value) {
        setState(() => _instantBook = value);
      }),
      _QuickFilterOption('Self check-in', _selfCheckIn, (value) {
        setState(() => _selfCheckIn = value);
      }),
      _QuickFilterOption('Pets allowed', _petsAllowed, (value) {
        setState(() => _petsAllowed = value);
      }),
      _QuickFilterOption('Smoking allowed', _smokingAllowed, (value) {
        setState(() => _smokingAllowed = value);
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Experience',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickFilters.map((option) {
            return FilterChip(
              label: Text(option.label),
              selected: option.value,
              onSelected: option.onChanged,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cityController,
          decoration: InputDecoration(
            labelText: 'City or locality',
            hintText: 'e.g. Mumbai',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Search radius (km)'),
            Text(_radius.toStringAsFixed(0)),
          ],
        ),
        Slider(
          value: _radius,
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: Colors.blue[600],
          onChanged: (value) => setState(() => _radius = value),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _reset,
              child: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _apply(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 14),
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
      _minRating = 0;
      _instantBook = false;
      _selfCheckIn = false;
      _petsAllowed = false;
      _smokingAllowed = false;
      _radius = _defaultRadius;
      _cityController.clear();
    });
    _syncPriceControllers(_priceRange);
  }

  void _apply(BuildContext context) {
    final min = _parsePrice(_minPriceController.text);
    final max = _parsePrice(_maxPriceController.text);
    final city = _cityController.text.trim();
    final model = UnifiedFilterModel(
      minPrice: min,
      maxPrice: max,
      propertyTypes: _selectedTypes.isEmpty ? null : _selectedTypes.toList(),
      minRating: _minRating > 0 ? _minRating : null,
      instantBook: _instantBook ? true : null,
      selfCheckIn: _selfCheckIn ? true : null,
      petsAllowed: _petsAllowed ? true : null,
      smokingAllowed: _smokingAllowed ? true : null,
      city: city.isEmpty ? null : city,
      radiusKm: (_radius - _defaultRadius).abs() < 0.5 ? null : _radius,
    );
    Navigator.of(context).pop(model);
  }
}

class _QuickFilterOption {
  _QuickFilterOption(this.label, this.value, this.onChanged);

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
}

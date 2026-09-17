import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:stays_app/app/controllers/favorites_controller.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/core/ui/async_state.dart';
import 'package:stays_app/core/ui/tour_hero.dart';
import 'package:stays_app/features/listing/widgets/amenities_list.dart';
import 'package:stays_app/features/listing/widgets/detail_facts.dart';
import 'package:stays_app/features/listing/widgets/host_card.dart';

/// V2 listing detail. Composes [TourHero] + pure sections + one CTA.
///
/// Opens with [initialProperty] when navigated from Explore (no fetch),
/// otherwise loads via [PropertiesRepository.getDetails].
class DetailScreen extends ConsumerWidget {
  const DetailScreen({
    required this.propertyId,
    super.key,
    this.initialProperty,
  });
  final int propertyId;
  final Property? initialProperty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      _detailProvider((id: propertyId, initial: initialProperty)),
    );
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const AsyncState.loading(message: 'Loading stay…'),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: AsyncState.error(
          'Could not load this stay.',
          onRetry: () => ref.invalidate(
            _detailProvider((id: propertyId, initial: initialProperty)),
          ),
        ),
      ),
      data: (property) => _DetailBody(property: property),
    );
  }
}

final _detailProvider = FutureProvider.autoDispose
    .family<Property, ({int id, Property? initial})>((ref, args) async {
      if (args.initial != null) {
        final property = args.initial!;
        if (property.id == args.id) return property;
      }
      if (!Get.isRegistered<PropertiesRepository>()) {
        throw StateError('PropertiesRepository not ready');
      }
      return Get.find<PropertiesRepository>().getDetails(args.id);
    });

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.property});
  final Property property;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  late bool _favorite;

  @override
  void initState() {
    super.initState();
    _favorite = widget.property.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    final id = widget.property.id;
    setState(() => _favorite = !_favorite);
    try {
      if (!Get.isRegistered<FavoritesController>()) return;
      final favorites = Get.find<FavoritesController>();
      if (_favorite) {
        favorites.addFavorite(id);
        if (Get.isRegistered<WishlistRepository>()) {
          await Get.find<WishlistRepository>().add(id);
        }
      } else {
        favorites.removeFavorite(id);
        if (Get.isRegistered<WishlistRepository>()) {
          await Get.find<WishlistRepository>().remove(id);
        }
      }
    } catch (e) {
      AppLogger.error('Detail v2: favorite toggle failed', e);
      if (mounted) setState(() => _favorite = !_favorite);
    }
  }

  Future<void> _openTour() async {
    final property = widget.property;
    await context.push(
      AppPaths.tour('${property.id}'),
      extra: {'url': property.virtualTourUrl, 'title': property.name},
    );
  }

  Future<void> _openGallery() async {
    final images = [
      if (widget.property.coverImage?.isNotEmpty == true)
        widget.property.coverImage!,
      ...?widget.property.images?.map((e) => e.imageUrl),
    ].where((u) => u.isNotEmpty).toList();
    if (images.isEmpty || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) =>
          Dialog.fullscreen(child: _GalleryDialog(images: images)),
    );
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Check out ${widget.property.name} on 360ghar stays',
        subject: widget.property.name,
      ),
    );
  }

  Future<void> _book() async {
    await context.push('/inquiry', extra: widget.property);
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final amenities = (property.amenities ?? [])
        .where((a) => a.trim().isNotEmpty)
        .toList();
    final features = (property.features ?? [])
        .where((f) => f.trim().isNotEmpty)
        .toList();
    return Scaffold(
      backgroundColor: StayTokens.paper,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: StayTokens.paper,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppPaths.explore);
                }
              },
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _favorite ? Icons.favorite : Icons.favorite_border,
                  color: _favorite ? StayTokens.heart : StayTokens.ink,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: _share,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: TourHero(
              imageUrl: property.displayImage,
              hasTour: property.hasVirtualTour,
              onTourTap: _openTour,
              onGalleryTap: _openGallery,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(StayTokens.s16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(property.name, style: StayTokens.titleLarge),
                const SizedBox(height: StayTokens.s4),
                Text(property.fullAddress, style: StayTokens.bodySecondary),
                const SizedBox(height: StayTokens.s12),
                DetailFacts(property: property),
                if (property.description?.isNotEmpty == true) ...[
                  const SizedBox(height: StayTokens.s16),
                  Text(property.description!, style: StayTokens.body),
                ],
                if (amenities.isNotEmpty) ...[
                  const SizedBox(height: StayTokens.s24),
                  AmenitiesList(amenities: amenities),
                ],
                if (features.isNotEmpty) ...[
                  const SizedBox(height: StayTokens.s24),
                  const Text('Highlights', style: StayTokens.title),
                  const SizedBox(height: StayTokens.s12),
                  for (final feature in features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: StayTokens.s8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 18,
                            color: StayTokens.accentDark,
                          ),
                          const SizedBox(width: StayTokens.s8),
                          Expanded(
                            child: Text(feature, style: StayTokens.body),
                          ),
                        ],
                      ),
                    ),
                ],
                if (property.ownerName?.isNotEmpty == true) ...[
                  const SizedBox(height: StayTokens.s24),
                  HostCard(hostName: property.ownerName!),
                ],
                const SizedBox(height: 96),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(StayTokens.s16),
        decoration: const BoxDecoration(
          color: StayTokens.paper,
          border: Border(top: BorderSide(color: StayTokens.line)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property.displayPrice, style: StayTokens.price),
                  const Text('per night', style: StayTokens.label),
                ],
              ),
              const Spacer(),
              FilledButton(
                onPressed: _book,
                child: const Text('Request to book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryDialog extends StatefulWidget {
  const _GalleryDialog({required this.images});
  final List<String> images;

  @override
  State<_GalleryDialog> createState() => _GalleryDialogState();
}

class _GalleryDialogState extends State<_GalleryDialog> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          child: Center(
            child: Image.network(widget.images[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

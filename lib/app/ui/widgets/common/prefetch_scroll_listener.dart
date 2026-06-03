 import 'package:flutter/material.dart';
 import 'package:get/get.dart';
 
 import '../../../data/models/property_model.dart';
 import '../../../data/services/image_prefetch_service.dart';
 
 /// A widget that listens to scroll events and triggers image prefetching
 /// when the user scrolls near the end of visible content.
 class PrefetchScrollListener extends StatefulWidget {
   final Widget child;
   final ScrollController scrollController;
   final List<Property> properties;
   final int visibleItemCount;
   final int prefetchThreshold;
   final int prefetchBatchSize;
 
   const PrefetchScrollListener({
     super.key,
     required this.child,
     required this.scrollController,
     required this.properties,
     this.visibleItemCount = 3,
     this.prefetchThreshold = 2,
     this.prefetchBatchSize = 5,
   });
 
   @override
   State<PrefetchScrollListener> createState() => _PrefetchScrollListenerState();
 }
 
 class _PrefetchScrollListenerState extends State<PrefetchScrollListener> {
   int _lastPrefetchedIndex = -1;
   ImagePrefetchService? _prefetchService;
 
   @override
   void initState() {
     super.initState();
     widget.scrollController.addListener(_onScroll);
     _initPrefetchService();
   }
 
   void _initPrefetchService() {
     if (Get.isRegistered<ImagePrefetchService>()) {
       _prefetchService = Get.find<ImagePrefetchService>();
     }
   }
 
   @override
   void dispose() {
     widget.scrollController.removeListener(_onScroll);
     super.dispose();
   }
 
  void _onScroll() {
    if (_prefetchService == null) return;
    if (widget.properties.isEmpty) return;
    if (!widget.scrollController.hasClients) return;

    final currentScroll = widget.scrollController.position.pixels;
     
     // Calculate approximate current item index based on scroll position
     // This is a rough estimate - adjust itemExtent based on your card size
     const itemExtent = 200.0; // Approximate card width + margin
     final currentIndex = (currentScroll / itemExtent).floor();
     
     // Check if we should prefetch more images
     final shouldPrefetch = currentIndex > _lastPrefetchedIndex &&
         currentIndex + widget.prefetchThreshold >= widget.visibleItemCount;
     
     if (shouldPrefetch) {
       _lastPrefetchedIndex = currentIndex;
       _prefetchService!.prefetchNextBatch(
         widget.properties,
         currentIndex + widget.visibleItemCount,
         batchSize: widget.prefetchBatchSize,
       );
     }
   }
 
   @override
   Widget build(BuildContext context) {
     return widget.child;
   }
 }
 
 /// A simpler alternative: wrap a horizontal ListView to prefetch on scroll
 class HorizontalPrefetchList extends StatefulWidget {
   final List<Property> properties;
   final Widget Function(BuildContext, int) itemBuilder;
   final double itemWidth;
   final EdgeInsets? padding;
   final ScrollPhysics? physics;
 
   const HorizontalPrefetchList({
     super.key,
     required this.properties,
     required this.itemBuilder,
     this.itemWidth = 262.0,
     this.padding,
     this.physics,
   });
 
   @override
   State<HorizontalPrefetchList> createState() => _HorizontalPrefetchListState();
 }
 
 class _HorizontalPrefetchListState extends State<HorizontalPrefetchList> {
   final ScrollController _scrollController = ScrollController();
   int _lastPrefetchedIndex = 0;
   ImagePrefetchService? _prefetchService;
 
   @override
   void initState() {
     super.initState();
     _scrollController.addListener(_onScroll);
     _initPrefetchService();
     
     // Initial prefetch for first few items
     WidgetsBinding.instance.addPostFrameCallback((_) {
       _prefetchInitialImages();
     });
   }
 
   void _initPrefetchService() {
     if (Get.isRegistered<ImagePrefetchService>()) {
       _prefetchService = Get.find<ImagePrefetchService>();
     }
   }
 
   void _prefetchInitialImages() {
     if (_prefetchService == null) return;
     _prefetchService!.prefetchPropertyImages(widget.properties, limit: 5);
   }
 
   @override
   void dispose() {
     _scrollController.removeListener(_onScroll);
     _scrollController.dispose();
     super.dispose();
   }
 
   void _onScroll() {
     if (_prefetchService == null) return;
     if (widget.properties.isEmpty) return;
 
     final currentScroll = _scrollController.position.pixels;
     final currentIndex = (currentScroll / widget.itemWidth).floor();
     
     // Prefetch when scrolling past 2 more items
     if (currentIndex > _lastPrefetchedIndex + 2) {
       _lastPrefetchedIndex = currentIndex;
       _prefetchService!.prefetchNextBatch(
         widget.properties,
         currentIndex + 3,
         batchSize: 3,
       );
     }
   }
 
   @override
   Widget build(BuildContext context) {
     return ListView.builder(
       controller: _scrollController,
       scrollDirection: Axis.horizontal,
       padding: widget.padding,
       physics: widget.physics,
       itemCount: widget.properties.length,
       itemBuilder: widget.itemBuilder,
     );
   }
 }

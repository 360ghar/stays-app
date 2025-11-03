import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../controllers/activity_controller.dart';
import '../../../data/models/visit_model.dart';

class ActivityView extends GetView<ActivityController> {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.poppinsTextTheme(theme.textTheme);

    return Theme(
      data: theme.copyWith(textTheme: textTheme),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scheduled Visits'),
        ),
        body: Obx(() {
          final visits = controller.scheduledVisits;
          final isLoading = controller.isVisitsLoading.value;

          if (isLoading && visits.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (visits.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => controller.loadScheduledVisits(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: const [
                  _VisitsEmptyState(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadScheduledVisits(forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: visits.length,
              itemBuilder: (context, index) {
                final visit = visits[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _VisitCard(visit: visit),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final scheduledLocal = visit.scheduledDate.toLocal();
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(scheduledLocal);
    final timeLabel = DateFormat('h:mm a').format(scheduledLocal);
    final status = visit.status.isEmpty ? 'pending' : visit.status;
    final statusColor = colors.primary.withValues(alpha: 0.12);
    final statusTextColor = colors.primary;
    final property = visit.property;
    final title = property?.name ?? 'Visit request';
    final location =
        property?.fullAddress ??
        property?.city ??
        property?.address ??
        '—';

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            location,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visit.specialRequirements != null &&
              visit.specialRequirements!.trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                visit.specialRequirements!.trim(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: colors.onSurface.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ),
          if (visit.specialRequirements != null &&
              visit.specialRequirements!.trim().isNotEmpty)
            const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: statusTextColor,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitsEmptyState extends StatelessWidget {
  const _VisitsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 48,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No visits scheduled',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you request a visit, it will appear here with its status.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

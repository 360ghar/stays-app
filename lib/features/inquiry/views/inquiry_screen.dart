import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/features/inquiry/providers/inquiry_providers.dart';
import 'package:stays_app/features/trips/providers/trips_providers.dart';

/// V2 inquiry form. Dates → server pricing → contact → submit.
class InquiryScreen extends ConsumerStatefulWidget {
  const InquiryScreen({super.key, this.property});
  final Property? property;

  @override
  ConsumerState<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends ConsumerState<InquiryScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _requests = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _requests.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final form = ref.read(inquiryFormProvider);
    final now = DateTime.now();
    // Check-out is at least one night after check-in. The initial date must
    // lie inside [firstDate, lastDate] or the picker asserts.
    final firstDate = isCheckIn
        ? now
        : (form.checkIn ?? now).add(const Duration(days: 1));
    final lastDate = firstDate.isAfter(now.add(const Duration(days: 365)))
        ? firstDate.add(const Duration(days: 1))
        : now.add(const Duration(days: 365));
    final wanted = isCheckIn ? form.checkIn : form.checkOut;
    final initialDate = wanted == null || wanted.isBefore(firstDate)
        ? firstDate
        : (wanted.isAfter(lastDate) ? lastDate : wanted);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;
    final notifier = ref.read(inquiryFormProvider.notifier);
    if (isCheckIn) {
      // A check-out on or before the new check-in is no longer valid.
      final keepCheckOut =
          form.checkOut != null && form.checkOut!.isAfter(picked);
      notifier.setDates(picked, keepCheckOut ? form.checkOut : null);
      if (!keepCheckOut) return;
    } else {
      notifier.setDates(form.checkIn, picked);
    }
    final property = widget.property;
    if (property != null) {
      await ref.read(inquiryFormProvider.notifier).loadPricing(property.id);
    }
  }

  Future<void> _setGuests(int guests) async {
    final notifier = ref.read(inquiryFormProvider.notifier);
    notifier.setGuests(guests, max: widget.property?.maxGuests);
    final property = widget.property;
    // Changing the guests clears the price, so ask the server again.
    if (property != null) await notifier.loadPricing(property.id);
  }

  Future<void> _submit() async {
    final property = widget.property;
    if (property == null) return;
    final ok = await ref.read(inquiryFormProvider.notifier).submit(property.id);
    if (!ok || !mounted) return;
    final booking = ref.read(inquiryFormProvider).booking;
    if (booking == null || !mounted) return;
    ref.invalidate(tripsProvider);
    await context.push('/inquiry-confirmation', extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(inquiryFormProvider);
    final notifier = ref.read(inquiryFormProvider.notifier);
    final property = widget.property;
    final dateFmt = DateFormat.MMMd();
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(title: const Text('Request to book')),
      body: ListView(
        padding: const EdgeInsets.all(StayTokens.s16),
        children: [
          if (property != null) ...[
            Text(property.name, style: StayTokens.title),
            Text(property.fullAddress, style: StayTokens.bodySecondary),
            const SizedBox(height: StayTokens.s16),
          ],
          const Text('Dates', style: StayTokens.title),
          const SizedBox(height: StayTokens.s8),
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Check-in',
                  value: form.checkIn == null
                      ? 'Add date'
                      : dateFmt.format(form.checkIn!),
                  onTap: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: StayTokens.s12),
              Expanded(
                child: _DateTile(
                  label: 'Checkout',
                  value: form.checkOut == null
                      ? 'Add date'
                      : dateFmt.format(form.checkOut!),
                  onTap: () => _pickDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: StayTokens.s16),
          Row(
            children: [
              const Text('Guests', style: StayTokens.title),
              const Spacer(),
              IconButton(
                onPressed: () => _setGuests(form.guests - 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('${form.guests}', style: StayTokens.title),
              IconButton(
                onPressed: () => _setGuests(form.guests + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (form.status == InquiryStatus.pricing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: StayTokens.s12),
              child: LinearProgressIndicator(),
            ),
          if (form.pricing != null) _PricingCard(form: form),
          const SizedBox(height: StayTokens.s16),
          const Text('Contact', style: StayTokens.title),
          const SizedBox(height: StayTokens.s8),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name'),
            onChanged: (v) => notifier.setContact(name: v),
          ),
          const SizedBox(height: StayTokens.s12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
            onChanged: (v) => notifier.setContact(phone: v),
          ),
          const SizedBox(height: StayTokens.s12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            onChanged: (v) => notifier.setContact(email: v),
          ),
          const SizedBox(height: StayTokens.s12),
          TextField(
            controller: _requests,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Special requests (optional)',
            ),
            onChanged: notifier.setRequests,
          ),
          if (form.error.isNotEmpty) ...[
            const SizedBox(height: StayTokens.s12),
            Text(
              form.error,
              style: StayTokens.body.copyWith(color: StayTokens.danger),
            ),
          ],
          const SizedBox(height: StayTokens.s24),
          FilledButton(
            // Disabled after a successful submit too: a second tap on the
            // same form would create a second booking.
            onPressed:
                form.canSubmit &&
                    form.status != InquiryStatus.submitting &&
                    form.status != InquiryStatus.success
                ? _submit
                : null,
            child: form.status == InquiryStatus.submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit inquiry'),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(StayTokens.s12),
        decoration: BoxDecoration(
          border: Border.all(color: StayTokens.line),
          borderRadius: BorderRadius.circular(StayTokens.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: StayTokens.label),
            const SizedBox(height: StayTokens.s4),
            Text(value, style: StayTokens.body),
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.form});
  final InquiryFormState form;

  @override
  Widget build(BuildContext context) {
    final pricing = form.pricing!;
    return Container(
      margin: const EdgeInsets.only(top: StayTokens.s16),
      padding: const EdgeInsets.all(StayTokens.s16),
      decoration: BoxDecoration(
        color: StayTokens.paperWarm,
        borderRadius: BorderRadius.circular(StayTokens.radiusCard),
        border: Border.all(color: StayTokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Price details', style: StayTokens.title),
          const SizedBox(height: StayTokens.s8),
          _row('Base', pricing.baseAmount),
          _row('Taxes', pricing.taxesAmount),
          _row('Service charges', pricing.serviceCharges),
          if ((pricing.discountAmount ?? 0) > 0)
            _row('Discount', -pricing.discountAmount!),
          const Divider(),
          Row(
            children: [
              const Text('Total', style: StayTokens.price),
              const Spacer(),
              Text(
                '₹${pricing.totalAmount.toStringAsFixed(0)}',
                style: StayTokens.price,
              ),
            ],
          ),
          if (form.nights != null)
            Text('${form.nights} nights', style: StayTokens.label),
        ],
      ),
    );
  }

  Widget _row(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StayTokens.s4),
      child: Row(
        children: [
          Text(label, style: StayTokens.bodySecondary),
          const Spacer(),
          Text('₹${amount.toStringAsFixed(0)}', style: StayTokens.body),
        ],
      ),
    );
  }
}

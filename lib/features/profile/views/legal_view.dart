import 'package:flutter/material.dart';

class LegalView extends StatelessWidget {
  const LegalView({super.key});

  static const _legalSections = [
    {
      'title': 'Terms & Conditions',
      'body':
          'By using 360ghar Stays you agree to follow local regulations, respect hosts and neighbours, and comply with our cancellation policies. Hosts are responsible for maintaining accurate listings and ensuring safe stays.',
    },
    {
      'title': 'Privacy Policy',
      'body':
          'We collect only the information needed to provide booking services, kept secure via encrypted storage. Review your privacy preferences under Privacy & Security to control data sharing.',
    },
    {
      'title': 'Refund & Cancellation Policy',
      'body':
          'Flexible cancellation is available up to 48 hours before check-in for most stays. Refunds are processed within 5-7 business days. Special events and non-refundable rates follow the listing rules.',
    },
    {
      'title': 'Licenses & Compliance',
      'body':
          '360ghar Stays partners with verified hosts and adheres to regional tourism regulations. We work with local authorities to ensure guest safety and tax compliance.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemBuilder: (context, index) {
          final section = _legalSections[index];
          return _LegalCard(title: section['title']!, body: section['body']!);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: _legalSections.length,
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

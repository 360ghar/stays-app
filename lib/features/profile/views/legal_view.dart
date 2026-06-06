import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stays_app/app/utils/constants/app_constants.dart';

class LegalView extends StatelessWidget {
  const LegalView({super.key});

  static const Map<String, _LegalDocument> _documents = {
    'terms': _LegalDocument(
      title: 'Terms of Service',
      url: AppConstants.termsOfServiceUrl,
    ),
    'privacy': _LegalDocument(
      title: 'Privacy Policy',
      url: AppConstants.privacyPolicyUrl,
    ),
  };

  _LegalDocument _resolveDocument() {
    final raw = Get.arguments;
    final slug = raw is String ? raw.toLowerCase() : 'terms';
    final key = _documents.keys.firstWhere(
      (k) => slug == k || slug == '$k-policy' || slug == '${k}s',
      orElse: () => 'terms',
    );
    return _documents[key]!;
  }

  @override
  Widget build(BuildContext context) {
    final doc = _resolveDocument();
    _openUrl(doc.url);
    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: const Center(
        child: Text('Opening...'),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showError();
      }
    } catch (_) {
      _showError();
    }
  }

  void _showError() {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(content: Text('Could not open this link. Please try again.')),
      );
    }
  }
}

class _LegalDocument {
  const _LegalDocument({required this.title, required this.url});

  final String title;
  final String url;
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stays_app/app/utils/constants/app_constants.dart';

class LegalView extends StatefulWidget {
  const LegalView({super.key});

  @override
  State<LegalView> createState() => _LegalViewState();
}

class _LegalViewState extends State<LegalView> {
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

  late final _LegalDocument _doc;

  @override
  void initState() {
    super.initState();
    _doc = _resolveDocument();
    // Launch once after the first frame, not on every build().
    WidgetsBinding.instance.addPostFrameCallback((_) => _openUrl(_doc.url));
  }

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
    return Scaffold(
      appBar: AppBar(title: Text(_doc.title)),
      body: const Center(
        child: Text('Opening…'),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!mounted) return;
    if (launched) {
      // The external browser is now in front; pop this placeholder screen so
      // the user returns to the previous page instead of a stuck "Opening…".
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      _showError();
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open this link. Please try again.'),
      ),
    );
  }
}

class _LegalDocument {
  const _LegalDocument({required this.title, required this.url});

  final String title;
  final String url;
}

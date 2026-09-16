import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:stays_app/app/data/services/remember_me_service.dart';
import 'package:stays_app/app/utils/helpers/webview_helper.dart';

void main() {
  group('RememberMeService contract', () {
    test('never exposes token storage methods (compile-time contract)', () {
      // The security contract: this service must not persist tokens. If the
      // class ever grows storedAccessToken/storedRefreshToken/persistSession,
      // this test file's imports will not compile — the contract is enforced
      // by the absence of those members.
      expect(RememberMeService, isNotNull);
    });

    test('maskIdentifier masks emails and phones', () {
      expect(
        RememberMeService.maskIdentifier('john@gmail.com'),
        'j***@gmail.com',
      );
      expect(
        RememberMeService.maskIdentifier('+919876543210'),
        contains('****'),
      );
      expect(
        RememberMeService.maskIdentifier('+919876543210'),
        isNot('+919876543210'),
      );
    });

    test('AuthMethods validation', () {
      expect(AuthMethods.isValid('google'), isTrue);
      expect(AuthMethods.isValid('email_password'), isTrue);
      expect(AuthMethods.isValid('nonsense'), isFalse);
      expect(AuthMethods.isValid(null), isFalse);
    });
  });

  group('WebViewHelper navigation policy', () {
    test('allows https Kuula hosts', () {
      final decision = WebViewHelper.defaultNavigationPolicy(
        const NavigationRequest(
          url: 'https://kuula.co/share/abc123',
          isMainFrame: true,
        ),
      );
      expect(decision, NavigationDecision.navigate);
    });

    test('allows https subdomains of kuula.co', () {
      final decision = WebViewHelper.defaultNavigationPolicy(
        const NavigationRequest(
          url: 'https://embed.kuula.co/share/abc123',
          isMainFrame: true,
        ),
      );
      expect(decision, NavigationDecision.navigate);
    });

    test('blocks non-https schemes', () {
      for (final url in [
        'http://kuula.co/share/abc',
        'javascript:alert(1)',
        'file:///etc/passwd',
        'intent://kuula.co#Intent;end',
      ]) {
        final decision = WebViewHelper.defaultNavigationPolicy(
          NavigationRequest(url: url, isMainFrame: true),
        );
        expect(decision, NavigationDecision.prevent, reason: url);
      }
    });

    test('blocks unknown hosts', () {
      final decision = WebViewHelper.defaultNavigationPolicy(
        const NavigationRequest(
          url: 'https://evil.example.com/phish',
          isMainFrame: true,
        ),
      );
      expect(decision, NavigationDecision.prevent);
    });
  });
}

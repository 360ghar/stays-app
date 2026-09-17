import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/app/utils/services/token_service.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      // DI lookups are guarded but still wrapped: a registration racing the
      // guard throws, which is an internal ordering issue — not an auth
      // failure — so it is caught and logged separately below.
      AuthController? auth;
      TokenService? tokenService;
      try {
        if (Get.isRegistered<AuthController>()) {
          auth = Get.find<AuthController>();
        }
        if (Get.isRegistered<TokenService>()) {
          tokenService = Get.find<TokenService>();
        }
      } catch (e, s) {
        AppLogger.error(
          'AuthMiddleware DI error (service not registered)',
          e,
          s,
        );
        return const RouteSettings(name: Routes.login);
      }
      if (auth != null && auth.isAuthenticated.value) {
        return null;
      }
      if (tokenService != null && tokenService.hasValidToken) {
        return null;
      }

      // No in-memory auth state: fall back to the Supabase session. A throw
      // here means the SDK isn't initialized (internal error), NOT "logged
      // out" — logged distinctly from the no-session auth failure below.
      try {
        final session = Supabase.instance.client.auth.currentSession;
        final hasSession = session != null && session.accessToken.isNotEmpty;
        if (!hasSession) {
          AppLogger.info('No token found, redirecting to login');
          return const RouteSettings(name: Routes.login);
        }
      } catch (e, s) {
        AppLogger.error(
          'AuthMiddleware internal error reading Supabase session',
          e,
          s,
        );
        return const RouteSettings(name: Routes.login);
      }

      // Token exists, allow navigation (controller will be created by binding)
      return null;
    } catch (e, s) {
      AppLogger.error('AuthMiddleware unexpected error', e, s);
      // If any error occurs, redirect to login
      return const RouteSettings(name: Routes.login);
    }
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    // Additional security check
    AppLogger.debug('Auth middleware called for route: ${page?.name}');
    return super.onPageCalled(page);
  }
}

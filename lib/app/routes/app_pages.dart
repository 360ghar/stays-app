import 'package:get/get.dart';

import '../bindings/auth_binding.dart';
import '../bindings/booking_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/listing_binding.dart';
import '../bindings/message_binding.dart';
import '../bindings/payment_binding.dart';
import '../bindings/trips_binding.dart';
import '../bindings/settings_binding.dart';
import '../bindings/splash_binding.dart';
import '../bindings/tour_binding.dart';
import '../middlewares/auth_middleware.dart';
import '../middlewares/initial_middleware.dart';
import '../ui/views/auth/forgot_password_view.dart';
import '../ui/views/auth/phone_login_view.dart';
import '../ui/views/auth/reset_password_view.dart';
import '../ui/views/auth/signup_view.dart';
import '../ui/views/auth/verification_view.dart';
import '../ui/views/booking/booking_view.dart';
import '../ui/views/booking/booking_confirmation_view.dart';
import '../ui/views/home/home_shell_view.dart';
import '../ui/views/listing/listing_detail_view.dart';
import '../ui/views/listing/location_search_view.dart';
import '../ui/views/listing/search_results_view.dart';
import '../ui/views/messaging/chat_view.dart';
import '../ui/views/messaging/locate_view.dart';
import '../ui/views/payment/payment_methods_view.dart';
import '../ui/views/payment/payment_view.dart';
import '../ui/views/settings/settings_view.dart';
import '../ui/views/splash/splash_view.dart';
import '../ui/views/bookings/bookings_page.dart';
import '../ui/views/tour/tour_view.dart';
import 'app_routes.dart';
import 'package:stays_app/features/profile/bindings/profile_binding.dart'
    as feature_profile_binding;
import 'package:stays_app/features/profile/views/profile_view.dart'
    as feature_profile_view;
import 'package:stays_app/features/profile/views/edit_profile_view.dart'
    as feature_edit_profile_view;
import 'package:stays_app/features/profile/views/preferences_view.dart'
    as feature_preferences_view;
import 'package:stays_app/features/profile/views/notifications_view.dart'
    as feature_notifications_view;
import 'package:stays_app/features/profile/views/privacy_view.dart'
    as feature_privacy_view;
import 'package:stays_app/features/profile/views/help_view.dart'
    as feature_help_view;
import 'package:stays_app/features/profile/views/about_view.dart'
    as feature_about_view;
import 'package:stays_app/features/profile/views/legal_view.dart'
    as feature_legal_view;

class AppPages {
  static const initial = Routes.initial;

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: Routes.initial,
      page: () => const SplashView(),
      binding: SplashBinding(),
      middlewares: [InitialMiddleware()],
    ),
    GetPage(
      name: Routes.login,
      page: () => const PhoneLoginView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.register,
      page: () => const SignupView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: AuthBinding(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: Routes.verification,
      page: () => const VerificationView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.resetPassword,
      page: () => const ResetPasswordView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeShellView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.search,
      page: () => const LocationSearchView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.searchResults,
      page: () => const SearchResultsView(),
      binding: HomeBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.listingDetail,
      page: () => const ListingDetailView(),
      binding: ListingBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.tour,
      page: () => const TourView(),
      binding: TourBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.booking,
      page: () => const BookingView(),
      binding: BookingBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.bookingConfirmation,
      page: () => const BookingConfirmationView(),
      binding: BookingBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.payment,
      page: () => const PaymentView(),
      binding: PaymentBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.paymentMethods,
      page: () => const PaymentMethodsView(),
      binding: PaymentBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.inbox,
      page: () => const LocateView(),
      binding: MessageBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.chat,
      page: () => const ChatView(),
      binding: MessageBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profile,
      page: () => const feature_profile_view.ProfileView(),
      binding: feature_profile_binding.ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.editProfile,
      page: () => const feature_edit_profile_view.EditProfileView(),
      binding: feature_profile_binding.ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profilePreferences,
      page: () => const feature_preferences_view.PreferencesView(),
      binding: feature_profile_binding.ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profileNotifications,
      page: () => const feature_notifications_view.NotificationsView(),
      binding: feature_profile_binding.ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profilePrivacy,
      page: () => const feature_privacy_view.PrivacyView(),
      binding: feature_profile_binding.ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profileHelp,
      page: () => const feature_help_view.HelpView(),
      binding: feature_profile_binding.ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profileAbout,
      page: () => const feature_about_view.AboutView(),
      binding: feature_profile_binding.ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profileLegal,
      page: () => const feature_legal_view.LegalView(),
      binding: feature_profile_binding.ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.accountSettings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.cupertino,
    ),
    GetPage(
      name: Routes.trips,
      page: () => BookingsPage(),
      binding: TripsBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}

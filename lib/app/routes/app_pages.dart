import 'package:get/get.dart';

// Feature imports - Auth
import 'package:stays_app/features/auth/bindings/auth_binding.dart';
import 'package:stays_app/features/auth/views/forgot_password_view.dart';
import 'package:stays_app/features/auth/views/phone_login_view.dart';
import 'package:stays_app/features/auth/views/reset_password_view.dart';
import 'package:stays_app/features/auth/views/signup_view.dart';
import 'package:stays_app/features/auth/views/verification_view.dart';

// Feature imports - Splash
import 'package:stays_app/features/splash/bindings/splash_binding.dart';
import 'package:stays_app/features/splash/views/splash_view.dart';

// Feature imports - Home
import 'package:stays_app/features/home/bindings/home_binding.dart';
import 'package:stays_app/features/home/views/home_shell_view.dart';

// Feature imports - Listing
import 'package:stays_app/features/listing/bindings/listing_binding.dart';
import 'package:stays_app/features/listing/views/listing_detail_view.dart';
import 'package:stays_app/features/listing/views/location_search_view.dart';
import 'package:stays_app/features/listing/views/search_results_view.dart';

// Feature imports - Inquiry
import 'package:stays_app/features/inquiry/bindings/inquiry_binding.dart';
import 'package:stays_app/features/inquiry/views/inquiry_view.dart';
import 'package:stays_app/features/inquiry/views/inquiry_confirmation_view.dart';
import 'package:stays_app/features/inquiry/views/inquiry_page.dart';

// Feature imports - Payment
import 'package:stays_app/features/payment/bindings/payment_binding.dart';
import 'package:stays_app/features/payment/views/payment_methods_view.dart';
import 'package:stays_app/features/payment/views/payment_view.dart';

// Feature imports - Messaging
import 'package:stays_app/features/messaging/bindings/message_binding.dart';
import 'package:stays_app/features/messaging/views/chat_view.dart';
import 'package:stays_app/features/messaging/views/locate_view.dart';

// Feature imports - Settings
import 'package:stays_app/features/settings/bindings/settings_binding.dart';
import 'package:stays_app/features/settings/views/settings_view.dart';

// Feature imports - Trips
import 'package:stays_app/features/trips/bindings/trips_binding.dart';

// Feature imports - Tour
import 'package:stays_app/features/tour/bindings/tour_binding.dart';
import 'package:stays_app/features/tour/views/tour_view.dart';

// Core imports - Middleware and Routes
import '../middlewares/auth_middleware.dart';
import '../middlewares/initial_middleware.dart';
import 'app_routes.dart';

// Feature imports - Profile
import 'package:stays_app/features/profile/bindings/profile_binding.dart';
import 'package:stays_app/features/profile/views/profile_view.dart';
import 'package:stays_app/features/profile/views/edit_profile_view.dart';
import 'package:stays_app/features/profile/views/preferences_view.dart';
import 'package:stays_app/features/profile/views/notifications_view.dart';
import 'package:stays_app/features/profile/views/privacy_view.dart';
import 'package:stays_app/features/profile/views/help_view.dart';
import 'package:stays_app/features/profile/views/about_view.dart';
import 'package:stays_app/features/profile/views/legal_view.dart';

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
      name: Routes.inquiry,
      page: () => const InquiryView(),
      binding: InquiryBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.inquiryConfirmation,
      page: () => const InquiryConfirmationView(),
      binding: InquiryBinding(),
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
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.editProfile,
      page: () => const EditProfileView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profilePreferences,
      page: () => const PreferencesView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profileNotifications,
      page: () => const NotificationsView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profilePrivacy,
      page: () => const PrivacyView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profileHelp,
      page: () => const HelpView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profileAbout,
      page: () => const AboutView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.profileLegal,
      page: () => const LegalView(),
      binding: ProfileBinding(),
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
      name: Routes.inquiries,
      page: () => InquiriesPage(),
      binding: TripsBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}

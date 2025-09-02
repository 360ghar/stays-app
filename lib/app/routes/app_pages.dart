import 'package:get/get.dart';

import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/listing_binding.dart';
import '../bindings/booking_binding.dart';
import '../bindings/initial_binding.dart';
import '../bindings/message_binding.dart';
import '../bindings/payment_binding.dart';
import '../bindings/profile_binding.dart';

import '../middlewares/auth_middleware.dart';
import '../middlewares/initial_middleware.dart';

import '../ui/views/auth/phone_login_view.dart';
import '../ui/views/auth/signup_view.dart';
import '../ui/views/auth/forgot_password_view.dart';
import '../ui/views/auth/verification_view.dart';
import '../ui/views/auth/reset_password_view.dart';
import '../ui/views/home/home_shell_view.dart';
import '../ui/views/home/explore_view.dart';
import '../ui/views/listing/listing_detail_view.dart';
import '../ui/views/listing/search_results_view.dart';
import '../ui/views/booking/booking_view.dart';
import '../ui/views/payment/payment_view.dart';
import '../ui/views/payment/payment_methods_view.dart';
import '../ui/views/messaging/inbox_view.dart';
import '../ui/views/messaging/chat_view.dart';
import '../ui/views/profile/profile_view.dart';
import '../ui/views/splash/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = Routes.initial;

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: Routes.initial,
      page: () => const SplashView(),
      binding: InitialBinding(),
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
      page: () => const ExploreView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.searchResults,
      page: () => const SearchResultsView(),
      binding: HomeBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: Routes.listingDetail,
      page: () => const ListingDetailView(),
      binding: ListingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.booking,
      page: () => const BookingView(),
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
      page: () => const InboxView(),
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
  ];
}

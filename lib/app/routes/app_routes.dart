abstract class Routes {
  static const initial = '/';
  static const forceUpdate = '/force-update';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verification = '/verification';
  static const resetPassword = '/reset-password';
  static const setPassword = '/set-password';
  static const profileCompletion = '/profile-completion';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const search = '/search';
  static const searchResults = '/search-results';
  static const listingDetail = '/listing/:id';
  // Inquiry flow (client-side wording)
  static const inquiry = '/inquiry';
  static const inquiryConfirmation = '/inquiry-confirmation';
  static const payment = '/payment';
  static const paymentMethods = '/payment-methods';
  static const profile = '/profile';
  static const inbox = '/inbox';
  static const chat = '/chat/:conversationId';
  static const tour = '/tour';
  static const wishlist = '/wishlist';

  // Profile related routes
  static const inquiries = '/inquiries';
  static const accountSettings = '/account-settings';
  static const editProfile = '/profile/edit';
  static const profilePreferences = '/profile/preferences';
  static const profileNotifications = '/profile/notifications';
  static const profilePrivacy = '/profile/privacy';
  static const profileHelp = '/profile/help';
  static const profileAbout = '/profile/about';
  static const profileLegal = '/profile/legal';
  static const profileFeedbackBug = '/profile/feedback/bug';
  static const profileFeedbackFeature = '/profile/feedback/feature';

  // Backwards compatibility aliases (deprecated; migrate to the canonical
  // constants above). Will be removed once consumers migrate.
  @Deprecated(
    'Use Routes.inquiry instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const enquiry = inquiry; // British spelling alias
  @Deprecated(
    'Use Routes.inquiryConfirmation instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const enquiryConfirmation = inquiryConfirmation;
  @Deprecated(
    'Use Routes.inquiry instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const booking = inquiry; // Legacy naming alias
  @Deprecated(
    'Use Routes.inquiryConfirmation instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const bookingConfirmation = inquiryConfirmation;
  @Deprecated(
    'Use Routes.inquiries instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const enquiries = inquiries; // British spelling alias
  @Deprecated(
    'Use Routes.inquiries instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const trips = inquiries;
  @Deprecated(
    'Use Routes.profileHelp instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const help = profileHelp;
  @Deprecated(
    'Use Routes.editProfile instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const profileView = editProfile;
  @Deprecated(
    'Use Routes.profilePrivacy instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const privacySecurity = profilePrivacy;
  @Deprecated(
    'Use Routes.profileAbout instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const appInfo = profileAbout;
  @Deprecated(
    'Use Routes.profileLegal instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const legal = profileLegal;
  @Deprecated(
    'Use Routes.profilePrivacy instead (deprecated since 1.0.1, remove in 1.1.0)',
  )
  static const privacy = profilePrivacy;
}

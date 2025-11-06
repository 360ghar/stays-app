abstract class Routes {
  static const initial = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verification = '/verification';
  static const resetPassword = '/reset-password';
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

  // Backwards compatibility aliases (will be removed once consumers migrate)
  static const enquiry = inquiry; // British spelling alias
  static const enquiryConfirmation = inquiryConfirmation;
  static const booking = inquiry; // Legacy naming alias
  static const bookingConfirmation = inquiryConfirmation;
  static const enquiries = inquiries; // British spelling alias
  static const trips = inquiries;
  static const help = profileHelp;
  static const profileView = editProfile;
  static const privacySecurity = profilePrivacy;
  static const appInfo = profileAbout;
  static const legal = profileLegal;
  static const privacy = profilePrivacy;
}

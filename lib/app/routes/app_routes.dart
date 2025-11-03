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
  static const scheduleVisit = '/schedule-visit';
  static const booking = '/booking';
  static const bookingConfirmation = '/booking-confirmation';
  static const payment = '/payment';
  static const paymentMethods = '/payment-methods';
  static const profile = '/profile';
  static const inbox = '/inbox';
  static const chat = '/chat/:conversationId';
  static const tour = '/tour';
  static const wishlist = '/wishlist';

  // Profile related routes
  static const activity = '/activity';
  static const trips = activity;
  static const accountSettings = '/account-settings';
  static const editProfile = '/profile/edit';
  static const profilePreferences = '/profile/preferences';
  static const profileNotifications = '/profile/notifications';
  static const profilePrivacy = '/profile/privacy';
  static const profileHelp = '/profile/help';
  static const profileAbout = '/profile/about';
  static const profileLegal = '/profile/legal';

  // Backwards compatibility aliases (will be removed once consumers migrate)
  static const help = profileHelp;
  static const profileView = editProfile;
  static const privacySecurity = profilePrivacy;
  static const appInfo = profileAbout;
  static const legal = profileLegal;
  static const privacy = profilePrivacy;
}

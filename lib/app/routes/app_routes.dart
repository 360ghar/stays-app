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
  static const booking = '/booking';
  static const payment = '/payment';
  static const paymentMethods = '/payment-methods';
  static const profile = '/profile';
  static const inbox = '/inbox';
  static const chat = '/chat/:conversationId';
  static const wishlist = '/wishlist';
  
  // Profile related routes
  static const trips = '/trips';
  static const accountSettings = '/account-settings';
  static const help = '/help';
  static const profileView = '/profile-view';
  static const privacy = '/privacy';
  static const legal = '/legal';
}

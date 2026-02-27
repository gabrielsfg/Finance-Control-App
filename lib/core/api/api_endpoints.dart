import '../config/app_config.dart';

abstract class ApiEndpoints {
  static String get baseUrl => AppConfig.apiBaseUrl;

  // Auth — UserController
  static const String login = '/api/user/login';
  static const String register = '/api/user/register';

  // Main page
  static const String mainPageSummary = '/api/mainpage/summary';

  // Accounts
  static const String accounts = '/api/accounts';

  // Transactions
  static const String transactions = '/api/transactions';

  // Categories
  static const String categories = '/api/categories';

  // Budgets
  static const String budgets = '/api/budgets';
}

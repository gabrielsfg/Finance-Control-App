import '../config/app_config.dart';

abstract class ApiEndpoints {
  static String get baseUrl => AppConfig.apiBaseUrl;

  // Auth — UserController
  static const String login = '/api/user/login';
  static const String register = '/api/user/register';

  // Main page
  static const String mainPageSummary = '/api/mainpage/summary';

  // Accounts
  static const String accounts = '/api/Account';
  static String accountById(int id) => '/api/Account/$id';

  // Transactions
  static const String transactions = '/api/Transaction';

  // Categories (transaction picker — includes system categories)
  static const String categories = '/api/categories';

  // Categories (user-owned — CRUD)
  static const String userCategories = '/api/category';
  static String userCategoryById(int id) => '/api/category/$id';
  static const String userCategoryUpdate = '/api/category';

  // Subcategories
  static const String subcategories = '/api/SubCategory';
  static const String allSubcategories = '/api/SubCategory/all';
  static String subcategoryById(int id) => '/api/SubCategory/by-id/$id';
  static String deleteSubcategory(int id) => '/api/SubCategory/$id';

  // Budgets
  static const String budgets = '/api/budgets';
}

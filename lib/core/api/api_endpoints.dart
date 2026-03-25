import '../config/app_config.dart';

abstract class ApiEndpoints {
  static String get baseUrl => AppConfig.apiBaseUrl;

  // Auth — UserController
  static const String login = '/api/user/login';
  static const String register = '/api/user/register';
  static const String refresh = '/api/user/refresh';
  static const String logout = '/api/user/logout';
  static const String forgotPassword = '/api/user/forgot-password';
  static const String resetPassword = '/api/user/reset-password';
  static const String verifyEmail = '/api/user/verify-email';
  static const String userMe = '/api/user/me';
  static const String resetData = '/api/user/me/reset-data';

  // Main page
  static const String mainPageSummary = '/api/mainpage/summary';

  // Accounts
  static const String accounts = '/api/Account';
  static String accountById(int id) => '/api/Account/$id';

  // Transactions
  static const String transactions = '/api/transaction';
  static String transactionById(int id) => '/api/transaction/$id';
  static String transactionsByBudget(int budgetId) =>
      '/api/transaction/by-budget/$budgetId';
  static String transactionsByAccount(int accountId) =>
      '/api/transaction/by-account/$accountId';
  static String transactionsBySubcategory(int subCategoryId) =>
      '/api/transaction/by-subcategory/$subCategoryId';
  static String updateRecurringTransaction(int recurringId) =>
      '/api/transaction/$recurringId/recurring';
  static String cancelRecurringTransaction(int recurringId) =>
      '/api/transaction/$recurringId/recurring/cancel';

  // Categories (user-owned — CRUD)
  static const String userCategories = '/api/category';
  static String userCategoryById(int id) => '/api/category/$id';

  // Subcategories
  static const String subcategories = '/api/SubCategory';
  static String subcategoryById(int id) => '/api/SubCategory/$id';
  static String deleteSubcategory(int id) => '/api/SubCategory/$id';

  // Currencies
  static const String currencies = '/api/currencies';

  // Banks
  static const String banks = '/api/banks';

  // Payment methods
  static const String paymentMethods = '/api/payment-methods';

  // Wishlist
  static const String wishlist = '/api/wishlist';
  static String wishlistById(int id) => '/api/wishlist/$id';
  static String wishlistPrice(int id) => '/api/wishlist/$id/price';
  static String wishlistPurchase(int id) => '/api/wishlist/$id/purchase';
  static String wishlistPriceHistory(int id) => '/api/wishlist/$id/price-history';

  // Budgets
  static const String budgets = '/api/budget';
  static String budgetById(int id) => '/api/budget/$id';
  static String budgetWithAllocations(int id) => '/api/budget/$id/allocation';

  // Budget Areas
  static const String budgetAreas = '/api/area';
  static String areaById(int id) => '/api/area/$id';
  static String budgetAreasByBudget(int budgetId) => '/api/area?budgetId=$budgetId';

  // Budget Allocations
  static String budgetAllocations(int budgetId) =>
      '/api/budgets/$budgetId/allocation';
  static String budgetAllocationsByArea(int budgetId, int areaId) =>
      '/api/budgets/$budgetId/allocation/by-area/$areaId';
  static String budgetAllocationById(int budgetId, int allocationId) =>
      '/api/budgets/$budgetId/allocation/$allocationId';
}

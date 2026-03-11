import '../data/models/budget_models.dart';

/// Singleton that holds wizard state across the 3 creation steps.
/// Cleared when the wizard is dismissed or completed.
class CreateBudgetState {
  CreateBudgetState._();
  static final instance = CreateBudgetState._();

  String name = '';
  String recurrence = 'Monthly';
  int startDay = 1;
  List<DraftArea> areas = [];

  void reset() {
    name = '';
    recurrence = 'Monthly';
    startDay = 1;
    areas = [];
  }
}

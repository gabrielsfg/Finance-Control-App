// TODO: replace with API-connected model
/// Lightweight view model used to display a recent transaction on the home screen.
class TransactionPreview {
  final String name;
  final String category;
  final int amountCents;
  final String emoji;
  final int color; // ARGB int, e.g. 0xFF8B5CF6

  const TransactionPreview(
      this.name, this.category, this.amountCents, this.emoji, this.color);
}

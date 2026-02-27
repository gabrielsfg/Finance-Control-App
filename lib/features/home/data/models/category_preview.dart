// TODO: replace with API-connected model
/// Lightweight view model used to display a top-spending category on the home screen.
class CategoryPreview {
  final String name;
  final String emoji;
  final int amountCents;
  final int color; // ARGB int, e.g. 0xFF8B5CF6

  const CategoryPreview(this.name, this.emoji, this.amountCents, this.color);
}

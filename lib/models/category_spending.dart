// summarize one category using the saved usd amounts
class CategorySpending {
  const CategorySpending({
    required this.category,
    required this.amountUsdMinor,
    required this.expenseCount,
    required this.share,
  });
  final String category;
  final int amountUsdMinor;
  final int expenseCount;
  final double share;
}

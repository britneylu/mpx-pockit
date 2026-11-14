import 'package:flutter/material.dart';

import '../core/money.dart';
import '../core/category_style.dart';
import 'category_donut.dart';
import '../models/category_spending.dart';
import '../models/currency.dart';

// compare category totals with labeled bars rather than color alone
class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onCategorySelected,
    this.selectedContent,
  });
  final List<CategorySpending> categories;
  final String? selectedCategory;
  final ValueChanged<String>? onCategorySelected;
  final Widget? selectedContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // replace category summaries with individual purchases when selected
    if (selectedCategory != null && selectedContent != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CategoryDonut(
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
          const SizedBox(height: 16),
          selectedContent!,
        ],
      );
    }
    if (categories.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CategoryDonut(categories: []),
          SizedBox(height: 16),
          Text('No expenses for this month yet.'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryDonut(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategorySelected: onCategorySelected,
        ),
        const SizedBox(height: 8),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Semantics(
              container: true,
              button: onCategorySelected != null,
              selected: onCategorySelected == null
                  ? null
                  : selectedCategory == category.category,
              onTap: onCategorySelected == null
                  ? null
                  : () => onCategorySelected!(category.category),
              label:
                  '${category.category}, ${formatMinor(category.amountUsdMinor, Currency.usd)} USD, '
                  '${(category.share * 100).toStringAsFixed(1)} percent of spending, '
                  '${category.expenseCount} ${category.expenseCount == 1 ? 'expense' : 'expenses'}',
              child: ExcludeSemantics(
                child: InkWell(
                  key: ValueKey('categoryFilter-${category.category}'),
                  onTap: onCategorySelected == null
                      ? null
                      : () => onCategorySelected!(category.category),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: selectedCategory == category.category
                          ? CategoryStyle.tint(
                              category.category,
                              strength: 0.12,
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // wrapping keeps long amounts readable at larger text sizes
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  key: ValueKey(
                                    'categoryColor-${category.category}',
                                  ),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: CategoryStyle.color(
                                      category.category,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    category.category,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${formatMinor(category.amountUsdMinor, Currency.usd)} USD',
                              key: ValueKey(
                                'categoryAmount-${category.category}',
                              ),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: category.share.clamp(0.0, 1.0),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: CategoryStyle.color(category.category),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(category.share * 100).toStringAsFixed(1)}% of spending · '
                          '${category.expenseCount} ${category.expenseCount == 1 ? 'expense' : 'expenses'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

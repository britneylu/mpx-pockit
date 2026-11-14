import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/category_style.dart';
import '../core/money.dart';
import '../models/category_spending.dart';
import '../models/currency.dart';

// show shares of actual spending without needing a budget
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onCategorySelected,
  });
  final List<CategorySpending> categories;
  final String? selectedCategory;
  final ValueChanged<String>? onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final total = categories.fold(
      0,
      (sum, category) => sum + category.amountUsdMinor,
    );
    final amount = formatMinor(total, Currency.usd);
    final theme = Theme.of(context);
    return Semantics(
      label: 'Category spending chart',
      value: categories.isEmpty
          ? 'No spending yet'
          : '$amount USD total spending',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(260.0, constraints.maxWidth);
            return Center(
              child: GestureDetector(
                onTapUp: onCategorySelected == null
                    ? null
                    : (details) {
                        final delta =
                            details.localPosition - Offset(size / 2, size / 2);
                        final stroke = size * 0.105;
                        final radius = (size - stroke) / 2;
                        if (delta.distance < radius - stroke / 2 ||
                            delta.distance > radius + stroke / 2 ||
                            total == 0) {
                          return;
                        }
                        final angle =
                            (math.atan2(delta.dy, delta.dx) + math.pi / 2) %
                            (2 * math.pi);
                        var end = 0.0;
                        for (final category in categories) {
                          end += category.amountUsdMinor / total * 2 * math.pi;
                          if (angle < end) {
                            onCategorySelected!(category.category);
                            break;
                          }
                        }
                      },
                child: SizedBox.square(
                  dimension: size,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        key: const Key('categoryDonut'),
                        painter: CategoryDonutPainter(
                          categories,
                          theme.colorScheme.surfaceContainerHighest,
                          selectedCategory: selectedCategory,
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          width: size * 0.58,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (categories.isEmpty)
                                Text(
                                  'No spending\nyet',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium,
                                )
                              else ...[
                                const Text(
                                  'Total spent',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    amount,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('USD', textAlign: TextAlign.center),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// paint colored arcs from saved usd totals and leave a neutral track when empty
class CategoryDonutPainter extends CustomPainter {
  CategoryDonutPainter(
    List<CategorySpending> categories,
    this.trackColor, {
    this.selectedCategory,
  }) : categories = List.unmodifiable(categories);
  final List<CategorySpending> categories;
  final Color trackColor;
  final String? selectedCategory;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.105;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = trackColor);
    final positive = categories
        .where((item) => item.amountUsdMinor > 0)
        .toList();
    final total = positive.fold(0, (sum, item) => sum + item.amountUsdMinor);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (final item in positive) {
      final sweep = item.amountUsdMinor / total * 2 * math.pi;
      // keep tiny slices visible and avoid gaps for a single category
      final gap = positive.length == 1 ? 0.0 : math.min(0.025, sweep / 3);
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep - gap,
        false,
        paint
          ..color =
              selectedCategory != null && selectedCategory != item.category
              ? CategoryStyle.color(item.category).withValues(alpha: 0.25)
              : CategoryStyle.color(item.category),
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CategoryDonutPainter oldDelegate) =>
      oldDelegate.trackColor != trackColor ||
      oldDelegate.selectedCategory != selectedCategory ||
      !listEquals(oldDelegate.categories, categories);
}

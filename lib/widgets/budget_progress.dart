import 'package:flutter/material.dart';

// animate the fill while keeping the true percentage visible above the limit
class BudgetProgress extends StatelessWidget {
  const BudgetProgress({super.key, required this.usage});
  final double usage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final over = usage > 1;
    final color = over ? theme.colorScheme.error : theme.colorScheme.primary;
    final percent = (usage * 100)
        .toStringAsFixed(1)
        .replaceFirst(RegExp(r'\.0$'), '');
    final status = over
        ? 'Over budget'
        : usage == 1
        ? 'Budget reached'
        : 'Within budget';
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Monthly budget usage',
      value: '$percent percent used, ${status.toLowerCase()}',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 4,
              children: [
                const Text('Budget used'),
                Text(
                  '$percent% used',
                  key: const Key('budgetPercentage'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // preserve the animated value when amounts budgets or months change
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: usage.clamp(0.0, 1.0)),
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                key: const Key('budgetProgressFill'),
                value: value,
                minHeight: 12,
                borderRadius: BorderRadius.circular(8),
                color: color,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            // use text and icons so budget status does not rely on color alone
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  over
                      ? Icons.warning_amber_rounded
                      : usage == 1
                      ? Icons.flag_outlined
                      : Icons.check_circle_outline,
                  size: 18,
                  color: color,
                ),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/models/subscription.dart';
import '../theme/app_theme.dart';
import '../widgets/neomorphic_card.dart';

class AnalyticsScreen extends StatelessWidget {
  final List<Subscription> subscriptions;

  const AnalyticsScreen({
    Key? key,
    required this.subscriptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) {
      return const Center(
        child: Text('No subscriptions to analyze'),
      );
    }

    final totalMonthlySpending = _calculateTotalMonthlySpending();
    final activeSubscriptions = subscriptions.where((s) => s.isActive).length;
    final mostExpensiveSubscription = _getMostExpensiveSubscription();
    final upcomingPayments = _getUpcomingPayments();
    final categorySpending = _calculateCategorySpending();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(
            context,
            title: 'Monthly Spending',
            value: '₹${totalMonthlySpending.toStringAsFixed(2)}',
            icon: Icons.attach_money,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            context,
            title: 'Active Subscriptions',
            value: activeSubscriptions.toString(),
            icon: Icons.check_circle,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            context,
            title: 'Most Expensive',
            value: mostExpensiveSubscription?.serviceName ?? 'N/A',
            subtitle: mostExpensiveSubscription != null
                ? '₹${mostExpensiveSubscription.amount.toStringAsFixed(2)}/${mostExpensiveSubscription.billingCycle}'
                : null,
            icon: Icons.star,
          ),
          const SizedBox(height: 24),
          Text(
            'Spending by Category',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildCategoryBarChart(context, categorySpending),
          const SizedBox(height: 16),
          ...categorySpending.entries.map((entry) => NeomorphicCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _getCategoryIcon(entry.key),
                  title: Text(entry.key),
                  trailing: Text(
                    '₹${entry.value.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              )),
          const SizedBox(height: 24),
          Text(
            'Upcoming Payments',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...upcomingPayments.map((subscription) => NeomorphicCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(subscription.serviceName),
                  subtitle: Text(
                    '₹${subscription.amount.toStringAsFixed(2)} - ${subscription.billingCycle}',
                  ),
                  trailing: Text(
                    subscription.formattedNextBillingDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryBarChart(
      BuildContext context, Map<String, double> categorySpending) {
    if (categorySpending.isEmpty) {
      return const SizedBox(
          height: 200, child: Center(child: Text('No data available')));
    }

    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    final totalSpending = categorySpending.values.reduce((a, b) => a + b);
    final maxSpending = categorySpending.values.reduce((a, b) => a > b ? a : b);

    return NeomorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSpending * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Theme.of(context).colorScheme.surface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final category =
                          categorySpending.keys.elementAt(groupIndex);
                      final amount = categorySpending[category]!;
                      final percentage =
                          (amount / totalSpending * 100).toStringAsFixed(1);
                      return BarTooltipItem(
                        '$category\n₹${amount.toStringAsFixed(2)}\n$percentage%',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < categorySpending.length) {
                          final category =
                              categorySpending.keys.elementAt(index);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: categorySpending.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final category = entry.value.key;
                  final amount = entry.value.value;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: amount,
                        color: colors[index % colors.length],
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children:
                categorySpending.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value.key;
              final amount = entry.value.value;
              final percentage =
                  (amount / totalSpending * 100).toStringAsFixed(1);

              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: colors[index % colors.length],
                  radius: 8,
                ),
                label: Text('$category (${percentage}%)'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  double _calculateTotalMonthlySpending() {
    return subscriptions.fold(0.0, (total, subscription) {
      if (!subscription.isActive) return total;

      final monthlyAmount = switch (subscription.billingCycle.toLowerCase()) {
        'monthly' => subscription.amount,
        'quarterly' => subscription.amount / 3,
        'yearly' => subscription.amount / 12,
        'weekly' => subscription.amount * 4,
        _ => subscription.amount,
      };

      return total + monthlyAmount;
    });
  }

  Map<String, double> _calculateCategorySpending() {
    final categorySpending = <String, double>{};

    for (final subscription in subscriptions) {
      if (!subscription.isActive) continue;

      final category = subscription.category ?? 'Uncategorized';
      final monthlyAmount = switch (subscription.billingCycle.toLowerCase()) {
        'monthly' => subscription.amount,
        'quarterly' => subscription.amount / 3,
        'yearly' => subscription.amount / 12,
        'weekly' => subscription.amount * 4,
        _ => subscription.amount,
      };

      categorySpending[category] =
          (categorySpending[category] ?? 0) + monthlyAmount;
    }

    // Sort by spending amount (descending)
    final sortedEntries = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  Subscription? _getMostExpensiveSubscription() {
    if (subscriptions.isEmpty) return null;

    return subscriptions.reduce((a, b) {
      final aMonthly = _getMonthlyAmount(a);
      final bMonthly = _getMonthlyAmount(b);
      return aMonthly > bMonthly ? a : b;
    });
  }

  double _getMonthlyAmount(Subscription subscription) {
    return switch (subscription.billingCycle.toLowerCase()) {
      'monthly' => subscription.amount,
      'quarterly' => subscription.amount / 3,
      'yearly' => subscription.amount / 12,
      'weekly' => subscription.amount * 4,
      _ => subscription.amount,
    };
  }

  List<Subscription> _getUpcomingPayments() {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    return subscriptions.where((s) => s.isActive).where((s) {
      final nextBilling = DateTime.parse(s.nextBillingDate);
      return nextBilling.isAfter(now) &&
          nextBilling.isBefore(thirtyDaysFromNow);
    }).toList()
      ..sort((a, b) => DateTime.parse(a.nextBillingDate)
          .compareTo(DateTime.parse(b.nextBillingDate)));
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
  }) {
    return NeomorphicCard(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Icon _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'streaming':
        return const Icon(Icons.movie);
      case 'music':
        return const Icon(Icons.music_note);
      case 'cloud storage':
        return const Icon(Icons.cloud);
      case 'gaming':
        return const Icon(Icons.games);
      case 'productivity':
        return const Icon(Icons.computer);
      default:
        return const Icon(Icons.category);
    }
  }
}

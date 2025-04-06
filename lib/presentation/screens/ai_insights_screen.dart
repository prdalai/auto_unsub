import 'package:flutter/material.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/services/subscription_ai_service.dart';
import '../theme/neomorphic_theme.dart';

class AIInsightsScreen extends StatefulWidget {
  final List<Subscription> subscriptions;
  final SubscriptionAIService aiService;

  const AIInsightsScreen({
    Key? key,
    required this.subscriptions,
    required this.aiService,
  }) : super(key: key);

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  late Future<SubscriptionInsights> _insightsFuture;

  @override
  void initState() {
    super.initState();
    _insightsFuture =
        widget.aiService.generateSubscriptionInsights(widget.subscriptions);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SubscriptionInsights>(
      future: _insightsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final insights = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthlySpendingCard(context, insights.totalMonthlySpending),
              const SizedBox(height: 16),
              _buildInsightsSection(context, insights.insights),
              const SizedBox(height: 16),
              _buildRecommendationsSection(context, insights.recommendations),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlySpendingCard(BuildContext context, double totalSpending) {
    return Container(
      decoration: NeomorphicTheme.neomorphicDecoration(
        borderRadius: 12,
        blurRadius: 10,
        offset: 5,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Spending',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '₹${totalSpending.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: totalSpending / 500, // Assuming $500 is the max
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(
    BuildContext context,
    List<SubscriptionInsight> insights,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...insights.map((insight) => _buildInsightCard(context, insight)),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context, SubscriptionInsight insight) {
    final icon = _getInsightIcon(insight.type);
    final color = _getInsightColor(insight.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: NeomorphicTheme.neomorphicDecoration(
        borderRadius: 12,
        blurRadius: 10,
        offset: 5,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                insight.message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(
    BuildContext context,
    List<SubscriptionRecommendation> recommendations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...recommendations.map((recommendation) =>
            _buildRecommendationCard(context, recommendation)),
      ],
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    SubscriptionRecommendation recommendation,
  ) {
    final color = _getRecommendationColor(recommendation.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: NeomorphicTheme.neomorphicDecoration(
        borderRadius: 12,
        blurRadius: 10,
        offset: 5,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  recommendation.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.spendingTrend:
        return Icons.trending_up;
      case InsightType.mostExpensive:
        return Icons.attach_money;
      case InsightType.unused:
        return Icons.warning;
      case InsightType.duplicate:
        return Icons.copy;
    }
  }

  Color _getInsightColor(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.low:
        return Colors.green;
      case InsightPriority.medium:
        return Colors.orange;
      case InsightPriority.high:
        return Colors.red;
    }
  }

  Color _getRecommendationColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.low:
        return Colors.green;
      case RecommendationPriority.medium:
        return Colors.orange;
      case RecommendationPriority.high:
        return Colors.red;
    }
  }
}

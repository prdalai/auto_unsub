enum RecommendationPriority {
  low,
  medium,
  high,
}

class SubscriptionRecommendation {
  final String title;
  final String description;
  final RecommendationPriority priority;

  const SubscriptionRecommendation({
    required this.title,
    required this.description,
    required this.priority,
  });
}

enum InsightType {
  spendingTrend,
  mostExpensive,
  unused,
  duplicate,
}

enum InsightPriority {
  low,
  medium,
  high,
}

class SubscriptionInsight {
  final String message;
  final InsightType type;
  final InsightPriority priority;

  const SubscriptionInsight({
    required this.message,
    required this.type,
    required this.priority,
  });
}

class SubscriptionInsights {
  final double totalMonthlySpending;
  final List<SubscriptionInsight> insights;
  final List<SubscriptionRecommendation> recommendations;

  const SubscriptionInsights({
    required this.totalMonthlySpending,
    required this.insights,
    required this.recommendations,
  });
}

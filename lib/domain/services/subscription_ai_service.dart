import 'package:http/http.dart' as http;
import 'dart:convert';
import '../entities/subscription.dart';
import 'package:flutter/material.dart';
import '../../config/env.dart';

class SubscriptionAIService {
  final String apiEndpoint;
  final String apiKey;

  SubscriptionAIService({
    String? apiEndpoint,
    String? apiKey,
  })  : apiEndpoint = apiEndpoint ?? Environment.apiEndpoint,
        apiKey = apiKey ?? Environment.apiKey;

  Future<SubscriptionInsights> generateSubscriptionInsights(
    List<Subscription> subscriptions,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiEndpoint/generate-insights'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _processAIResponse(data, subscriptions);
      } else {
        // Fallback to local insights generation if API call fails
        return _generateLocalInsights(subscriptions);
      }
    } catch (e) {
      // Fallback to local insights generation if API call fails
      return _generateLocalInsights(subscriptions);
    }
  }

  SubscriptionInsights _processAIResponse(
    Map<String, dynamic> data,
    List<Subscription> subscriptions,
  ) {
    final insights = <SubscriptionInsight>[];
    final recommendations = <SubscriptionRecommendation>[];
    double totalMonthlySpending = 0;

    // Calculate total monthly spending
    for (var subscription in subscriptions) {
      if (subscription.isActive) {
        switch (subscription.billingCycle.toLowerCase()) {
          case 'monthly':
            totalMonthlySpending += subscription.amount;
            break;
          case 'quarterly':
            totalMonthlySpending += subscription.amount / 3;
            break;
          case 'yearly':
            totalMonthlySpending += subscription.amount / 12;
            break;
          case 'weekly':
            totalMonthlySpending += subscription.amount * 4;
            break;
        }
      }
    }

    // Process AI-generated insights
    if (data['insights'] != null) {
      for (var insight in data['insights']) {
        insights.add(
          SubscriptionInsight(
            type: _parseInsightType(insight['type']),
            message: insight['message'],
            priority: _parseInsightPriority(insight['priority']),
          ),
        );
      }
    }

    // Process AI-generated recommendations
    if (data['recommendations'] != null) {
      for (var recommendation in data['recommendations']) {
        recommendations.add(
          SubscriptionRecommendation(
            title: recommendation['title'],
            description: recommendation['description'],
            priority: _parseRecommendationPriority(recommendation['priority']),
          ),
        );
      }
    }

    return SubscriptionInsights(
      insights: insights,
      recommendations: recommendations,
      totalMonthlySpending: totalMonthlySpending,
    );
  }

  InsightType _parseInsightType(String type) {
    switch (type.toLowerCase()) {
      case 'spendingtrend':
        return InsightType.spendingTrend;
      case 'mostexpensive':
        return InsightType.mostExpensive;
      case 'unused':
        return InsightType.unused;
      case 'duplicate':
        return InsightType.duplicate;
      default:
        return InsightType.spendingTrend;
    }
  }

  InsightPriority _parseInsightPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return InsightPriority.high;
      case 'medium':
        return InsightPriority.medium;
      case 'low':
        return InsightPriority.low;
      default:
        return InsightPriority.medium;
    }
  }

  RecommendationPriority _parseRecommendationPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return RecommendationPriority.high;
      case 'medium':
        return RecommendationPriority.medium;
      case 'low':
        return RecommendationPriority.low;
      default:
        return RecommendationPriority.medium;
    }
  }

  SubscriptionInsights _generateLocalInsights(
      List<Subscription> subscriptions) {
    // Calculate total monthly spending
    double totalMonthlySpending = 0;
    for (var subscription in subscriptions) {
      if (subscription.isActive) {
        switch (subscription.billingCycle.toLowerCase()) {
          case 'monthly':
            totalMonthlySpending += subscription.amount;
            break;
          case 'quarterly':
            totalMonthlySpending += subscription.amount / 3;
            break;
          case 'yearly':
            totalMonthlySpending += subscription.amount / 12;
            break;
          case 'weekly':
            totalMonthlySpending += subscription.amount * 4;
            break;
        }
      }
    }

    // Generate insights
    final insights = <SubscriptionInsight>[];
    final recommendations = <SubscriptionRecommendation>[];

    // Add spending trend insight
    insights.add(
      SubscriptionInsight(
        type: InsightType.spendingTrend,
        message:
            'You spend \$${totalMonthlySpending.toStringAsFixed(2)} per month on subscriptions.',
        priority: InsightPriority.high,
      ),
    );

    // Add recommendation for high spending
    if (totalMonthlySpending > 100) {
      recommendations.add(
        SubscriptionRecommendation(
          title: 'High Monthly Spending',
          description:
              'Consider reviewing your subscriptions to reduce monthly expenses.',
          priority: RecommendationPriority.high,
        ),
      );
    }

    // Add recommendation for multiple streaming services
    final streamingServices = subscriptions
        .where((s) =>
            s.isActive &&
            (s.serviceName.toLowerCase().contains('netflix') ||
                s.serviceName.toLowerCase().contains('prime') ||
                s.serviceName.toLowerCase().contains('disney') ||
                s.serviceName.toLowerCase().contains('hbo')))
        .length;

    if (streamingServices > 2) {
      recommendations.add(
        SubscriptionRecommendation(
          title: 'Multiple Streaming Services',
          description:
              'You have $streamingServices streaming services. Consider consolidating to save money.',
          priority: RecommendationPriority.medium,
        ),
      );
    }

    // Find most expensive subscription
    if (subscriptions.isNotEmpty) {
      final mostExpensive = subscriptions.reduce(
        (a, b) => a.amount > b.amount ? a : b,
      );

      insights.add(
        SubscriptionInsight(
          type: InsightType.mostExpensive,
          message:
              '${mostExpensive.serviceName} is your most expensive subscription at \$${mostExpensive.amount} per ${mostExpensive.billingCycle.toLowerCase()}.',
          priority: InsightPriority.medium,
        ),
      );
    }

    return SubscriptionInsights(
      insights: insights,
      recommendations: recommendations,
      totalMonthlySpending: totalMonthlySpending,
    );
  }

  Future<Subscription?> extractSubscriptionDetails(String emailBody) async {
    try {
      // Extract service name from common patterns
      final servicePatterns = [
        RegExp(r'from\s+([A-Za-z\s]+)'),
        RegExp(r'subscription\s+to\s+([A-Za-z\s]+)'),
        RegExp(r'([A-Za-z\s]+)\s+subscription'),
      ];

      String? serviceName;
      for (var pattern in servicePatterns) {
        final match = pattern.firstMatch(emailBody);
        if (match != null && match.groupCount >= 1) {
          serviceName = match.group(1)?.trim();
          break;
        }
      }

      // Extract amount using price pattern
      final pricePattern = RegExp(r'\$?\d+(?:\.\d{2})?');
      final priceMatch = pricePattern.firstMatch(emailBody);
      final amount = priceMatch != null
          ? double.tryParse(priceMatch.group(0)?.replaceAll('\$', '') ?? '')
          : null;

      if (serviceName != null && amount != null) {
        return Subscription(
          serviceName: serviceName,
          amount: amount,
          billingCycle: 'monthly', // Default to monthly
          nextBillingDate:
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          isActive: true,
          startDate: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error extracting subscription details: $e');
    }
    return null;
  }
}

class SubscriptionInsights {
  final List<SubscriptionInsight> insights;
  final List<SubscriptionRecommendation> recommendations;
  final double totalMonthlySpending;

  SubscriptionInsights({
    required this.insights,
    required this.recommendations,
    required this.totalMonthlySpending,
  });
}

class SubscriptionInsight {
  final InsightType type;
  final String message;
  final InsightPriority priority;

  SubscriptionInsight({
    required this.type,
    required this.message,
    required this.priority,
  });
}

class SubscriptionRecommendation {
  final String title;
  final String description;
  final RecommendationPriority priority;

  SubscriptionRecommendation({
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

enum RecommendationPriority {
  low,
  medium,
  high,
}

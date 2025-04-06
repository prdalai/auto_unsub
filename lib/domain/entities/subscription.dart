import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Subscription {
  final String id;
  final String serviceName;
  final double amount;
  final String billingCycle;
  final String nextBillingDate;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final String? description;
  final String? category;
  final String? website;
  final String? email;
  final String? phone;
  final String? notes;
  final String? paymentMethod;

  Subscription({
    String? id,
    required this.serviceName,
    required this.amount,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.isActive,
    required this.startDate,
    this.endDate,
    this.description,
    this.category,
    this.website,
    this.email,
    this.phone,
    this.notes,
    this.paymentMethod,
  }) : id = id ?? const Uuid().v4();

  // Create a Subscription from JSON data
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String?,
      serviceName: json['serviceName'] as String,
      amount: (json['amount'] as num).toDouble(),
      billingCycle: json['billingCycle'] as String,
      nextBillingDate: json['nextBillingDate'] as String,
      isActive: json['isActive'] as bool,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      description: json['description'] as String?,
      category: json['category'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }

  // Convert Subscription to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'amount': amount,
      'billingCycle': billingCycle,
      'nextBillingDate': nextBillingDate,
      'isActive': isActive,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'description': description,
      'category': category,
      'website': website,
      'email': email,
      'phone': phone,
      'notes': notes,
      'paymentMethod': paymentMethod,
    };
  }

  // Format the next billing date with month name and year
  String get formattedNextBillingDate {
    try {
      final date = DateTime.parse(nextBillingDate);
      final monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
    } catch (e) {
      return nextBillingDate;
    }
  }

  // Create a copy of Subscription with some fields updated
  Subscription copyWith({
    String? id,
    String? serviceName,
    double? amount,
    String? billingCycle,
    String? nextBillingDate,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String? category,
    String? website,
    String? email,
    String? phone,
    String? notes,
    String? paymentMethod,
  }) {
    return Subscription(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      category: category ?? this.category,
      website: website ?? this.website,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  double get monthlyPrice {
    switch (billingCycle.toLowerCase()) {
      case 'monthly':
        return amount;
      case 'quarterly':
        return amount / 3;
      case 'yearly':
        return amount / 12;
      default:
        return amount;
    }
  }

  String get formattedAmount {
    final formatter = NumberFormat.currency(symbol: '₹');
    return formatter.format(amount);
  }

  String get formattedMonthlyPrice {
    final formatter = NumberFormat.currency(symbol: '₹');
    return formatter.format(monthlyPrice);
  }
}
